#!/usr/bin/env nu

const TEMPLATES_DIR = path self "templates"

# Validate a formula name and release tag before using them in paths or commands.
export def validate [formula: string, tag: string] {
  if $formula !~ '^[a-z0-9]+(-[a-z0-9]+)*$' {
    error make {msg: "Expected a lowercase formula name separated by hyphens"}
  }

  if not ($TEMPLATES_DIR | path join $"($formula).rb" | path exists) {
    error make {msg: $"No template found for ($formula)"}
  }

  if $tag !~ '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' {
    error make {msg: "Expected a release tag including its v prefix"}
  }
}

# Regenerate one Homebrew formula from a release's checksum sidecars.
export def main [
  formula: string # Formula name matching a template
  tag: string # Release tag, including the v prefix
  sidecars: string # Directory containing the release's .sha256 files
  --output: string # Output path, defaulting to Formula/<formula>.rb
] {
  validate $formula $tag

  let template = (open --raw ($TEMPLATES_DIR | path join $"($formula).rb"))
  let archives = (
    $template
    | parse --regex 'url "\{\{base\}\}/(?<archive>[^"/]+)\.tar\.gz"'
    | get archive
  )

  let checksums = ["aarch64-apple-darwin" "x86_64-unknown-linux-gnu"]
    | each {|target|
      let matching = ($archives | where {|archive| $archive | str ends-with $"-($target)" })
      if ($matching | length) != 1 {
        error make {msg: $"Expected one template archive for ($target)"}
      }

      let checksum = open --raw ($sidecars | path join $"($matching.0).sha256")
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

  $template
    | str replace --all "{{base}}" $base
    | str replace --all "{{version}}" $version
    | str replace --all "{{mac_arm_sha}}" $checksums.0
    | str replace --all "{{linux_x86_sha}}" $checksums.1
    | save --force $destination

  print $"Updated ($destination) to ($tag)"
}
