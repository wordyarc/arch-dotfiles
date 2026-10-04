alias ll='ls -lh'
alias la='ls -lah'
if (( $+commands[bat] )); then
  alias cat='bat --paging never --decorations never --plain'
fi
alias df='df -h'
alias -- -='cd -'
alias cls='printf "\033[3J\033[H\033[2J"'

alias vim='nvim'
alias mc='SHELL=/bin/bash mc'

alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'

alias dclean='docker ps -q | xargs -r docker stop && docker container prune -f && docker volume prune -af'
