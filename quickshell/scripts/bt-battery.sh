#!/bin/sh
# Prints the battery level of every connected Bluetooth peripheral that reports one,
# as a single JSON array on one line. An empty array means "nothing to show", which is
# also what a laptop with no earbuds connected produces.
#
#   [{"name":"MOONDROP MOCA","percent":90,"path":"/org/bluez/hci0/dev_41_..."}]
#
# Source: UPower. It tracks org.bluez.Battery1 and publishes each peripheral as a
# UPower device whose NativePath is the BlueZ object path. BlueZ only exposes Battery1
# on devices that support it, so a peripheral without a battery never appears here.
#
# The Connected check is explicit even though UPower normally drops disconnected
# devices: "only connected" is a requirement, not a side effect to rely on.
#
# No jq dependency: the payload is built with printf, and names are escaped for the
# characters that realistically appear in a device alias.

set -u

UPOWER_DEST=org.freedesktop.UPower
DEVICES_ROOT=/org/freedesktop/UPower/devices

# Escapes backslash and double quote, and drops control characters, so a device name
# cannot break the JSON.
json_escape() {
    printf '%s' "$1" | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Reads one UPower property, printing an empty string when it is unavailable.
# The interface and property are separate arguments: busctl rejects the combined
# "interface.Property" form for some names (NativePath among them) with
# "Too few arguments".
prop() {
    busctl --system get-property "$UPOWER_DEST" "$1" org.freedesktop.UPower.Device "$2" 2>/dev/null |
        sed -e 's/^[a-z] //' -e 's/^"//' -e 's/"$//'
}

# Is the BlueZ object path still connected? Anything that is not a clear "true" is
# treated as disconnected, so a missing BlueZ object hides the device.
bluez_connected() {
    case "$1" in
        /org/bluez/*) ;;
        *) return 1 ;;
    esac

    val=$(busctl --system get-property org.bluez "$1" org.bluez.Device1 Connected 2>/dev/null | awk '{print $2}')
    [ "$val" = "true" ]
}

out=""
count=0

for path in $(busctl --system tree "$UPOWER_DEST" 2>/dev/null | grep -oE "$DEVICES_ROOT/[A-Za-z0-9_]+"); do
    # Skip the aggregate display and line-power pseudo-devices.
    case "$path" in
        */DisplayDevice|*/line_power_*|*/battery_BAT*|*/battery_CMB*) continue ;;
    esac

    native=$(prop "$path" NativePath)
    [ -n "$native" ] || continue
    bluez_connected "$native" || continue

    percent=$(prop "$path" Percentage)
    [ -n "$percent" ] || continue

    model=$(prop "$path" Model)
    [ -n "$model" ] || model=$(prop "$path" Description)
    [ -n "$model" ] || model="Bluetooth device"

    # UPower reports percentage as a float; round for display.
    percent=$(printf '%.0f' "$percent" 2>/dev/null || printf '%s' "$percent")

    if [ "$count" -gt 0 ]; then
        out="$out,"
    fi
    out="$out{\"name\":\"$(json_escape "$model")\",\"percent\":$percent,\"path\":\"$(json_escape "$native")\"}"
    count=$((count + 1))
done

printf '[%s]\n' "$out"
