use std/assert
use ./check.nu [select-formulae]

export def "test selects affected formulae from a large catalog" [] {
  let formulae = (
    0..<100
    | each {|index|
      let suffix = (
        $index
        | into string
        | fill --width 3 --alignment right --character "0"
      )
      $"Formula/example-($suffix).rb"
    }
  )

  let cases = [
    {
      changed: ["Formula/example-042.rb"]
      expected: [$formulae.42]
    }
    {
      changed: ["scripts/formula/templates/example-042.rb"]
      expected: [$formulae.42]
    }
    {
      changed: ["Formula/example-042.rb" "scripts/formula/templates/example-042.rb"]
      expected: [$formulae.42]
    }
    {
      changed: ["scripts/formula/generate.nu"]
      expected: $formulae
    }
    {
      changed: [".github/workflows/formula.yml"]
      expected: $formulae
    }
    {
      changed: [".github/workflows/ci.yml"]
      expected: $formulae
    }
    {
      changed: [".github/workflows/update.yml"]
      expected: $formulae
    }
    {
      changed: ["flake.nix"]
      expected: $formulae
    }
    {
      changed: ["flake.lock"]
      expected: $formulae
    }
    {
      changed: ["README.md"]
      expected: []
    }
    {
      changed: ["Formula/removed.rb"]
      expected: []
    }
  ]

  for case in $cases {
    let actual = (select-formulae $formulae $case.changed)

    assert equal $actual $case.expected $"Changed paths: ($case.changed)"
  }
}
