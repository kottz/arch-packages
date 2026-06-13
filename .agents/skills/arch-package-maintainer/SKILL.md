---
name: arch-package-maintainer
description: Maintain kottz's Arch package repository for personal fork packages, including PKGBUILD updates, .SRCINFO regeneration, package builds, pacman repo publication, and automation scripts that call Opencode only after deterministic steps fail.
---

# Arch Package Maintainer

Use this skill in `kottz/arch-packages`.

## Workflow

1. Read `AGENTS.md`.
2. Use `config/packages.sh` as the source of package metadata.
3. Prefer deterministic scripts in `scripts/` before manual edits.
4. Treat Opencode as a recovery step only. After `opencode run`, rerun the
   failed deterministic command and continue only if it passes.
5. Before automated pushes, require clean Git working trees. If the agent made
   changes but did not commit them, stop and report the dirty repo.
6. For package metadata changes, run:

```bash
bash -n scripts/*
bash -n packages/*/PKGBUILD
git diff --check
```

7. On an Arch builder, run the relevant package build:

```bash
scripts/build-package sway-groups
scripts/build-package waybar-groups
```

8. Regenerate `.SRCINFO` with:

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
- GitHub auth or permission failures should be reported through the classified
  stage failure path, with the captured log path included.
- Runtime secrets should be consumed through systemd credentials. Do not add
  secret `Environment=` or `EnvironmentFile=` usage.

## Source Skills

When package work requires source changes, also use the relevant source repo:

- Sway: `../sway/.agents/skills/sway-workspace-groups-maintainer/SKILL.md`
- Waybar: `../Waybar/.agents/skills/waybar-workspace-groups-maintainer/SKILL.md`
