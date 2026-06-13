---
name: arch-package-maintainer
description: Maintain kottz's Arch package repository for personal fork packages, including PKGBUILD updates, .SRCINFO regeneration, package builds, pacman repo publication, and automation scripts that call Codex only after deterministic steps fail.
---

# Arch Package Maintainer

Use this skill in `kottz/arch-packages`.

## Workflow

1. Read `AGENTS.md`.
2. Use `config/packages.sh` as the source of package metadata.
3. Prefer deterministic scripts in `scripts/` before manual edits.
4. For package metadata changes, run:

```bash
bash -n scripts/*
bash -n packages/*/PKGBUILD
git diff --check
```

5. On an Arch builder, run the relevant package build:

```bash
scripts/build-package sway-groups
scripts/build-package waybar-groups
```

6. Regenerate `.SRCINFO` with:

```bash
scripts/update-srcinfo sway-groups
scripts/update-srcinfo waybar-groups
```

## Policy

- Package names use `-groups`.
- Packages must `provide` and `conflict` with the upstream package they replace.
- The binary repo is updated only after successful package builds.
- Do not delete old package artifacts during publish; keep rollback possible.
- Source-specific conflict fixes belong in the source repos, not in PKGBUILD hacks.

## Source Skills

When package work requires source changes, also use the relevant source repo:

- Sway: `../sway/.agents/skills/sway-workspace-groups-maintainer/SKILL.md`
- Waybar: `../Waybar/.agents/skills/waybar-workspace-groups-maintainer/SKILL.md`
