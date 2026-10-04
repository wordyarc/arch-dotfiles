mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh"

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT

typeset -U path PATH fpath FPATH
if [[ -d "$XDG_CONFIG_HOME/zsh/completions" ]]; then
  fpath=("$XDG_CONFIG_HOME/zsh/completions" $fpath)
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

source "$XDG_CONFIG_HOME/zsh/oh-my-zsh.zsh"

source "$XDG_CONFIG_HOME/zsh/integrations.zsh"
source "$XDG_CONFIG_HOME/zsh/aliases.zsh"
source "$XDG_CONFIG_HOME/zsh/functions.zsh"
source "$XDG_CONFIG_HOME/zsh/local.zsh"

export VIRTUAL_ENV_DISABLE_PROMPT=1
