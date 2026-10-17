#!/usr/bin/env bash
# Logs every suspend and resume to ~/.local/state/sleep.log, to catch the laptop cold-booting
# instead of resuming. logind announces each sleep on the system bus (PrepareForSleep true
# before, false after), so this needs no root. Hyprland starts it at login.
#
# Before sleep it records what could matter (external monitor, lid, AC, uptime); after resume,
# how long it slept and what woke it. At start it checks the previous boot: if its last entry
# is "sleep" with no "resume", that sleep never came back, and a DIED line says so.
set -uo pipefail

log=${SLEEP_LOG:-$HOME/.local/state/sleep.log}
mkdir -p "$(dirname "$log")"
exec 9>"$log.lock"
flock -n 9 || exit 0

boot=$(cat /proc/sys/kernel/random/boot_id)
note() { echo "$(date -Is) boot=${boot:0:8} $*" >>"$log"; }

context() {
    local hdmi lid ac outputs
    hdmi=$(cat /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null | head -1)
    lid=$(awk '{print $2}' /proc/acpi/button/lid/*/state 2>/dev/null | head -1)
    ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)
    outputs=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | "\(.name):\(if .dpmsStatus then "on" else "off" end)"] | join(",")')
    echo "hdmi=${hdmi:-?} lid=${lid:-?} ac=${ac:-?} outputs=${outputs:-?} uptime=$(cut -d' ' -f1 /proc/uptime)s"
}

# The previous boot's last entry tells whether its last sleep came back.
last=$(tail -1 "$log" 2>/dev/null)
case $last in
    *" boot=${boot:0:8} "*) ;;
    *" sleep "*) note "DIED: previous boot never resumed from: $last" ;;
esac
note "start $(context)"

slept_at=0
gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 |
    while read -r line; do
        case $line in
            *PrepareForSleep\ \(true,\)*)
                slept_at=$(date +%s)
                note "sleep $(context)"
                sync "$log"
                ;;
            *PrepareForSleep\ \(false,\)*)
                irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)
                source=${irq:+$irq $(awk -v i="$irq:" '$1 == i {print $NF}' /proc/interrupts)}
                note "resume after $(($(date +%s) - slept_at))s wake=${source:-unknown} $(context)"
                ;;
        esac
    done
