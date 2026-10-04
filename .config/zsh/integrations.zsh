if [[ -t 0 ]]; then
  export GPG_TTY="$(tty)"
fi

if (( $+commands[bat] )); then
  export MANPAGER='bat -l man -p'
fi

if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
