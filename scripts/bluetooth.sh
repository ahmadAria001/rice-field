#!/usr/bin/env bash
# bluetooth.sh - Manage Bluetooth devices and connections for Quickshell
# Usage:
#   bluetooth.sh list
#   bluetooth.sh connect <mac>
#   bluetooth.sh disconnect <mac>
#   bluetooth.sh toggle [on|off]
#   bluetooth.sh status

set -e

ACTION="${1:-status}"
shift || true

case "$ACTION" in
    list)
        python3 -c "
import subprocess, json

def get_devices():
    try:
        # Check power
        show_out = subprocess.check_output(['bluetoothctl', 'show'], text=True)
        powered = 'Powered: yes' in show_out
        if not powered:
            return []

        out = subprocess.check_output(['bluetoothctl', 'devices'], text=True)
        connected_out = subprocess.check_output(['bluetoothctl', 'devices', 'Connected'], text=True)
        paired_out = subprocess.check_output(['bluetoothctl', 'devices', 'Paired'], text=True)

        connected_macs = set()
        for l in connected_out.splitlines():
            p = l.split()
            if len(p) >= 2 and p[0] == 'Device':
                connected_macs.add(p[1])

        paired_macs = set()
        for l in paired_out.splitlines():
            p = l.split()
            if len(p) >= 2 and p[0] == 'Device':
                paired_macs.add(p[1])

        devices = []
        for l in out.splitlines():
            p = l.split(' ', 2)
            if len(p) >= 3 and p[0] == 'Device':
                mac = p[1]
                name = p[2]
                devices.append({
                    'mac': mac,
                    'name': name,
                    'connected': mac in connected_macs,
                    'paired': mac in paired_macs
                })
        return sorted(devices, key=lambda d: (not d['connected'], not d['paired'], d['name']))
    except Exception:
        return []

print(json.dumps(get_devices()))
"
        ;;
    connect)
        MAC="$1"
        if [ -z "$MAC" ]; then
            echo "Error: missing MAC address" >&2
            exit 1
        fi
        bluetoothctl connect "$MAC"
        ;;
    disconnect)
        MAC="$1"
        if [ -z "$MAC" ]; then
            echo "Error: missing MAC address" >&2
            exit 1
        fi
        bluetoothctl disconnect "$MAC"
        ;;
    toggle)
        TARGET="$1"
        if [ -z "$TARGET" ]; then
            show_out=$(bluetoothctl show 2>/dev/null || true)
            if echo "$show_out" | grep -q 'Powered: yes'; then
                TARGET="off"
            else
                TARGET="on"
            fi
        fi
        bluetoothctl power "$TARGET"
        ;;
    status)
        python3 -c "
import subprocess, json

def get_status():
    try:
        show_out = subprocess.check_output(['bluetoothctl', 'show'], text=True)
        powered = 'Powered: yes' in show_out
        dev_name = ''
        if powered:
            c = subprocess.check_output(['bluetoothctl', 'devices', 'Connected'], text=True)
            for l in c.splitlines():
                p = l.split(' ', 2)
                if len(p) >= 3 and p[0] == 'Device':
                    dev_name = p[2]
                    break
        return {
            'enabled': powered,
            'connected': bool(dev_name),
            'device': dev_name or ('On' if powered else 'Off')
        }
    except Exception:
        return {'enabled': False, 'connected': False, 'device': 'Off'}

print(json.dumps(get_status()))
"
        ;;
    *)
        echo "Unknown action: $ACTION" >&2
        exit 1
        ;;
esac
