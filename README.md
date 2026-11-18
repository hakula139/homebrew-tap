# Homebrew tap

Homebrew formulae maintained by Hakula.

## Install

Replace `FORMULA` with a package name:

```bash
brew install hakula139/tap/FORMULA
```

## Formulae

| Formula                             | Description                              |
| ----------------------------------- | ---------------------------------------- |
| [kiln](Formula/kiln.rb)             | Static site generator with AVIF decoding |
| [oxide-code](Formula/oxide-code.rb) | Coding agent (`ox`)                      |

## Maintain formulae

Source release workflows dispatch `update.yml` on `main` with `formula` and a published `tag` including `v`. The updater tracks the latest stable release, or the newest prerelease before the first stable release, and opens a PR with squash auto-merge enabled for each formula and tag. CI checks checksums, rendering, installation and `brew test` on macOS and Linux before the PR merges.

### Automation setup

Install the release GitHub App on this tap with Contents, Pull requests and Actions write permissions. Set `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY` as Actions secrets in this tap and each notifying source repository.

Source notifications request a token with `owner: hakula139`, `repositories: homebrew-tap` and `permission-actions: write`. The tap requests Contents and Pull requests write permissions so its formula PRs trigger CI and enable auto-merge.

### Update a formula

To recover a missed notification, fix any App setup errors and dispatch the published tag:

```bash
formula=FORMULA
tag=vX.Y.Z

gh workflow run update.yml \
  --repo hakula139/homebrew-tap \
  --ref main \
  -f "formula=$formula" \
  -f "tag=$tag"
```

A rerun reuses the formula / tag branch, updates its open PR, and enables squash auto-merge. Tags outside the selected release policy are skipped.

### Change a template

Templates live in `scripts/formula/templates/`. Keep their platform requirements aligned with upstream release builds. Download the published SHA-256 sidecars and regenerate the formula using the same `formula` and `tag` variables:

```bash
sidecars=$(mktemp -d)

gh release download "$tag" \
  --repo "hakula139/$formula" \
  --pattern '*.sha256' \
  --dir "$sidecars"

nix develop -c nu scripts/formula/generate.nu "$formula" "$tag" "$sidecars"

rm -rf "$sidecars"
```

Enter `nix develop` for hook tooling and run `run-hooks` before publishing a change.
