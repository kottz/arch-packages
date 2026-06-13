#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck source=../config/packages.sh
source "$ROOT/config/packages.sh"

SOURCE_ROOT=${KOTTZ_SOURCE_ROOT:-$(cd -- "$ROOT/.." && pwd)}
REPO_DIR=${KOTTZ_REPO_DIR:-"$ROOT/repo/x86_64"}
LOG_DIR=${KOTTZ_LOG_DIR:-"$ROOT/logs"}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

package_exists() {
  local package=$1
  [[ -n ${PACKAGE_SOURCE_DIR[$package]+set} ]]
}

package_dir() {
  local package=$1
  printf '%s/packages/%s\n' "$ROOT" "$package"
}

source_dir() {
  local package=$1
  printf '%s/%s\n' "$SOURCE_ROOT" "${PACKAGE_SOURCE_DIR[$package]}"
}

selected_packages() {
  if [[ $# -eq 0 || ${1:-} == "all" ]]; then
    printf '%s\n' "${PACKAGES[@]}"
    return
  fi

  local package
  for package in "$@"; do
    package_exists "$package" || die "unknown package '$package'"
    printf '%s\n' "$package"
  done
}

ensure_source_repo() {
  local package=$1
  local repo
  local origin_url
  repo=$(source_dir "$package")
  [[ -d $repo/.git ]] || die "missing source repo for $package: $repo"

  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    git -C "$repo" remote add origin "${PACKAGE_ORIGIN[$package]}"
  else
    origin_url=$(git -C "$repo" remote get-url origin)
    if [[ $origin_url == git@github.com:* && ${PACKAGE_ORIGIN[$package]} == https://github.com/* ]]; then
      git -C "$repo" remote set-url origin "${PACKAGE_ORIGIN[$package]}"
    fi
  fi
  if ! git -C "$repo" remote get-url upstream >/dev/null 2>&1; then
    git -C "$repo" remote add upstream "${PACKAGE_UPSTREAM[$package]}"
  fi
}

ensure_git_worktree_ready() {
  local repo=$1
  local label=$2
  local state path

  for state in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    path=$(git -C "$repo" rev-parse --git-path "$state" 2>/dev/null) ||
      die "$label is not a git repository: $repo"
    if [[ -e $path ]]; then
      die "$label has an in-progress Git operation ($state); resolve or abort it before continuing"
    fi
  done

  if [[ -n $(git -C "$repo" status --porcelain=v1) ]]; then
    git -C "$repo" status --short >&2
    die "$label has uncommitted changes"
  fi
}

sync_source_branch_from_origin() {
  local package=$1
  local repo
  local branch
  local remote_ref
  local current=
  local remote=

  repo=$(source_dir "$package")
  branch=${PACKAGE_BRANCH[$package]}
  remote_ref=refs/remotes/origin/$branch

  ensure_git_worktree_ready "$repo" "$package source"

  if git -C "$repo" rev-parse --verify --quiet "$branch" >/dev/null; then
    current=$(git -C "$repo" rev-parse "$branch")
  fi
  remote=$(git -C "$repo" rev-parse "$remote_ref")

  if [[ $current != "$remote" ]]; then
    printf '%s: syncing local branch %s to origin/%s\n' "$package" "$branch" "$branch"
  fi

  git -C "$repo" switch -C "$branch" "$remote_ref"
}

latest_upstream_tag() {
  local package=$1
  local repo
  repo=$(source_dir "$package")
  git -C "$repo" tag -l "${PACKAGE_TAG_MATCH[$package]}" --sort=-v:refname |
    grep -E '^[0-9]+([.][0-9]+)*$' |
    head -n1
}

run_source_tests() {
  local package=$1
  local repo
  repo=$(source_dir "$package")
  (cd "$repo" && bash -lc "${PACKAGE_SOURCE_TEST[$package]}")
}

sanitize_for_notification() {
  sed -E \
    -e 's/github_pat_[A-Za-z0-9_]+/[redacted-github-token]/g' \
    -e 's/(Authorization: Bearer )[A-Za-z0-9._-]+/\1[redacted]/g' \
    -e 's#https://[^/@]+@github[.]com/#https://[redacted]@github.com/#g'
}

summarize_failure_log() {
  local log_file=$1

  if [[ ! -s $log_file ]]; then
    printf 'failed with no captured output'
    return
  fi

  if grep -Eiq \
    'Authentication failed|Bad credentials|Invalid username or token|Permission denied [(]publickey[)]|Repository not found|could not read Username|HTTP 401|HTTP 403|403 Forbidden|Write access to repository not granted|support for password authentication was removed' \
    "$log_file"; then
    printf 'GitHub authentication or authorization failed'
    return
  fi

  if grep -Eiq \
    'Could not resolve host|Failed to connect|Connection timed out|Network is unreachable|Temporary failure in name resolution' \
    "$log_file"; then
    printf 'network connection to remote service failed'
    return
  fi

  if grep -Eiq \
    'OPENROUTER_API_KEY|OpenRouter|401 Unauthorized|invalid api key|Incorrect API key' \
    "$log_file"; then
    printf 'OpenRouter or model provider authentication failed'
    return
  fi

  if grep -Eiq \
    'Please tell me who you are|empty ident name|unable to auto-detect email address' \
    "$log_file"; then
    printf 'Git committer identity is not configured'
    return
  fi

  if grep -Eiq \
    'CONFLICT [(]|could not apply [0-9a-f]+|Resolve all conflicts manually|You can instead skip this commit|rebase in progress' \
    "$log_file"; then
    printf 'Git rebase or merge conflict needs attention'
    return
  fi

  local line
  line=$(sed -n '/[^[:space:]]/p' "$log_file" | head -n1 || true)
  if [[ -z $line ]]; then
    printf 'failed with no useful captured output'
    return
  fi

  printf '%s' "$line" | sanitize_for_notification
}
