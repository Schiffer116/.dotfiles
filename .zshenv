### EXPORT ###
export EDITOR='nvim'
export HISTCONTROL='ignoreboth:erasedups'
export MANPAGER='nvim +Man!'

export VDPAU_DRIVER=va_gl
export LIBVA_DRIVER_NAME=iHD

export RANGER_LOAD_DEFAULT_RC=false

export DISABLE_QT5_COMPAT=1

export PATH=$PATH:$HOME/scripts:$HOME/Documents/eww/target/release

# ibus
export XMODIFIERS=@im=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx

# pidof ibus-daemon > /dev/null || ibus-daemon -drx

# cleanup
export CARGO_HOME=$HOME/.cargo

source "$HOME/.cargo/env"
