#!/usr/bin/env bash
# Bootstrap: enable repo git hooks and stow every package into $HOME.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

command -v stow >/dev/null || { echo "stow is not installed: sudo pacman -S stow" >&2; exit 1; }

git config core.hooksPath .githooks

# Every non-hidden top-level directory is a stow package.
mapfile -t packages < <(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' | sort)

stow --no "${packages[@]}" >/dev/null # dry run first: abort before touching anything on conflict
stow "${packages[@]}"

echo "Stowed: ${packages[*]}"
