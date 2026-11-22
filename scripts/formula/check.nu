#!/usr/bin/env nu

use ./generate.nu

# Select existing formulae affected by changed paths, including shared maintenance code.
export def select-formulae [
  formulae: list<string>
  changed: list<string>
]: nothing -> list<string> {
  let shared = ($changed | any {|file|
    (
      ($file | str starts-with ".github/workflows/") or
      ($file in ["flake.nix" "flake.lock"]) or (
        ($file | str starts-with "scripts/formula/") and
        not ($file | str starts-with "scripts/formula/templates/")
      )
    )
  })

  if $shared {
    return $formulae
  }

  $formulae | where {|file|
    $file in $changed or (
      $"scripts/formula/templates/($file | path basename)" in $changed
    )
  }
}

def formulae []: nothing -> list<string> {
  let available = (glob "Formula/*.rb" | path relative-to (pwd) | sort)
  if $env.GITHUB_EVENT_NAME? != "pull_request" {
    return $available
  }

  let base = (open $env.GITHUB_EVENT_PATH).pull_request.base.sha
  let changed = (^git diff --name-only $base HEAD | lines)
  select-formulae $available $changed
}

def check [files: list<string>, scratch: path] {
  ^brew tap-new --no-git local/check
  let tap = (^brew --repository local/check | str trim)

  for file in $files {
    let formula = ($file | path parse | get stem)
    let version = (
      open --raw $file
      | parse --regex '(?m)^  version "(?<version>[^"]+)"$'
      | get version
      | first
    )
    let tag = $"v($version)"
    let sidecars = ($scratch | path join $formula)

    mkdir $sidecars

    (
      ^gh release download $tag
        --repo $"hakulab/($formula)"
        --pattern "*.sha256"
        --dir $sidecars
    )

    generate $formula $tag $sidecars
    ^git diff --exit-code -- $file

    ^cp $file ($tap | path join "Formula")
    ^brew install $"local/check/($formula)"
    ^brew test $"local/check/($formula)"
  }
}

# Check rendering, installation and tests for affected formulae, or all on non-PR runs.
def main [] {
  let files = (formulae)
  if ($files | is-empty) {
    print "No formulae changed."
    return
  }

  let scratch = (mktemp -d)
  try {
    check $files $scratch
  } catch {|err|
    rm -r $scratch
    error make $err
  }

  rm -r $scratch
}
