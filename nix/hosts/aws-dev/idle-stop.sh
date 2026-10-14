# Stop the box once the firstmate fleet and the captain have been idle for IDLE_MINUTES.
#
# Run every few minutes by a systemd timer, as root. The EC2 instance is created with
# instance_initiated_shutdown_behavior = "stop", so a poweroff stops it (EBS is kept);
# `scripts/devbox.sh start` brings it back.
#
# A run counts as busy when any of these holds:
#   - the inhibit file exists (touch it to keep the box up, e.g. over a long CI wait)
#   - someone is logged in: utmp, an OpenSSH session, or a Tailscale SSH session
#   - a firstmate lane reports state=busy in $FLEET_HOME/state/*.busy-state, or reports
#     state=unknown recently (a harness that cannot classify itself is never idle)
#   - the machine used more than CPU_PERCENT of one vCPU since the previous run
#     (catches interactive agents and builds that have no busy-state record)
# The box stops only after IDLE_MINUTES of consecutive idle runs.
set -euo pipefail

idle_minutes=${IDLE_MINUTES:-30}
cpu_percent=${CPU_PERCENT:-20}
unknown_grace_minutes=${UNKNOWN_GRACE_MINUTES:-120}
fleet_home=${FLEET_HOME:-/home/schiffer/firstmate}
inhibit_file=${INHIBIT_FILE:-/home/schiffer/.config/idle-stop/inhibit}
state_dir=${STATE_DIR:-/run/idle-stop}
proc_stat=${PROC_STAT:-/proc/stat}
dry_run=${DRY_RUN:-0}

mkdir -p "$state_dir"
now=$(date +%s)

# Busy share of one vCPU since the previous run, in whole percent. Empty on the first run.
cpu_since_last_run() {
  local cpus total idle prev_total prev_idle
  cpus=$(grep -c '^cpu[0-9]' "$proc_stat")
  read -r total idle < <(awk '/^cpu / { t = 0; for (i = 2; i <= NF; i++) t += $i; print t, $5 + $6 }' "$proc_stat")
  if [[ -f $state_dir/cpu ]]; then
    read -r prev_total prev_idle <"$state_dir/cpu"
    if ((total > prev_total)); then
      echo $(((100 * cpus * ((total - prev_total) - (idle - prev_idle))) / (total - prev_total)))
    fi
  fi
  echo "$total $idle" >"$state_dir/cpu"
}

# Prints why the box is busy, or nothing when it is idle.
busy_reason() {
  local f record ts

  if [[ -e $inhibit_file ]]; then
    echo "inhibited by $inhibit_file"
    return
  fi

  if [[ -n $(who) ]]; then
    echo "user logged in: $(who | awk '{ print $1 "@" $2 }' | paste -sd ' ')"
    return
  fi
  if pgrep -f '^sshd(-session)?: [^ ]+@' >/dev/null || pgrep -f 'tailscaled be-child ssh' >/dev/null; then
    echo "SSH session open"
    return
  fi

  for f in "$fleet_home"/state/*.busy-state; do
    [[ -f $f ]] || continue
    record=$(head -n 1 "$f")
    if [[ " $record " == *" state=busy "* ]]; then
      echo "fleet lane busy: $(basename "$f" .busy-state)"
      return
    fi
    if [[ " $record " == *" state=unknown "* ]]; then
      ts=$(sed -n 's/.* ts=\([0-9]*\).*/\1/p' <<<"$record")
      if [[ -z $ts ]] || ((now - ts < unknown_grace_minutes * 60)); then
        echo "fleet lane state unknown: $(basename "$f" .busy-state)"
        return
      fi
    fi
  done

  if [[ -z $cpu ]]; then
    echo "first CPU sample"
  elif ((cpu > cpu_percent)); then
    echo "CPU ${cpu}% of one vCPU (limit ${cpu_percent}%)"
  fi
}

# Sampled on every run, so each measurement covers exactly one timer interval.
cpu=$(cpu_since_last_run)
reason=$(busy_reason)
if [[ -n $reason ]]; then
  rm -f "$state_dir/idle-since"
  echo "busy: $reason"
  exit 0
fi

if [[ ! -f $state_dir/idle-since ]]; then
  echo "$now" >"$state_dir/idle-since"
fi
idle_for=$((now - $(cat "$state_dir/idle-since")))
echo "idle for $((idle_for / 60)) min (stop at ${idle_minutes} min)"

if ((idle_for >= idle_minutes * 60)); then
  if [[ $dry_run == 1 ]]; then
    echo "would power off"
  else
    echo "powering off: idle for $((idle_for / 60)) min"
    systemctl poweroff
  fi
fi
