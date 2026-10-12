#!/usr/bin/env bash
set -e

ACTION="${1:-list}"
STATE_FILE="$HOME/.config/quickshell/current_wallpaper.txt"

ensure_hyprpaper() {
    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
        setsid -f hyprpaper >/dev/null 2>&1
        sleep 0.3
    fi
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
    *)
        echo "Usage: $0 [list|set <path>|get]"
        exit 1
        ;;
esac
