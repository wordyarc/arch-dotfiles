# -- XDG -------------------------------------------------------
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
mkdir -p "${LESSHISTFILE:h}"

export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export IPYTHONDIR="$XDG_DATA_HOME/ipython"
export KONAN_DATA_DIR="$XDG_CACHE_HOME/konan"

export CLAUDE_CONFIG_DIR="$XDG_DATA_HOME/claude"
export CODEX_HOME="$XDG_DATA_HOME/codex"
export COPILOT_HOME="$XDG_DATA_HOME/copilot"

# Rust
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# SDKMAN
export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [[ -n "$JAVA_HOME" && -d "$JAVA_HOME/bin" ]]; then
  path=("$JAVA_HOME/bin" $path)
fi
