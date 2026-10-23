#!/bin/sh
# GPU sampling for the bar's GPU pill.
#
# Emits one line per sample on stdout:
#
#   suspended
#       The dGPU is in PCI runtime suspend. Nothing is queried, because reading
#       nvidia-smi brings the GPU back to D0 and holds it there, which is exactly the
#       state a laptop idles in to save power.
#
#   active|util|mem_used|mem_total|temp|power|power_limit|clk|clk_max|pstate
#       util %; VRAM used/total in MiB; temperature in C; power draw and enforced
#       limit in W; current and max graphics clock in MHz; P-state.
#       Fields the driver does not expose are emitted empty rather than "N/A".
#
#   error|<reason>
#       nvidia-smi is missing or failed. The bar shows a dash instead of stale data.
#
# Usage: gpu.sh [--once] [interval_seconds]
#   --once   emit a single sample and exit (handy for testing).
#   default  loop forever, one sample per interval (default 2 s).
#
# Reading the PCI runtime status is a plain sysfs read and does not wake the GPU, so
# the loop can stay cheap while the card sleeps.

set -u

ONCE=0
INTERVAL=2

for arg in "$@"; do
    case "$arg" in
        --once) ONCE=1 ;;
        ''|*[!0-9]*) ;;
        *) INTERVAL="$arg" ;;
    esac
done

# Locate the NVIDIA PCI device by driver rather than by a hard-coded address, so the
# script survives a slot change or a different machine.
# SYSFS_ROOT exists so the suspended/error branches can be tested against a fake tree;
# production never sets it.
SYSFS="${SYSFS_ROOT:-}"

find_nvidia_pci() {
    for d in "$SYSFS"/sys/bus/pci/devices/*; do
        drv=$(basename "$(readlink -f "$d/driver" 2>/dev/null)" 2>/dev/null)
        if [ "$drv" = "nvidia" ]; then
            printf '%s\n' "$d"
            return 0
        fi
    done
    return 1
}

PCI=$(find_nvidia_pci || true)
STATUS_FILE=""
if [ -n "$PCI" ]; then
    STATUS_FILE="$PCI/power/runtime_status"
fi

# "[N/A]" is what nvidia-smi prints for a field the driver does not expose. Turning it
# into an empty field keeps the column count stable for the reader.
clean() {
    case "$1" in
        '[N/A]'|'N/A') printf '' ;;
        *) printf '%s' "$1" ;;
    esac
}

sample() {
    if [ -z "$STATUS_FILE" ] || [ ! -r "$STATUS_FILE" ]; then
        printf 'error|no nvidia pci device\n'
        return 0
    fi

    if [ "$(cat "$STATUS_FILE" 2>/dev/null)" = "suspended" ]; then
        printf 'suspended\n'
        return 0
    fi

    if ! command -v nvidia-smi >/dev/null 2>&1; then
        printf 'error|nvidia-smi not found\n'
        return 0
    fi

    raw=$(nvidia-smi \
        --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,enforced.power.limit,clocks.current.graphics,clocks.max.graphics,pstate \
        --format=csv,noheader,nounits 2>/dev/null)

    if [ -z "$raw" ]; then
        printf 'error|nvidia-smi returned nothing\n'
        return 0
    fi

    # Strip spaces around the CSV fields.
    util=$(clean "$(printf '%s' "$raw" | cut -d, -f1 | tr -d ' ')")
    mem_used=$(clean "$(printf '%s' "$raw" | cut -d, -f2 | tr -d ' ')")
    mem_total=$(clean "$(printf '%s' "$raw" | cut -d, -f3 | tr -d ' ')")
    temp=$(clean "$(printf '%s' "$raw" | cut -d, -f4 | tr -d ' ')")
    power=$(clean "$(printf '%s' "$raw" | cut -d, -f5 | tr -d ' ')")
    plimit=$(clean "$(printf '%s' "$raw" | cut -d, -f6 | tr -d ' ')")
    clk=$(clean "$(printf '%s' "$raw" | cut -d, -f7 | tr -d ' ')")
    clk_max=$(clean "$(printf '%s' "$raw" | cut -d, -f8 | tr -d ' ')")
    pstate=$(clean "$(printf '%s' "$raw" | cut -d, -f9 | tr -d ' ')")

    printf 'active|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
        "$util" "$mem_used" "$mem_total" "$temp" "$power" "$plimit" "$clk" "$clk_max" "$pstate"
}

if [ "$ONCE" = "1" ]; then
    sample
    exit 0
fi

while :; do
    sample
    sleep "$INTERVAL"
done
