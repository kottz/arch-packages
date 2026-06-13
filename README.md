# kottz Arch packages

Personal Arch package repository for packages built from kottz-maintained forks.

## Layout

- `packages/<name>/`: PKGBUILD and package-local files.
- `config/packages.sh`: package metadata used by automation scripts.
- `scripts/`: deterministic maintenance, build, and publish commands.
- `.agents/skills/`: repo-local agent skills for packaging maintenance.
- `systemd/`: optional weekly automation units.

## Common Commands

```bash
scripts/check-updates
scripts/rebase-source sway-groups
scripts/build-package sway-groups
scripts/publish-repo
```

By default scripts expect source forks beside this repo:

```text
../sway
../Waybar
```

On a server, set:

```bash
export KOTTZ_SOURCE_ROOT=/srv/kottz/src
export KOTTZ_REPO_DIR=/srv/kottz/repo/x86_64
```

## Pacman Repo

After publishing, serve `KOTTZ_REPO_DIR` as static files and add this to clients:

```ini
[kottz]
SigLevel = Optional TrustAll
Server = https://repo.example.invalid/$arch
```

Switch to signed packages and database files when the repo key is installed on
all machines.
