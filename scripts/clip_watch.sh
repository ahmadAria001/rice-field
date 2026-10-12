#!/usr/bin/env sh
# Continuous clipboard watcher outputting single-line JSON per clipboard change
exec wl-paste --watch python3 -c '
import sys, json
try:
    text = sys.stdin.read()
    if text:
        sys.stdout.write(json.dumps(text) + "\n")
        sys.stdout.flush()
except Exception:
    pass
'
