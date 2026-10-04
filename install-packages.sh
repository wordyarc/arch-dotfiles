#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: ${0##*/} [--disable-download-timeout]"
}

download_options=()
for arg; do
  case $arg in
    --disable-download-timeout) download_options=(--disable-download-timeout) ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

read_packages() {
  local package
  local -n result=$2

  while read -r package || [[ -n "$package" ]]; do
    [[ -z "$package" || "$package" == \#* ]] || result+=("$package")
  done < "$1"
}

cd "$(dirname "${BASH_SOURCE[0]}")"

repo_packages=()
aur_packages=()
read_packages pkglist.txt repo_packages
read_packages pkglist_aur.txt aur_packages

if (( ${#repo_packages[@]} )); then
  sudo pacman -Syu --needed "${download_options[@]}" -- "${repo_packages[@]}"
fi

if (( ${#aur_packages[@]} )); then
  paru -Sa --needed "${download_options[@]}" -- "${aur_packages[@]}"
fi
