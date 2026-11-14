#!/usr/bin/env nu

const SCRIPT_DIR = path self "."

# Regenerate one Homebrew formula from a release's checksum sidecars.
def main [
  formula: string # kiln or oxide-code
  tag: string # Release tag, including the v prefix
  sidecars: string # Directory containing the release's .sha256 files
  --output: string # Output path, defaulting to Formula/<formula>.rb
] {
  if $formula not-in ["kiln" "oxide-code"] {
    error make {msg: "Formula must be kiln or oxide-code"}
  }
  if $tag !~ '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' {
    error make {msg: "Expected a release tag including its v prefix"}
  }

  let checksums = ["aarch64-apple-darwin" "x86_64-unknown-linux-gnu"]
    | each {|target|
      let checksum = open --raw ($sidecars | path join $"($formula)-($target).sha256")
        | split words
        | first
      if $checksum !~ '^[0-9a-fA-F]{64}$' {
        error make {msg: $"Invalid SHA-256 checksum for ($target)"}
      }
      $checksum
    }
    | collect
  let version = $tag | str substring 1..
  let base = $"https://github.com/hakula139/($formula)/releases/download/($tag)"
  let destination = $output | default $"Formula/($formula).rb"

  open --raw ($SCRIPT_DIR | path join $"($formula)-formula.rb")
    | str replace --all "{{base}}" $base
    | str replace --all "{{version}}" $version
    | str replace --all "{{mac_arm_sha}}" $checksums.0
    | str replace --all "{{linux_x86_sha}}" $checksums.1
    | save --force $destination

  print $"Updated ($destination) to ($tag)"
}
