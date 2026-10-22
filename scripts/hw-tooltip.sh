#!/bin/bash
# Prints the tooltip text of one of the bar's hardware rings: cpu, ram or disk.
# Columns are space-aligned for the bar's monospace font. Run by an eww defpoll
# that only polls while a ring is hovered, so it costs nothing otherwise.
set -uo pipefail

GIB=1073741824
TOP_N=5

# Prints the bytes in $1 as GiB with one decimal.
gib() { awk -v b="$1" -v g="$GIB" 'BEGIN { printf "%.1f", b / g }'; }

# Reads "name value" lines and prints the top rows, summed by name, with a
# "xN" suffix when several processes share it. $1 is the printf format of the
# value column; $2 is "bytes" to render the value as MB/GB instead.
top_procs() {
  awk '{ sum[$1] += $2; cnt[$1]++ } END { for (k in sum) print sum[k], k, cnt[k] }' |
    sort -rn | head -n "$TOP_N" |
    awk -v fmt="$1" -v bytes="${2:-}" '{
      v = $1
      if (bytes) v = v >= 1073741824 ? sprintf("%.1f GB", v / 1073741824) : sprintf("%d MB", v / 1048576)
      printf "  %-16s %8s%s\n", $2, (bytes ? v : sprintf(fmt, v)), ($3 > 1 ? "  x" $3 : "")
    }'
}

# Per-core busy percent over a 0.5s window, four cores per row.
cores() {
  local a b
  a=$(grep '^cpu[0-9]' /proc/stat)
  sleep 0.5
  b=$(grep '^cpu[0-9]' /proc/stat)
  paste -d' ' <(echo "$a") <(echo "$b") | awk '
    {
      t1 = 0; t2 = 0
      for (i = 2; i <= 11; i++) { t1 += $i; t2 += $(i + 11) }
      idle = ($(5 + 11) + $(6 + 11)) - ($5 + $6)
      busy = (t2 - t1) > 0 ? 100 * (1 - idle / (t2 - t1)) : 0
      printf "%s%d %3d%%", (NR % 4 == 1 ? "  " : "   "), NR - 1, busy
      if (NR % 4 == 0) printf "\n"
    }
    END { if (NR % 4) printf "\n" }'
}

cpu() {
  local load temp frame top_pid
  load=$(awk -v n="$(nproc)" '{ printf "%d", 100 * $1 / n }' /proc/loadavg)
  temp=$(sensors 2>/dev/null | awk '/^Package id 0/ { gsub(/[+°C]/, "", $4); printf "%d", $4 }')
  frame=$(mktemp)
  top -b -n2 -d0.5 -w 120 -o %CPU >"$frame" &
  top_pid=$!
  echo "CPU load ${load}%${temp:+ · ${temp}°C}"
  echo
  cores
  wait
  echo
  echo "Top by CPU"
  awk -v top_pid="$top_pid" '/^top -/ { n++ } n == 2 && /^ *PID/ { go = 1; next } n == 2 && go && $1 != top_pid { print $12, $9 }' "$frame" |
    top_procs "%.1f%%"
  rm -f "$frame"
}

ram() {
  local total used avail
  read -r total used avail < <(free -b | awk '/^Mem:/ { print $2, $3, $7 }')
  echo "RAM $(gib "$used") / $(gib "$total") GB · $(gib "$avail") GB available"
  free -b | awk -v g="$GIB" '/^Swap:/ && $2 > 0 { printf "Swap %.1f / %.1f GB\n", $3 / g, $2 / g }'
  if [ -r /sys/block/zram0/mm_stat ]; then
    awk -v g="$GIB" '{ printf "zram %.2f GB stored, %.2f GB compressed\n", $1 / g, $2 / g }' \
      /sys/block/zram0/mm_stat
  fi
  echo
  echo "Top by memory (RSS)"
  ps -eo comm=,rss= | awk '{ print $1, $2 * 1024 }' | top_procs "" bytes
}

disk() {
  echo "Disk"
  findmnt -rnbo TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL |
    awk -v g="$GIB" '
      $2 ~ /^\/dev\// && $3 !~ /^(squashfs|iso9660)$/ && !seen[$2]++ {
        pct = $4 > 0 ? 100 * $5 / $4 : 0
        printf "  %-26s %6.1f / %6.1f GB  %5.1f free  %3d%%\n", $1, $5 / g, $4 / g, $6 / g, pct
      }'
  local io
  io=$(awk '$3 ~ /^(sd[a-z]|nvme[0-9]+n[0-9]+|vd[a-z])$/ {
              printf "  %-26s read %.1f GB  written %.1f GB\n", $3, $6 * 512 / 1073741824, $10 * 512 / 1073741824
            }' /proc/diskstats)
  [ -n "$io" ] && { echo; echo "I/O since boot"; echo "$io"; }
}

case "${1:-}" in
  cpu) cpu ;;
  ram) ram ;;
  disk) disk ;;
  *) echo "usage: hw-tooltip.sh cpu|ram|disk" >&2; exit 2 ;;
esac
