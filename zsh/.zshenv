### EXPORT ###
export EDITOR='nvim'
export HISTCONTROL='ignoreboth:erasedups'
export MANPAGER='nvim +Man!'

export VDPAU_DRIVER=va_gl
export LIBVA_DRIVER_NAME=iHD

export RANGER_LOAD_DEFAULT_RC=false

export DISABLE_QT5_COMPAT=1

export PATH=$PATH:$HOME/scripts:$HOME/Documents/eww/target/release

# export XMODIFIERS=@im=fcitx
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx

# pidof ibus-daemon > /dev/null || ibus-daemon -drx

# cleanup
# export CARGO_HOME=$HOME/.cargo
# source "$HOME/.cargo/env"

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export HISTFILE="${XDG_STATE_HOME}"/bash/history
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GOPATH="$XDG_DATA_HOME"/go
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME"/jupyter
export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export ZDOTDIR="$HOME"/.config/zsh

