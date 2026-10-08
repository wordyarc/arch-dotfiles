#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: ${0##*/} [--disable-download-timeout]"
}

read_list() {
  local item
  local -n result=$2

  while read -r item || [[ -n "$item" ]]; do
    [[ -z "$item" || "$item" == \#* ]] || result+=("$item")
  done < "$1"
}

install_paru() {
  local build_dir

  command -v paru >/dev/null && return
  sudo pacman -S --needed base-devel git

  build_dir=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru.git "$build_dir"
  (cd "$build_dir" && makepkg -si) || { rm -rf "$build_dir"; return 1; }
  rm -rf "$build_dir"
}

# sync_tree SRC DEST [AS_ROOT]: mirror SRC/<path> onto DEST/<path>.
# Identical files are skipped, missing directories are created,
# executables get 755, everything else 644. Never deletes.
# AS_ROOT (true/false) selects sudo
#   sync_tree rootfs /         # system files, sudo
sync_tree() {
  local src=$1 dest=$2 as_root=${3:-} file target mode sudo=()

  if [[ -z $as_root ]]; then
    [[ -w "$dest" ]] && as_root=false || as_root=true
  fi
  $as_root && sudo=(sudo)

  while IFS= read -r -d '' file; do
    target="${dest%/}/${file#"$src"/}"
    cmp -s "$file" "$target" && continue
    mode=644
    [[ -x "$file" ]] && mode=755
    "${sudo[@]}" install -Dm"$mode" "$file" "$target"
    echo "$target"
  done < <(find "$src" -type f -print0)
}

enable_services() {
  local services=()

  read_list services.txt services
  if (( ${#services[@]} )); then
    sudo systemctl enable "${services[@]}"
  fi
}

setup_user() {
  local shell

  id -nG "$USER" | grep -qw docker || sudo usermod -aG docker "$USER"

  shell=$(getent passwd "$USER" | cut -d: -f7)
  [[ ${shell##*/} == zsh ]] || chsh -s /usr/bin/zsh
}

install_oh_my_zsh() {
  local omz_dir=$HOME/.oh-my-zsh

  [[ -d "$omz_dir" ]] || git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
}

install_tmux_plugins() {
  local tpm_dir=$XDG_DATA_HOME/tmux/plugins/tpm

  [[ -d "$tpm_dir" ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  "$tpm_dir/bin/install_plugins"
}

package_options=()
for arg; do
  case $arg in
    --disable-download-timeout) package_options=(--disable-download-timeout) ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if (( EUID == 0 )); then
  echo "${0##*/}: run as a regular user with sudo access" >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

install_paru
./install-packages.sh "${package_options[@]}"
./install-config.sh
install_oh_my_zsh
install_tmux_plugins
sync_tree rootfs /
enable_services
setup_user

echo "Done. Reboot to start greetd."
