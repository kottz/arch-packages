#!/usr/bin/env bash

KOTTZ_REPO_NAME=${KOTTZ_REPO_NAME:-kottz}

PACKAGES=(
  sway-groups
  waybar-groups
)

declare -A PACKAGE_SOURCE_DIR=(
  [sway-groups]=sway
  [waybar-groups]=Waybar
)

declare -A PACKAGE_ORIGIN=(
  [sway-groups]=https://github.com/kottz/sway.git
  [waybar-groups]=https://github.com/kottz/Waybar.git
)

declare -A PACKAGE_FETCH_URL=(
  [sway-groups]=https://github.com/kottz/sway.git
  [waybar-groups]=https://github.com/kottz/Waybar.git
)

declare -A PACKAGE_UPSTREAM=(
  [sway-groups]=https://github.com/swaywm/sway.git
  [waybar-groups]=https://github.com/Alexays/Waybar.git
)

declare -A PACKAGE_BRANCH=(
  [sway-groups]=workspace-groups
  [waybar-groups]=workspace-groups
)

declare -A PACKAGE_TAG_MATCH=(
  [sway-groups]='[0-9]*'
  [waybar-groups]='[0-9]*'
)

declare -A PACKAGE_SOURCE_TEST=(
  [sway-groups]='meson compile -C build -j "${KOTTZ_BUILD_JOBS:-4}" && meson test -C build'
  [waybar-groups]='meson compile -C build -j "${KOTTZ_BUILD_JOBS:-4}" && meson test -C build'
)

declare -A PACKAGE_SKILL=(
  [sway-groups]=sway-workspace-groups-maintainer
  [waybar-groups]=waybar-workspace-groups-maintainer
)
