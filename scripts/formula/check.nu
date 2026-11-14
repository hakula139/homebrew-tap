#!/usr/bin/env nu

use ./generate.nu

def check [scratch: path] {
  ^brew tap-new --no-git local/check
  let tap = (^brew --repository local/check | str trim)

  for file in (glob "Formula/*.rb") {
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
        --repo $"hakula139/($formula)"
        --pattern $"($formula)-*.sha256"
        --dir $sidecars
    )

    generate $formula $tag $sidecars
    ^git diff --exit-code -- $file

    ^cp $file ($tap | path join "Formula")
    ^brew install $"local/check/($formula)"
    ^brew test $"local/check/($formula)"
  }
}

# Check rendering, installation and tests for every formula in the tap.
def main [] {
  let scratch = (mktemp -d)
  try {
    check $scratch
  } catch {|err|
    rm -r $scratch
    error make $err
  }
  rm -r $scratch
}
