### EXPORT ###
export EDITOR='nvim'
export HISTCONTROL=ignoreboth:erasedups
export MANPAGER='nvim +Man!'

export LIBVA_DRIVER_NAME=vdpau
export VDPAU_DRIVER=nvidia

export RANGER_LOAD_DEFAULT_RC=false

export QT_QPA_PLATFORM=wayland
export DISABLE_QT5_COMPAT=1

# PATH
export PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/scripts/

#ibus
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
pidof ibus-daemon > /dev/null || ibus-daemon -drx

# cleanup
export CARGO_HOME=$HOME/.cargo

source "$HOME/.cargo/env"
