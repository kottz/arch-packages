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
  repo=$(source_dir "$package")
  [[ -d $repo/.git ]] || die "missing source repo for $package: $repo"

  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    git -C "$repo" remote add origin "${PACKAGE_ORIGIN[$package]}"
  fi
  if ! git -C "$repo" remote get-url upstream >/dev/null 2>&1; then
    git -C "$repo" remote add upstream "${PACKAGE_UPSTREAM[$package]}"
  fi
}

latest_upstream_tag() {
  local package=$1
  local repo
  repo=$(source_dir "$package")
  git -C "$repo" tag -l "${PACKAGE_TAG_MATCH[$package]}" --sort=-v:refname | head -n1
}

run_source_tests() {
  local package=$1
  local repo
  repo=$(source_dir "$package")
  (cd "$repo" && bash -lc "${PACKAGE_SOURCE_TEST[$package]}")
}
