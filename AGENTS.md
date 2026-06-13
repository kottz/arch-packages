# AGENTS.md

This repo owns Arch packaging and publishing for kottz-maintained forks. Source
features live in their upstream forks; this repo should stay focused on package
metadata, build scripts, repo publishing, and automation.

## Repositories

- Sway source fork: `https://github.com/kottz/sway.git`
- Waybar source fork: `https://github.com/kottz/Waybar.git`
- Package repo: `https://github.com/kottz/arch-packages.git`
- Secrets repo: `https://github.com/kottz/kottz-secrets.git`

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
- Prefer deterministic scripts in `scripts/`; call Opencode only when rebase,
  build, or package metadata maintenance fails.
- Treat `opencode run` as a repair attempt, not proof of success. Rerun the
  failed deterministic stage and continue only after it passes.
- Before automated pushes, require clean Git working trees. If Opencode changes
  files but does not commit them, stop instead of pushing stale commits.
- GitHub fetch/push failures should be classified from captured logs and sent
  to Telegram. Common auth failures should mention GitHub auth/permission rather
  than a generic exit code.
- Keep plaintext secrets out of this repo. Use SOPS files in `kottz-secrets`
  as the portable source of truth, then install host-bound systemd encrypted
  credentials with `scripts/install-credentials`.
- GitHub operations on the builder use HTTPS plus the `github_token` systemd
  credential through `scripts/git-with-credentials`; do not assume SSH keys
  exist inside a raw LXC.
- LXC/bootstrap work belongs under `infra/lxc/`; update `docs/secrets.md` if
  secret names or paths change.
- The package web server is Caddy serving `/srv/kottz/repo` on internal port
  `8080`; external TLS termination belongs to the Proxmox reverse proxy.

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

For builder host changes:

```bash
bash -n infra/lxc/bootstrap-arch-builder infra/lxc/doctor
bash -n scripts/*
scripts/doctor-secrets
caddy validate --config infra/caddy/Caddyfile --adapter caddyfile
infra/lxc/doctor
```

When changing Sway or Waybar source behavior, read the `AGENTS.md` in that
source repo and run that repo's build/test commands before updating packages.
