# Arch LXC Builder

This directory contains bootstrap and health-check scripts for a dedicated Arch
Linux LXC that builds and publishes the personal `kottz` package repo.

## Model

- Run package maintenance as the unprivileged `kottz` user.
- Keep source forks under `/srv/kottz/src`.
- Keep this repo under `/srv/kottz/packaging/arch-packages`.
- Serve the binary repo from `/srv/kottz/repo` on internal HTTP port `8080`.
- Keep encrypted SOPS secrets in `/srv/kottz/secrets/kottz-secrets`.
- Keep the age private key outside Git at `/etc/kottz/age/arch-packages.txt`.

The age key should be generated once, stored in Bitwarden, and installed on the
builder as `root:root` with mode `0400`.

The Opencode fallback uses OpenRouter through a systemd credential file. The
default model is `openrouter/moonshotai/kimi-k2.7-code`. A successful
`opencode run` does not by itself publish anything; the maintenance script
reruns the failed deterministic stage and only continues after that stage
passes.

## Bootstrap

From a fresh Arch LXC:

```bash
pacman -Syu --needed --noconfirm git openssh
git clone https://github.com/kottz/arch-packages.git /srv/kottz/packaging/arch-packages
/srv/kottz/packaging/arch-packages/infra/lxc/bootstrap-arch-builder
```

If `arch-packages` or `kottz-secrets` are private, place those repos by whatever
one-time method you have available, then install the age identity from Bitwarden
before running the bootstrap. The bootstrap installs systemd credentials and
uses the GitHub token credential for source repo clones.
It also repairs ownership of `/srv/kottz/packaging`, `/srv/kottz/src`, and
`/srv/kottz/repo` so the `kottz` service user can write logs, build outputs,
and package repository files.

Manual credential install:

```bash
SOPS_AGE_KEY_FILE=/etc/kottz/age/arch-packages.txt \
  /srv/kottz/packaging/arch-packages/scripts/install-credentials
```

## Checks

```bash
/srv/kottz/packaging/arch-packages/infra/lxc/doctor
/srv/kottz/packaging/arch-packages/scripts/run-with-credentials \
  /srv/kottz/packaging/arch-packages/scripts/doctor-secrets
/srv/kottz/packaging/arch-packages/scripts/run-with-credentials \
  /srv/kottz/packaging/arch-packages/scripts/test-notifications
/srv/kottz/packaging/arch-packages/scripts/run-with-credentials \
  /srv/kottz/packaging/arch-packages/scripts/check-github-access
curl -I http://127.0.0.1:8080/x86_64/kottz.db
systemctl list-timers kottz-arch-packages.timer
systemctl start kottz-arch-packages.service
```
