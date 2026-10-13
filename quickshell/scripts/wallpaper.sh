#!/usr/bin/env bash
set -e

ACTION="${1:-list}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
STATE_FILE="$STATE_DIR/current_wallpaper.txt"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Migrate old state file if it exists and new one does not
if [ ! -f "$STATE_FILE" ]; then
    if [ -f "$HOME/.config/quickshell/current_wallpaper.txt" ]; then
        cp "$HOME/.config/quickshell/current_wallpaper.txt" "$STATE_FILE"
    elif [ -f "$HOME/Codes/rice-field/quickshell/current_wallpaper.txt" ]; then
        cp "$HOME/Codes/rice-field/quickshell/current_wallpaper.txt" "$STATE_FILE"
    fi
fi

ensure_hyprpaper() {
    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
        setsid -f hyprpaper >/dev/null 2>&1
    fi
}

wait_for_hyprpaper() {
    ensure_hyprpaper
    local count=0
    # Bounded retry: up to ~5 seconds (50 * 0.1s)
    while [ $count -lt 50 ]; do
        if hyprctl hyprpaper listactive >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
        count=$((count + 1))
    done
    return 1
}

case "$ACTION" in
    list)
        python3 -c '
import os, json, hashlib
from PIL import Image
Image.MAX_IMAGE_PIXELS = None

dirs = [os.path.expanduser("~/Pictures/Wallpapers"), os.path.expanduser("~/Pictures/wallpapers")]
thumb_dir = os.path.expanduser("~/.config/quickshell/.thumbnails")
os.makedirs(thumb_dir, exist_ok=True)
exts = (".jpg", ".jpeg", ".png", ".webp")
files = []
seen = set()

for d in dirs:
    if os.path.isdir(d):
        for f in sorted(os.listdir(d)):
            if f.lower().endswith(exts):
                full_path = os.path.join(d, f)
                if full_path not in seen:
                    seen.add(full_path)
                    h = hashlib.md5(full_path.encode()).hexdigest()
                    thumb_path = os.path.join(thumb_dir, f"{h}.jpg")
                    if not os.path.exists(thumb_path):
                        try:
                            with Image.open(full_path) as img:
                                img.thumbnail((320, 200))
                                img.convert("RGB").save(thumb_path, "JPEG", quality=80)
                        except Exception:
                            thumb_path = full_path
                    files.append({
                        "name": f,
                        "path": full_path,
                        "thumb": thumb_path
                    })

print(json.dumps(files))
'
        ;;
    set)
        IMAGE="$2"
        if [ -n "$IMAGE" ] && [ -f "$IMAGE" ]; then
            ensure_hyprpaper
            hyprctl hyprpaper wallpaper ",$IMAGE" >/dev/null 2>&1 || true
            echo "$IMAGE" > "$STATE_FILE"
            echo "OK"
        else
            echo "Error: file not found" >&2
            exit 1
        fi
        ;;
    get)
        ensure_hyprpaper
        ACTIVE=$(hyprctl hyprpaper listactive 2>/dev/null | head -n1 | awk -F': ' '{print $2}')
        if [ -n "$ACTIVE" ] && [ -f "$ACTIVE" ]; then
            echo "$ACTIVE"
        elif [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        fi
        ;;
    restore)
        if [ ! -f "$STATE_FILE" ]; then
            exit 0
        fi
        SAVED_IMG=$(head -n 1 "$STATE_FILE" | tr -d '\r\n')
        if [ -z "$SAVED_IMG" ] || [ ! -f "$SAVED_IMG" ]; then
            exit 0
        fi
        if wait_for_hyprpaper; then
            hyprctl hyprpaper wallpaper ",$SAVED_IMG" >/dev/null 2>&1 || true
            echo "Restored: $SAVED_IMG"
        else
            echo "Warning: hyprpaper did not become ready within 5s" >&2
            exit 0
        fi
        ;;
    *)
        echo "Usage: $0 [list|set <path>|get|restore]"
        exit 1
        ;;
esac
