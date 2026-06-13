# AGENTS.md

This repo owns Arch packaging and publishing for kottz-maintained forks. Source
features live in their upstream forks; this repo should stay focused on package
metadata, build scripts, repo publishing, and automation.

## Repositories

- Sway source fork: `git@github.com:kottz/sway.git`
- Waybar source fork: `git@github.com:kottz/Waybar.git`
- Package repo: `git@github.com:kottz/arch-packages.git`

Expected local layout for development:

```text
swayway-groups/
  sway/
  Waybar/
  arch-packages/
```

Server layout can differ. Use `KOTTZ_SOURCE_ROOT` and `KOTTZ_REPO_DIR`.

## Package Policy

- Package names use the `-groups` suffix.
- Packages must conflict with and provide the upstream package they replace.
- Publish only after `makepkg`/clean-chroot build succeeds.
- Keep previous package files in the repo directory for manual rollback.
- Prefer deterministic scripts in `scripts/`; call Codex only when rebase,
  build, or package metadata maintenance fails.

## Verification

For package-only changes:

```bash
bash -n scripts/*
bash -n packages/*/PKGBUILD
git diff --check
```

For release work on an Arch builder:

```bash
scripts/weekly-maintenance
```

When changing Sway or Waybar source behavior, read the `AGENTS.md` in that
source repo and run that repo's build/test commands before updating packages.
