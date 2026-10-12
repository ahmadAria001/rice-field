#!/usr/bin/env bash
# network.sh - Manage Wi-Fi connections and scanning for Quickshell
# Usage:
#   network.sh list
#   network.sh connect <ssid> [password]
#   network.sh disconnect <ssid>
#   network.sh toggle [on|off]
#   network.sh status

set -e

ACTION="${1:-status}"
shift || true

case "$ACTION" in
    list)
        python3 -c "
import subprocess, json

def get_wifi_list():
    try:
        # Check if wifi is enabled
        res = subprocess.run(['nmcli', '-t', '-f', 'WIFI', 'g'], capture_output=True, text=True)
        if res.stdout.strip() != 'enabled':
            return []
        
        cmd = ['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list', '--rescan', 'auto']
        out = subprocess.check_output(cmd, text=True)
        networks = []
        seen = set()
        for line in out.splitlines():
            # nmcli -t escapes colons as \:
            # Let's handle escaped colons or split carefully
            # Usually: IN-USE:SSID:SIGNAL:SECURITY
            parts = line.replace('\\:', '__ESCAPED_COLON__').split(':')
            if len(parts) >= 4:
                in_use = parts[0].strip() == '*'
                ssid = parts[1].replace('__ESCAPED_COLON__', ':').strip()
                if not ssid:
                    continue
                if ssid in seen:
                    continue
                seen.add(ssid)
                sig_str = parts[2].strip()
                signal = int(sig_str) if sig_str.isdigit() else 0
                sec = parts[3].replace('__ESCAPED_COLON__', ':').strip()
                networks.append({
                    'ssid': ssid,
                    'active': in_use,
                    'signal': signal,
                    'security': sec,
                    'secured': bool(sec and sec != '--')
                })
        return sorted(networks, key=lambda x: (not x['active'], -x['signal']))
    except Exception as e:
        return []

print(json.dumps(get_wifi_list()))
"
        ;;
    connect)
        SSID="$1"
        PASSWORD="$2"
        if [ -z "$SSID" ]; then
            echo "Error: missing SSID" >&2
            exit 1
        fi
        if [ -n "$PASSWORD" ]; then
            nmcli dev wifi connect "$SSID" password "$PASSWORD"
        else
            nmcli dev wifi connect "$SSID"
        fi
        ;;
    disconnect)
        SSID="$1"
        if [ -n "$SSID" ]; then
            nmcli connection down "$SSID" || nmcli dev disconnect wlan0
        else
            nmcli dev disconnect wlan0
        fi
        ;;
    toggle)
        TARGET="$1"
        if [ -z "$TARGET" ]; then
            STATE=$(nmcli -t -f WIFI g)
            if [ "$STATE" = "enabled" ]; then
                TARGET="off"
            else
                TARGET="on"
            fi
        fi
        nmcli radio wifi "$TARGET"
        ;;
    status)
        python3 -c "
import subprocess, json

def get_status():
    try:
        g = subprocess.check_output(['nmcli', '-t', '-f', 'WIFI', 'g'], text=True).strip()
        enabled = (g == 'enabled')
        ssid = ''
        if enabled:
            out = subprocess.check_output(['nmcli', '-t', '-f', 'active,ssid', 'dev', 'wifi'], text=True)
            for line in out.splitlines():
                if line.startswith('yes:'):
                    ssid = line[4:].strip()
                    break
        return {'enabled': enabled, 'connected': bool(ssid), 'ssid': ssid or ('Disconnected' if enabled else 'Off')}
    except Exception:
        return {'enabled': False, 'connected': False, 'ssid': 'Off'}

print(json.dumps(get_status()))
"
        ;;
    *)
        echo "Unknown action: $ACTION" >&2
        exit 1
        ;;
esac
