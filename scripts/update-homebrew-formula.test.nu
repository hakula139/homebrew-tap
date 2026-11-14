use std/assert

const GENERATOR = path self "update-homebrew-formula.nu"

export def "test renders only the requested formula" [] {
  for case in [
    {formula: "kiln", class: "Kiln", binary: "kiln"}
    {formula: "oxide-code", class: "OxideCode", binary: "ox"}
  ] {
    let scratch = mktemp -d
    mkdir ($scratch | path join "Formula")
    let other = if $case.formula == "kiln" { "oxide-code" } else { "kiln" }
    "unchanged" | save ($scratch | path join $"Formula/($other).rb")
    let mac = "a" | fill --width 64 --character "a"
    let linux = "b" | fill --width 64 --character "b"
    $"($mac)  ($case.formula)-aarch64-apple-darwin.tar.gz\n"
      | save ($scratch | path join $"($case.formula)-aarch64-apple-darwin.sha256")
    $"($linux)  ($case.formula)-x86_64-unknown-linux-gnu.tar.gz\n"
      | save ($scratch | path join $"($case.formula)-x86_64-unknown-linux-gnu.sha256")

    let result = do {
      cd $scratch
      ^$nu.current-exe $GENERATOR $case.formula "v1.2.3-rc.1" $scratch | complete
    }
    assert equal $result.exit_code 0 $result.stderr

    let rendered = open --raw ($scratch | path join $"Formula/($case.formula).rb")
    for expected in [
      $"class ($case.class) < Formula"
      'version "1.2.3-rc.1"'
      $'sha256 "($mac)"'
      $'sha256 "($linux)"'
      $'bin.install "($case.binary)"'
      $"https://github.com/hakula139/($case.formula)/releases/download/v1.2.3-rc.1/($case.formula)-aarch64-apple-darwin.tar.gz"
      $"https://github.com/hakula139/($case.formula)/releases/download/v1.2.3-rc.1/($case.formula)-x86_64-unknown-linux-gnu.tar.gz"
    ] {
      assert ($rendered | str contains $expected) $"Missing ($expected)"
    }
    assert not ($rendered | str contains "{{")
    assert equal (open --raw ($scratch | path join $"Formula/($other).rb")) "unchanged"
    rm -r $scratch
  }
}

export def "test rejects invalid release inputs before writing" [] {
  for case in [
    {formula: "unknown", tag: "v1.2.3", checksum: "valid"}
    {formula: "kiln", tag: "1.2.3", checksum: "valid"}
    {formula: "kiln", tag: "v1.2.3/other", checksum: "valid"}
    {formula: "kiln", tag: "v1.2.3", checksum: "invalid"}
    {formula: "kiln", tag: "v1.2.3", checksum: "missing"}
  ] {
    let scratch = mktemp -d
    let output = $scratch | path join "formula.rb"
    "unchanged" | save $output
    if $case.checksum != "missing" {
      let checksum = if $case.checksum == "valid" {
        "a" | fill --width 64 --character "a"
      } else {
        "invalid"
      }
      for target in ["aarch64-apple-darwin" "x86_64-unknown-linux-gnu"] {
        $checksum | save ($scratch | path join $"kiln-($target).sha256")
      }
    }

    let result = ^$nu.current-exe $GENERATOR $case.formula $case.tag $scratch --output $output | complete

    assert ($result.exit_code != 0) $"Accepted invalid input: ($case)"
    assert equal (open --raw $output) "unchanged"
    rm -r $scratch
  }
}
