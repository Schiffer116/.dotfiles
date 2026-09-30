zmodload zsh/complist

###########
# options #
###########

HISTSIZE=100
SAVEHIST=100
HISTFILE=$XDG_CACHE_HOME/zsh/history
# HISTCONTROL='ignoreboth:erasedups'

setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

##############
# completion #
##############

fpath=("$XDG_CONFIG_HOME/zsh" $fpath)

autoload -U compinit
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

compinit
_comp_options+=(globdots)

autoload bashcompinit
bashcompinit
complete -C '/usr/bin/aws_completer' aws


######
# vi #
######

bindkey -v
export KEYTIMEOUT=1

# cursor shape
cursor_mode() {
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
        if [[ ${KEYMAP} == vicmd ]] ||
            [[ $1 = 'block' ]]; then
            echo -ne $cursor_block
        elif [[ ${KEYMAP} == main ]] ||
            [[ ${KEYMAP} == viins ]] ||
            [[ ${KEYMAP} = '' ]] ||
            [[ $1 = 'beam' ]]; then
            echo -ne $cursor_beam
        fi
    }

    zle-line-init() {
        echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
}
cursor_mode

# menu selection
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# text objects
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done


############
# keybinds #
############

bindkey -s '^f' 'tmux-session.sh^M'
# bindkey -s '^r' 'rebuild.sh^M'

###########
# aliases #
###########

alias insomnia='insomnia --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland'
alias code='codium'
alias anki='anki --no-sandbox'

alias dapterm='echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope'

alias icat='kitty +kitten icat'

alias ls='exa --color=always --icons=always'
alias tree='exa --tree --color=always --icons=always'

alias grep='grep --color=auto'

alias du='du -h'
alias df='df -h'

# history-substring
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# alias less='less --raw-control-chars --color=always'

alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

alias gs='git status'
alias tf='terraform'

##############
# shellhooks #
##############

eval "$(starship init zsh)"
eval "$(direnv hook $SHELL)"

if [ -z $DISPLAY ]; then
    start-hyprland
fi

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-auto-notify/auto-notify.plugin.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Play a sound when a long-running command finishes (same trigger conditions as auto-notify above)
[[ -z "$AUTO_NOTIFY_SOUND_FILE" ]] &&
    export AUTO_NOTIFY_SOUND_FILE=/usr/share/sounds/freedesktop/stereo/complete.oga

function _auto_notify_sound_track() {
    AUTO_NOTIFY_SOUND_START="$(date +"%s")"
    AUTO_NOTIFY_SOUND_CMD="$3"
}

function _auto_notify_sound_play() {
    local exit_code="$?"
    [[ -z "$AUTO_NOTIFY_SOUND_START" ]] && return

    local current="$(date +"%s")"
    local elapsed=$((current - AUTO_NOTIFY_SOUND_START))
    if [[ $elapsed -gt $AUTO_NOTIFY_THRESHOLD ]] && [[ "$(_is_auto_notify_ignored "$AUTO_NOTIFY_SOUND_CMD")" == "no" ]]; then
        (paplay "$AUTO_NOTIFY_SOUND_FILE" &) 2>/dev/null
    fi
    unset AUTO_NOTIFY_SOUND_START AUTO_NOTIFY_SOUND_CMD
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _auto_notify_sound_track
add-zsh-hook precmd _auto_notify_sound_play

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/schiffer/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/schiffer/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/schiffer/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/schiffer/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

. "$HOME/.local/share/../bin/env"
