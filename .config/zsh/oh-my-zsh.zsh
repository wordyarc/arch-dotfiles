export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="false"
HIST_STAMPS="yyyy-mm-dd"

plugins=(
  aliases
  git
  dotenv
  tmux
)

export ZSH_CACHE_DIR="$XDG_CACHE_HOME/oh-my-zsh"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump-$ZSH_VERSION"

export ZSH_DOTENV_ALLOWED_LIST="$XDG_STATE_HOME/zsh/dotenv-allowed.list"
export ZSH_DOTENV_DISALLOWED_LIST="$XDG_STATE_HOME/zsh/dotenv-disallowed.list"

mkdir -p "$ZSH_CACHE_DIR"

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
fi
