#!/usr/bin/env bash
# idle-brightness.sh dim|restore
#
# Soft wind-down for hypridle. brightnessctl is not installed on this machine,
# so this uses the same logind SetBrightness path the control panel falls back
# to. The pre-dim percentage is remembered in XDG_RUNTIME_DIR so a dim is never
# applied twice and a restore always lands on the level the user actually chose.
set -euo pipefail

action=${1:-}
state="${XDG_RUNTIME_DIR:-/tmp}/hypridle-brightness"

dev=$(basename "$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)")
[ -n "$dev" ] || exit 0

max=$(cat "/sys/class/backlight/$dev/max_brightness" 2>/dev/null || echo 0)
cur=$(cat "/sys/class/backlight/$dev/brightness" 2>/dev/null || echo 0)
[ "$max" -gt 0 ] || exit 0

pct=$(( cur * 100 / max ))

set_brightness() {
    busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
        org.freedesktop.login1.Session SetBrightness ssu backlight "$dev" "$1"
}

case "$action" in
    dim)
        [ -f "$state" ] && exit 0   # already dimmed
        [ "$pct" -le 30 ] && exit 0 # already darker than the target
        echo "$pct" > "$state"
        set_brightness $(( max * 25 / 100 ))
        ;;
    restore)
        [ -f "$state" ] || exit 0
        saved=$(cat "$state")
        rm -f "$state"
        set_brightness $(( max * saved / 100 ))
        ;;
    *)
        echo "usage: $0 dim|restore" >&2
        exit 2
        ;;
esac