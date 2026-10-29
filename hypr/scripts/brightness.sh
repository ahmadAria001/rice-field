#!/usr/bin/env bash
# brightness.sh up|down|set <pct> [step]
#
# The XF86MonBrightnessUp/Down binds used to call brightnessctl, which is not
# installed here, so both keys did nothing. This drives the panel through logind's
# SetBrightness instead -- the same path the control panel already falls back to.
set -euo pipefail

dev=$(basename "$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)")
[ -n "$dev" ] || exit 0

max=$(cat "/sys/class/backlight/$dev/max_brightness" 2>/dev/null || echo 0)
[ "$max" -gt 0 ] || exit 0

cur=$(cat "/sys/class/backlight/$dev/brightness" 2>/dev/null || echo 0)
pct=$(( cur * 100 / max ))

action=${1:-}
step=${3:-5}

case "$action" in
    up)   pct=$(( pct + step ));;
    down) pct=$(( pct - step ));;
    set)  pct=${2:-50};;
    *)
        echo "usage: $0 up|down|set <pct> [step]" >&2
        exit 2
        ;;
esac

# A single 5% step out of a fully dark panel is invisible, which reads as the key
# still being broken. Land somewhere legible instead.
if [ "$action" = "up" ] && [ "$pct" -gt 0 ] && [ "$pct" -lt 10 ]; then
    pct=10
fi

[ "$pct" -lt 0 ] && pct=0
[ "$pct" -gt 100 ] && pct=100

# Prefer brightnessctl when it is installed, so the keys and the control panel
# drive the panel the same way; logind is the fallback that needs no extra tool.
if command -v brightnessctl >/dev/null 2>&1; then
    brightnessctl -q set "${pct}%"
else
    busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
        org.freedesktop.login1.Session SetBrightness ssu backlight "$dev" $(( max * pct / 100 ))
fi