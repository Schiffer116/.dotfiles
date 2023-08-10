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
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

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
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

bindkey -s "^f" 'tmux-session.sh^M'
bindkey -s "^r" 'ranger^M'

alias wallpaper='swaybg -m fill -i'

# nvim-dap
alias dapterm='echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope'

# camera
alias camera='mpv av://v4l2:/dev/video0 --profile=low-latency --untimed'

# image preview
alias icat='kitty +kitten icat'

alias ls='exa --color=always --icons'
alias la='exa -a --color=always --icons'
alias ll='exa -ahl --color=always --icons'
alias tree='exa --tree --color=always --icons'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias free="free -mt"

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

eval "$(starship init zsh)"

source "$HOME/.cargo/env"

[ -f "/home/schiffer/.ghcup/env" ] && source "/home/schiffer/.ghcup/env" # ghcup-env


export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
