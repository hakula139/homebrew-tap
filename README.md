# Homebrew tap

Homebrew formulae maintained by Hakula.

## Install

Install a package with `brew install hakula139/tap/FORMULA`, replacing `FORMULA` with its name. Platform requirements are defined by each formula.

| Formula                             | Install                                 | Notes                    |
| ----------------------------------- | --------------------------------------- | ------------------------ |
| [kiln](Formula/kiln.rb)             | `brew install hakula139/tap/kiln`       | Base build without dav1d |
| [oxide-code](Formula/oxide-code.rb) | `brew install hakula139/tap/oxide-code` | `ox` executable          |

## Maintain formulae

Source repositories publish binary archives and SHA-256 sidecars. Their release workflows then dispatch this tap's `update.yml` on `main` with `formula` (the name of an existing formula) and `tag` (including `v`). The updater follows the latest stable release, or the newest prerelease before the first stable release, and opens a separate PR for each formula and tag. CI checks rendering against the published sidecars and runs `brew install` and `brew test` on macOS and Linux. Review and merge the formula PR to publish the update.

Install the release GitHub App on this tap with Contents and Pull requests write permissions for formula PRs and Actions write permission for source notifications. Set `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY` as Actions secrets in this tap and each notifying source repository. Source notifications must mint a token with `owner: hakula139`, `repositories: homebrew-tap` and `permission-actions: write`. The tap requests Contents and Pull requests write permissions for its token so its PRs trigger CI. Configure credentials through GitHub's secret settings without placing private keys in the repository.

If notification or updating fails, correct the App installation and secrets, then rerun the updater for the published tag:

```bash
formula=FORMULA
tag=vX.Y.Z

gh workflow run update.yml \
  --repo hakula139/homebrew-tap \
  --ref main \
  -f "formula=$formula" \
  -f "tag=$tag"
```

A rerun reuses the formula/tag branch and updates its open PR. Tags outside the selected release policy are skipped.

To change a template, download that formula's published sidecars and regenerate it locally:

```bash
sidecars=$(mktemp -d)

gh release download "$tag" \
  --repo "hakula139/$formula" \
  --pattern "$formula-*.sha256" \
  --dir "$sidecars"

nix develop -c nu scripts/formula/generate.nu "$formula" "$tag" "$sidecars"

rm -rf "$sidecars"
```

Templates live in `scripts/formula/templates/*.rb`. Keep platform requirements aligned with upstream release builds. Enter `nix develop` for hook tooling and run `run-hooks` before publishing a change.
