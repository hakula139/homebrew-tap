use std/assert

const GENERATOR = path self "generate.nu"
const FIXTURES = path self "fixtures"

def sandbox [] {
  let scratch = (mktemp -d)
  mkdir ($scratch | path join "Formula") ($scratch | path join "templates")
  ^cp $GENERATOR ($scratch | path join "generate.nu")
  ^cp ($FIXTURES | path join "template.rb") ($scratch | path join "templates/example-tool.rb")
  $scratch
}

def sidecars [scratch: path, valid: bool] {
  for target in [
    {
      name: "aarch64-apple-darwin"
      character: "a"
    }

    {
      name: "x86_64-unknown-linux-gnu"
      character: "b"
    }
  ] {
    let digest = if $valid {
      $target.character | fill --width 64 --character $target.character
    } else {
      "invalid"
    }
    $"($digest)  example-tool-($target.name).tar.gz\n"
      | save ($scratch | path join $"example-tool-($target.name).sha256")
  }
}

export def "test renders only the requested formula" [] {
  let scratch = (sandbox)
  sidecars $scratch true
  "unchanged" | save ($scratch | path join "Formula/other.rb")
  let generator = ($scratch | path join "generate.nu")

  let result = do {
    cd $scratch
    ^$nu.current-exe $generator "example-tool" "v1.2.3-rc.1" $scratch | complete
  }
  assert equal $result.exit_code 0 $result.stderr

  let rendered = (open --raw ($scratch | path join "Formula/example-tool.rb"))
  assert equal $rendered (open --raw ($FIXTURES | path join "rendered.rb"))
  assert equal (open --raw ($scratch | path join "Formula/other.rb")) "unchanged"
  rm -r $scratch
}

export def "test rejects invalid release inputs before writing" [] {
  for case in [
    {
      formula: "unknown"
      tag: "v1.2.3"
      checksum: "valid"
    }

    {
      formula: "../example-tool"
      tag: "v1.2.3"
      checksum: "valid"
    }

    {
      formula: "example-tool"
      tag: "1.2.3"
      checksum: "valid"
    }

    {
      formula: "example-tool"
      tag: "v1.2.3/other"
      checksum: "valid"
    }

    {
      formula: "example-tool"
      tag: "v1.2.3"
      checksum: "invalid"
    }

    {
      formula: "example-tool"
      tag: "v1.2.3"
      checksum: "missing"
    }
  ] {
    let scratch = (sandbox)
    let output = ($scratch | path join "formula.rb")
    "unchanged" | save $output
    if $case.checksum != "missing" {
      sidecars $scratch ($case.checksum == "valid")
    }
    let generator = ($scratch | path join "generate.nu")

    let result = (
      ^$nu.current-exe $generator $case.formula $case.tag $scratch
        --output $output
      | complete
    )

    assert ($result.exit_code != 0) $"Accepted invalid input: ($case)"
    assert equal (open --raw $output) "unchanged"
    rm -r $scratch
  }
}
