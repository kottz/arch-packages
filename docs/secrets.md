# Secrets

Secrets are stored outside this repo in `kottz-secrets` and encrypted with SOPS
using age. Runtime delivery uses systemd encrypted credentials, not secret
environment variables.

Recommended setup:

- One dedicated age identity for this automation: `arch-packages`.
- Store the private identity in Bitwarden.
- Commit only the public recipient and encrypted files.
- Install the private identity on the builder at
  `/etc/kottz/age/arch-packages.txt` as `root:root` with mode `0400`.

The portable source of truth is:

```text
/srv/kottz/secrets/kottz-secrets/secrets/arch-packages.enc.yaml
```

Expected shape:

```yaml
telegram:
  bot_token: ""
  chat_id: ""

openrouter:
  api_key: ""

github:
  token: ""
```

Install host-bound systemd credentials on the builder with:

```bash
SOPS_AGE_KEY_FILE=/etc/kottz/age/arch-packages.txt \
  scripts/install-credentials
```

The service receives credentials as files under `$CREDENTIALS_DIRECTORY`.
Opencode reads the OpenRouter API key through its `{file:...}` config
substitution. `github.token` is optional; prefer SSH deploy keys if that is
enough. If you use a fine-grained token, restrict it to the required repos with
contents read/write access.

When `github.token` is present, builder Git operations use HTTPS through
`scripts/git-with-credentials`; no SSH key is required for source fork fetches
or pushes.
