setopt HIST_IGNORE_ALL_DUPS
unsetopt beep
zstyle :compinstall filename '/home/schiffer/.zshrc'

# completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# vi mode
bindkey -v
export KEYTIMEOUT=1

# colors
autoload -U colors && colors

# History in cache directory:
HISTSIZE=100
SAVEHIST=100
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

bindkey -s "^f" 'tmux-session.sh^M'
bindkey -s "^r" 'ranger^M'
bindkey -s "^v" 'hyprctl keyword monitor eDP-1,preferred,auto,1,transform,1^M'
bindkey -s "^h" 'hyprctl keyword monitor eDP-1,preferred,auto,1,transform,0^M'

alias wallpaper='swaybg -m fill -i'

# nvim-dap
alias dapterm='echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope'

# camera
alias camera='mpv /dev/video0 --profile=low-latency --untimed'

# image preview
alias icat='kitty +kitten icat'

alias ls='exa --color=always --icons'
alias la='exa -a --color=always --icons'
alias ll='exa -ahl --color=always --icons'
alias tree='exa --tree --color=always --icons'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias du='du -h'
alias df='df -h'

alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

eval "$(starship init zsh)"

source "$XDG_DATA_HOME/cargo/env"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null

# [ -f "/home/schiffer/.ghcup/env" ] && source "/home/schiffer/.ghcup/env" # ghcup-env

# cleanup
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
