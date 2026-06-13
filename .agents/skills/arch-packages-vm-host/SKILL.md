---
name: arch-packages-vm-host
description: Bootstrap and operate the kottz Arch package builder VM, including systemd maintenance units, SOPS/age secrets, Telegram notifications, source checkout layout, clean chroot builds, and secure service-user conventions. Use when Codex is asked to set up, validate, or change the package builder host automation.
---

# Arch Packages VM Host

Use this skill in `kottz/arch-packages` when changing builder-host automation.

## Workflow

1. Read `AGENTS.md`.
2. Keep deterministic host setup in `infra/vm/`.
3. Keep runtime execution scripts in `scripts/`.
4. Keep systemd units in `systemd/`.
5. Keep plaintext secrets out of this repo.

## Host Layout

- Package repo: `/srv/kottz/packaging/arch-packages`
- Source repos: `/srv/kottz/src/{sway,Waybar}`
- Binary repo: `/srv/kottz/repo/x86_64`
- Clean chroot: `/srv/kottz/chroot`
- Internal package HTTP server: Caddy on `:8080`, root `/srv/kottz/repo`
- Encrypted secrets repo: `/srv/kottz/secrets/kottz-secrets`
- Builder age identity: `/etc/kottz/age/arch-packages.txt`
- Systemd encrypted credentials: `/etc/credstore.encrypted/kottz.arch-packages.*`

The systemd service runs as the `kottz` user. Do not make package builds run as
root; `makepkg` needs an unprivileged user. Bootstrap must ensure
`/srv/kottz/packaging`, `/srv/kottz/src`, and `/srv/kottz/repo` are writable by
`kottz`, and must configure a Git `user.name` and `user.email` for that user so
automated rebases can create commits.

Treat source checkouts under `/srv/kottz/src` as managed by the builder.
Maintenance scripts should run Git operations as `kottz` and sync source
branches from `origin/<branch>` before rebasing.

Package builds must use Arch devtools clean chroots through `mkarchroot` and
`makechrootpkg`. Do not add a host `makepkg` fallback to the automated builder.
Bootstrap should remove incomplete clean-chroot directories when
`etc/makepkg.conf` is missing.

## Secrets

Use SOPS with age as the portable source of truth. The private age identity is
stored in Bitwarden and installed on the VM as `root:root` mode `0400`.
Runtime delivery uses systemd encrypted credentials installed with
`scripts/install-credentials`.

Expected SOPS YAML shape:

```yaml
telegram:
  bot_token: ""
  chat_id: ""
openrouter:
  api_key: ""
github:
  token: ""
```

`github.token` is optional. Prefer SSH deploy keys for Git pushes if sufficient.
If a fine-grained token is used, restrict it to the required repos with contents
read/write access.

When `github.token` is present, builder Git operations should use
`scripts/git-with-credentials` and HTTPS remotes. Do not assume SSH keys exist
on the builder VM.

## Commands

Validate host scripts:

```bash
bash -n infra/vm/bootstrap-arch-builder infra/vm/doctor
bash -n scripts/*
caddy validate --config infra/caddy/Caddyfile --adapter caddyfile
infra/vm/doctor
```

Bootstrap inside a fresh Arch VM:

```bash
infra/vm/bootstrap-arch-builder
```

Install host-bound credentials:

```bash
SOPS_AGE_KEY_FILE=/etc/kottz/age/arch-packages.txt scripts/install-credentials
```

Check operations:

```bash
scripts/run-with-credentials scripts/doctor-secrets
scripts/run-with-credentials scripts/test-notifications
scripts/run-with-credentials scripts/check-github-access
```
