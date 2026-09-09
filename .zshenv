export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export EDITOR='nvim'
export VISUAL="nvim"
export LESS="-R"

export MANPAGER='nvim +Man!'

# export VDPAU_DRIVER=va_gl
# export LIBVA_DRIVER_NAME=iHD

export RANGER_LOAD_DEFAULT_RC=false

export DISABLE_QT5_COMPAT=1

export PATH=$PATH:$XDG_DATA_HOME/cargo/bin
export PATH=$PATH:$XDG_DATA_HOME/go/bin
export PATH=$PATH:$HOME/scripts
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/miniconda3/bin

export DIRENV_LOG_FORMAT=""

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
export XMODIFIERS=@im=fcitx
export GTK_USE_PORTAL=1

export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GOPATH="$XDG_DATA_HOME"/go
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME"/jupyter
export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export VCPKG_ROOT=$HOME/.local/share/vcpkg
. "/home/schiffer/.local/share/cargo/env"

export VOLUME_SERVER_SOCKET=$XDG_RUNTIME_DIR/volume_server.sock
export VOLUME_LOG=$XDG_RUNTIME_DIR/volume.log
export BRIGHTNESS_SERVER_SOCKET=$XDG_RUNTIME_DIR/brightness_server.sock
