# kottz Arch packages

Personal Arch package repository for packages built from kottz-maintained forks.

## Layout

- `packages/<name>/`: PKGBUILD and package-local files.
- `config/packages.sh`: package metadata used by automation scripts.
- `scripts/`: deterministic maintenance, build, and publish commands.
- `.agents/skills/`: repo-local agent skills for packaging maintenance.
- `systemd/`: optional weekly automation units.
- `infra/vm/`: Arch VM bootstrap and health-check scripts.
- `infra/caddy/`: internal static file server config for the pacman repo.
- `docs/secrets.md`: SOPS/age secret handling notes.

## Common Commands

```bash
scripts/check-updates
scripts/rebase-source sway-groups
scripts/build-package sway-groups
scripts/publish-repo
```

`scripts/weekly-maintenance` uses deterministic stages first. If a stage fails
and `RUN_OPENCODE_ON_FAILURE=1`, it runs `opencode run`, then reruns the failed
stage. Pushes only happen after the deterministic stage passes and the affected
Git working trees are clean.

Operational checks:

```bash
scripts/run-with-credentials scripts/doctor-secrets
scripts/run-with-credentials scripts/test-notifications
scripts/run-with-credentials scripts/check-github-access
```

Set `KOTTZ_GITHUB_ACCESS_CHECK=1` on the service if you want the weekly job to
run a live GitHub access check before maintenance. Normal fetch/push failures
are classified and sent to Telegram either way.

By default scripts expect source forks beside this repo:

```text
../sway
../Waybar
```

On a server, set:

```bash
export KOTTZ_SOURCE_ROOT=/srv/kottz/src
export KOTTZ_REPO_DIR=/srv/kottz/repo/x86_64
export KOTTZ_CHROOT_DIR=/srv/kottz/chroot
export OPENCODE_MODEL=openrouter/moonshotai/kimi-k2.7-code
```

Builds default to four compile jobs:

```bash
export KOTTZ_BUILD_JOBS=4
```

Package builds use Arch devtools clean chroots through `mkarchroot` and
`makechrootpkg`; they should not fall back to host `makepkg` builds.

## Builder VM

Bootstrap a fresh Arch VM with:

```bash
pacman -Syu --needed --noconfirm git openssh
git clone https://github.com/kottz/arch-packages.git /srv/kottz/packaging/arch-packages
/srv/kottz/packaging/arch-packages/infra/vm/bootstrap-arch-builder
```

If the repos are private, place `kottz-secrets` on the VM first and install the
age key from Bitwarden before running the bootstrap. The builder converts SOPS
secrets into host-bound systemd encrypted credentials and uses the GitHub token
credential for HTTPS fetch/push. See `docs/secrets.md`.

## Pacman Repo

The VM serves `/srv/kottz/repo` on internal HTTP port `8080` using Caddy. Put
your existing reverse proxy in front of that and add this to clients:

```ini
[kottz]
SigLevel = Optional TrustAll
Server = https://repo.example.invalid/$arch
```

Switch to signed packages and database files when the repo key is installed on
all machines.
