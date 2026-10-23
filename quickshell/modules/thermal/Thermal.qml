pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Read-only view of thermal-guard's monitoring output. This module only
// implements the data side of the format: no visuals, no control, so any
// consumer (bar pill, control panel, overlay) binds to the same source instead
// of re-parsing the daemon's output.
//
//     import "../modules/thermal"
//     Text { text: Math.round(Thermal.tctl) + "°C" }
//
// The producer's format is documented in thermal-guard's README. Reading it
// needs no privileges: the daemon owns the only write path to sysfs.
QtObject {
    id: root

    // install.sh installs the binary here; point it at a checkout to try changes
    // without reinstalling. Call reload() after changing it.
    property string binary: "/usr/local/bin/thermal-guard"
    // The bar does not need more than a couple of readings per second. Call
    // reload() after changing it.
    property int intervalMs: 1000
    // The stream outlives individual readings, so a restart only happens when the
    // process itself dies (binary missing, killed, replaced by an update).
    property int retryMs: 10000

    // One property per field of the payload, plus the raw object for anything
    // this module does not model yet.
    property bool ok: false
    property string state: "unavailable" // idle | ramping | floor | unavailable
    property real tctl: 0
    property real controlling: 0
    property real slope: 0
    property int ceilingKhz: 0
    property int maxKhz: 0
    property int floorKhz: 0
    property real target: 0
    property real rampStart: 0
    property bool throttled: false
    property string sensor: ""
    property double updatedAt: 0
    property var payload: null
    property string lastError: ""
    property bool pendingReload: false

    // Derived, so consumers do not repeat the arithmetic.
    readonly property real ceilingGhz: ceilingKhz / 1000000
    readonly property real maxGhz: maxKhz / 1000000
    readonly property real floorGhz: floorKhz / 1000000
    // 0 at the full frequency range, 1 when the ceiling sits on its floor.
    readonly property real throttleFraction: maxKhz > floorKhz ? (maxKhz - ceilingKhz) / (maxKhz - floorKhz) : 0
    // How close the die is to the ceiling it is being held under.
    readonly property real targetFraction: target > 0 ? Math.min(1, tctl / target) : 0

    // Re-reads binary and intervalMs: a running Process keeps the argv it
    // started with, so a change only takes effect through this.
    function reload() {
        if (stream.running) {
            pendingReload = true;
            stream.running = false;
        } else {
            stream.running = true;
        }
    }

    function ingest(line) {
        const text = line.trim();
        if (text === "")
            return;

        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            lastError = "unparseable reading";
            return;
        }

        payload = data;
        ok = data.ok === true;
        state = data.state !== undefined ? String(data.state) : "unavailable";
        tctl = Number(data.tctl_c) || 0;
        controlling = Number(data.controlling_c) || 0;
        slope = Number(data.slope_c_per_s) || 0;
        ceilingKhz = Number(data.ceiling_khz) || 0;
        maxKhz = Number(data.max_khz) || 0;
        floorKhz = Number(data.floor_khz) || 0;
        target = Number(data.target_c) || 0;
        rampStart = Number(data.ramp_start_c) || 0;
        throttled = data.throttled === true;
        sensor = data.sensor !== undefined ? String(data.sensor) : "";
        updatedAt = Number(data.ts) || 0;
        lastError = "";
    }

    property Process stream: Process {
        running: true
        command: [root.binary, "--json", "--follow", "--interval", String(root.intervalMs / 1000)]

        stdout: SplitParser {
            onRead: (line) => root.ingest(line)
        }

        stderr: SplitParser {
            onRead: (line) => {
                const text = line.trim();
                if (text !== "")
                    root.lastError = text;
            }
        }

        onExited: {
            // Stop claiming a live reading: the last payload is stale now.
            root.ok = false;
            root.state = "unavailable";
            if (root.pendingReload) {
                root.pendingReload = false;
                root.stream.running = true;
            }
        }
    }

    // Reattaches the stream. A failed exec (binary not installed yet) never emits
    // exited, so this cannot hang off onExited alone.
    property Timer reattachTimer: Timer {
        interval: root.retryMs
        running: true
        repeat: true
        onTriggered: {
            if (!root.stream.running)
                root.stream.running = true;
        }
    }

}
