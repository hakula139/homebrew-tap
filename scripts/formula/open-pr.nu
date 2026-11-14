#!/usr/bin/env nu

use ./generate.nu

const LATEST_RELEASE_QUERY = 'query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { latestRelease { tagName } } }'

def render [formula: string, tag: string, source_repo: string]: nothing -> string {
  let scratch = (mktemp -d)
  let output = ($scratch | path join "formula.rb")
  let rendered = try {
    (
      ^gh release download $tag
        --repo $source_repo
        --pattern $"($formula)-*.sha256"
        --dir $scratch
    )

    generate $formula $tag $scratch --output $output
    open --raw $output
  } catch {|err|
    rm -r $scratch
    error make $err
  }
  rm -r $scratch
  $rendered
}

# Open or update a scoped formula PR for the selected published release.
def main [] {
  let formula = $env.FORMULA
  let tag = $env.TAG
  generate validate $formula $tag

  let file = $"Formula/($formula).rb"
  ^git ls-files --error-unmatch $file
  let source_repo = $"hakula139/($formula)"

  mut latest = (
    ^gh api graphql
      --field "owner=hakula139"
      --field $"name=($formula)"
      --raw-field $"query=($LATEST_RELEASE_QUERY)"
    | from json
    | get -o data.repository.latestRelease.tagName
    | default ""
  )

  if $latest == "" {
    $latest = (
      ^gh release list
        --repo $source_repo
        --exclude-drafts
        --limit 1
        --json tagName
      | from json
      | get tagName
      | first
      | default ""
    )
  }

  if $latest == "" {
    error make {msg: "No published release found for the Homebrew formula"}
  }

  if $latest != $tag {
    print $"Skipping ($formula) ($tag), since the formula follows ($latest)."
    return
  }

  let rendered = (render $formula $tag $source_repo)
  let branch = $"chore/homebrew-($formula)-($tag)"
  let title = $"chore\(($formula)\): refresh Homebrew formula for ($tag)"
  let remote = (
    ^git ls-remote origin $"refs/heads/($branch)" --exit-code
    | complete
  )
  let existing = match $remote.exit_code {
    0 => true
    2 => false
    _ => {
      print -e $remote.stderr
      exit $remote.exit_code
    }
  }

  if $existing {
    ^git fetch origin $"refs/heads/($branch)"
    ^git switch -c $branch FETCH_HEAD
  } else {
    ^git switch -c $branch
  }

  $rendered | save --force $file
  let diff = (^git diff --quiet -- $file | complete)
  match $diff.exit_code {
    0 => {
      print $"The formula already points at ($tag)."
      if not $existing {
        return
      }
    }
    1 => {
      ^git add $file
      ^git diff --cached --name-only

      (
        ^git
          -c "user.name=hakula-release-bot[bot]"
          -c "user.email=351352052+hakula-release-bot[bot]@users.noreply.github.com"
          commit
            -m $title
            -- $file
      )

      ^git push origin $branch
    }
    _ => {
      print -e $diff.stderr
      exit $diff.exit_code
    }
  }

  let number = (
    ^gh pr list
      --head $branch
      --state open
      --json number
    | from json
    | get number
    | first
  )

  if $number == null {
    (
      ^gh pr create
        --base main
        --head $branch
        --title $title
        --assignee hakula139
        --label chore
        --body-file .github/templates/homebrew-formula-pr.md
    )
  } else {
    (
      ^gh pr edit $number
        --title $title
        --body-file .github/templates/homebrew-formula-pr.md
    )
  }
}
