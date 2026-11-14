# Homebrew tap

Homebrew formulae for [kiln](https://github.com/hakula139/kiln) and [oxide-code](https://github.com/hakula139/oxide-code).

## Install

```bash
brew install hakula139/tap/kiln
brew install hakula139/tap/oxide-code
```

Apple Silicon macOS and x86_64 Linux are supported. kiln installs the base release build without dav1d. oxide-code provides the `ox` command.

## Maintain formulae

The source repositories publish binary archives and SHA-256 sidecars. Their release workflows then dispatch this tap's `update-formula.yml` on `main` with `formula` (`kiln` or `oxide-code`) and `tag` (including `v`). The updater follows the latest stable release, or the newest prerelease before the first stable release, and opens a separate PR for each formula and tag. CI checks rendering against the published sidecars and runs `brew install` and `brew test` on macOS and Linux. Review and merge the formula PR to publish the update.

Install the release GitHub App on this tap with Contents and Pull requests read/write permissions for formula PRs and Actions read/write permission for source notifications. Set `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY` as Actions secrets in this tap and both source repositories. Source notifications must mint an installation token scoped to `hakula139/homebrew-tap` with `permission-actions: write`. The tap requests Contents and Pull requests write permissions for its token so its PRs trigger CI. Configure credentials through GitHub's secret settings without placing private keys in the repository.

If notification or updating fails, correct the App installation and secrets, then rerun the updater for the published tag:

```bash
gh workflow run update-formula.yml \
  --repo hakula139/homebrew-tap \
  --ref main \
  -f formula=kiln \
  -f tag=vX.Y.Z
```

A rerun reuses the formula/tag branch and updates its open PR. Tags outside the selected release policy are skipped.

To change a template, download that formula's published sidecars and regenerate it locally:

```bash
gh release download vX.Y.Z \
  --repo hakula139/kiln \
  --pattern 'kiln-*.sha256' \
  --dir /tmp/kiln-sidecars
nix develop -c nu scripts/update-homebrew-formula.nu kiln vX.Y.Z /tmp/kiln-sidecars
```

Templates live in `scripts/*-formula.rb`. Keep platform requirements aligned with the source release builds. Enter `nix develop` for hook tooling and run `run-hooks` before publishing a change.
