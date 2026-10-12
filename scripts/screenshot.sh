#!/usr/bin/env bash
set -eo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
MODE="${1:-area}"

case "$MODE" in
    area)
        # Select region with slurp, exit cleanly if user cancels (e.g. presses Escape)
        GEOM=$(slurp 2>/dev/null) || exit 0
        [ -z "$GEOM" ] && exit 0
        grim -g "$GEOM" "$FILE"
        ;;
    window)
        # Query active window geometry from Hyprland IPC
        GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
        if [ -z "$GEOM" ] || [ "$GEOM" = "null,null nullxnull" ]; then
            exit 0
        fi
        grim -g "$GEOM" "$FILE"
        ;;
    screen)
        # Capture all monitors / active screen
        grim "$FILE"
        ;;
    *)
        echo "Usage: $0 [area|window|screen]"
        exit 1
        ;;
esac

# If image was successfully generated
if [ -f "$FILE" ]; then
    # Copy PNG directly to Wayland clipboard
    wl-copy --type image/png < "$FILE"
    
    # Send desktop notification with thumbnail in background so script returns immediately
    (
        ACTION=$(notify-send "Screenshot Captured" "Saved to $(basename "$FILE") and copied to clipboard." \
            -i "$FILE" \
            -a "Screenshot" \
            --action="open=Open Image" 2>/dev/null || true)

        if [ "$ACTION" = "open" ]; then
            xdg-open "$FILE"
        fi
    ) &
fi
