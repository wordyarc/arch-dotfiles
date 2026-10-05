#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: ${0##*/} [--dry-run] [--delete]"
}

install_file() {
  local source=$1 target=$2 status=0

  cmp -s "$source" "$target" && return
  if $dry_run; then
    diff -uN "$target" "$source" || status=$?
    (( status <= 1 ))
    return
  fi

  mkdir -p "${target%/*}"
  cp -p "$source" "$target"
  echo "$target"
}

prune_dir() {
  local source_dir=$1 target_dir=$2 target relative

  [[ -d "$target_dir" ]] || return 0
  while IFS= read -r -d '' target; do
    relative=${target#"$target_dir/"}
    [[ -f "$source_dir/$relative" ]] && continue
    if $dry_run; then
      echo "would delete $target"
    else
      rm -f "$target"
      echo "deleted $target"
    fi
  done < <(find "$target_dir" ! -type d -print0)

  $dry_run || find "$target_dir" -depth -type d -empty -delete
}

dry_run=false
delete=false
for arg; do
  case $arg in
    --dry-run) dry_run=true ;;
    --delete) delete=true ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")"
config_home=${XDG_CONFIG_HOME:-$HOME/.config}

for file in .zshenv .zshrc; do
  install_file "$file" "$HOME/$file"
done

for source_dir in .config/*; do
  [[ -d "$source_dir" ]] || continue
  app=${source_dir##*/}
  target_dir="$config_home/$app"
  while IFS= read -r -d '' file; do
    relative=${file#"$source_dir/"}
    install_file "$file" "$target_dir/$relative"
  done < <(find "$source_dir" -type f -print0)

  if $delete; then
    prune_dir "$source_dir" "$target_dir"
  fi
done
