#!/usr/bin/env bash
# dpms.sh on|off
#
# Hyprland 0.56 parses `hyprctl dispatch` arguments as Lua, so the classic
# `hyprctl dispatch dpms off` is a syntax error (')' expected near 'on') and the
# display never actually turned off. Going through a script keeps the quoting out
# of hypridle.conf, which passes commands to the shell as plain words.
set -euo pipefail

action="${1:-on}"

case "$action" in
    on|off) ;;
    *)
        echo "usage: $0 on|off" >&2
        exit 2
        ;;
esac

hyprctl dispatch "hl.dsp.dpms({ action = \"$action\" })" >/dev/null