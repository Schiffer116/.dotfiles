### EXPORT ###
export EDITOR=nvim
export HISTCONTROL=ignoreboth:erasedups
export PAGER='most'
export MANPAGER=less

export LIBVA_DRIVER_NAME=vdpau
export VDPAU_DRIVER=nvidia

export RANGER_LOAD_DEFAULT_RC=false
export RANGER_DEVICONS_SEPARATOR="  "

export QT_QPA_PLATFORM=wayland
export DISABLE_QT5_COMPAT=1

# PATH
export PATH=$PATH:$HOME/.local/bin/

#ibus
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
pidof ibus-daemon > /dev/null || ibus-daemon -drx

# cleanup
export HISTFILE=$HOME/bash/history
export CARGO_HOME=$HOME/.cargo
# export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

source "$HOME"/.bashrc
eval "$(starship init bash)"

. "$HOME/.cargo/env"
