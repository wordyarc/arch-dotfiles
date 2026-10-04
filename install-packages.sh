#!/usr/bin/env bash

set -euo pipefail

if (( $# )); then
  echo "usage: ${0##*/}" >&2
  exit 2
fi

read_packages() {
  local package
  local -n result=$2

  while read -r package || [[ -n "$package" ]]; do
    [[ -z "$package" ]] || result+=("$package")
  done < "$1"
}

cd "$(dirname "${BASH_SOURCE[0]}")"

repo_packages=()
aur_packages=()
read_packages pkglist.txt repo_packages
read_packages pkglist_aur.txt aur_packages

if (( ${#repo_packages[@]} )); then
  sudo pacman -Syu --needed -- "${repo_packages[@]}"
fi

if (( ${#aur_packages[@]} )); then
  paru -Sa --needed -- "${aur_packages[@]}"
fi
