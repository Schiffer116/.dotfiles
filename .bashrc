### EXPORT ###
export EDITOR=nvim
export HISTCONTROL=ignoreboth:erasedups
export PAGER='most'
export RANGER_LOAD_DEFAULT_RC=false
export RANGER_DEVICONS_SEPARATOR="  "
export QT_QPA_PLATFORM=wayland
export DISABLE_QT5_COMPAT=1
export MANPAGER=less

#ibus
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
pidof ibus-daemon > /dev/null || ibus-daemon -drx

# cleanup
export HISTFILE="${XDG_STATE_HOME}"/bash/history
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

set -o vi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


if [ -d "$HOME/.bin" ] ;
  then PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

### ALIASES ###

#list
alias ls='exa -aG --color=always --icons'
alias la='exa -a --color=always --icons'
alias ll='ls -alFh'
alias l.="ls -A | egrep '^\.'"

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#pacman unlock
alias unlock="sudo rm /var/lib/pacman/db.lck"
alias rmpacmanlock="sudo rm /var/lib/pacman/db.lck"

#free
alias free="free -mt"

#continue download
alias wget="wget -c"

#audio check pulseaudio or pipewire
alias audio="pactl info | grep 'Server Name'"

#skip integrity check
alias yayskip='yay -S --mflags --skipinteg'

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

#shopt
shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects cd misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend # do not overwrite history
shopt -s expand_aliases # expand aliases


eval "$(starship init bash)"
