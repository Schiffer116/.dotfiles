set -o vi

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

### ALIASES ###

# nvim-dap
alias dapterm='echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope'

# camera
alias camera='mpv av://v4l2:/dev/video0 --profile=low-latency --untimed'

# image preview
alias icat='kitty +kitten icat'

alias ls='exa -G --color=always --icons'
alias la='exa -aG --color=always --icons'
alias ll='exa -alhG --color=always --icons'
alias tree='exa --tree'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#free
alias free="free -mt"

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

eval "$(starship init bash)"

# . and source are synonyms
. "$HOME/.cargo/env"

[ -f "/home/schiffer/.ghcup/env" ] && source "/home/schiffer/.ghcup/env" # ghcup-env
