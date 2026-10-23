import "../../components"
import "../../theme"
import "../thermal"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// CPU temperature on the bar. The number is thermal-guard's own Tctl reading, taken
// from the Thermal singleton, so the bar shows the exact sensor the guard throttles
// on rather than a second, possibly disagreeing, read of the same file.
//
// Hovering opens a card with the load detail, pinned below the pill like the other
// bar cards: it does not follow the cursor and does not cover the pill's hit area.
Rectangle {
    id: root

    // Load detail, sampled here rather than in Thermal: that singleton is only the
    // guard's monitoring format, and this is a bar-local concern.
    property real load: 0
    property real load1: 0
    property real load5: 0
    property real load15: 0
    property int cores: 0
    property bool hovered: false

    // Previous /proc/stat totals, for the utilisation delta.
    property real prevTotal: 0
    property real prevIdle: 0

    // Comfortable, warm, and at the guard's target. Theme.red is the palette's fixed
    // danger colour; the warm step has no token, so it uses the Catppuccin yellow the
    // rice already hard-codes elsewhere.
    readonly property real warnAt: 75
    readonly property real hotAt: 85
    readonly property color tempColor: {
        if (!Thermal.ok)
            return Theme.subtext0;

        if (Thermal.tctl >= root.hotAt)
            return Theme.red;

        if (Thermal.tctl >= root.warnAt)
            return "#f9e2af";

        return Theme.text;
    }

    function ingest(line) {
        const text = line.trim();
        if (text === "")
            return ;

        // Aggregate CPU line: "cpu user nice system idle iowait irq softirq steal ..."
        if (text.indexOf("cpu") === 0) {
            const f = text.split(/\s+/);
            let total = 0;
            for (let i = 1; i < f.length && i <= 8; i++)
                total += Number(f[i]) || 0;

            const idle = (Number(f[4]) || 0) + (Number(f[5]) || 0);
            // The first sample only establishes a baseline.
            if (root.prevTotal > 0 && total > root.prevTotal) {
                const dt = total - root.prevTotal;
                const di = idle - root.prevIdle;
                root.load = Math.max(0, Math.min(1, 1 - di / dt));
            }

            root.prevTotal = total;
            root.prevIdle = idle;
            return ;
        }

        // loadavg: "2.15 3.12 4.03 4/1821 207938"
        const parts = text.split(/\s+/);
        if (parts.length >= 3 && !isNaN(parseFloat(parts[0]))) {
            root.load1 = parseFloat(parts[0]);
            root.load5 = parseFloat(parts[1]);
            root.load15 = parseFloat(parts[2]);
        }
    }

    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: pillMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth

    // One loop for both numbers, so the bar keeps a single sampler process instead of
    // a timer per metric.
    Process {
        id: sampler

        running: true
        command: ["sh", "-c", "while :; do grep '^cpu ' /proc/stat; cat /proc/loadavg; sleep 1; done"]

        stdout: SplitParser {
            onRead: (line) => root.ingest(line)
        }

    }

    // Core count, once: load average only means something per core.
    Process {
        id: coresProc

        running: true
        command: ["nproc"]

        stdout: SplitParser {
            onRead: (line) => {
                const n = parseInt(line.trim(), 10);
                if (n > 0)
                    root.cores = n;

            }
        }

    }

    RowLayout {
        id: pillLayout

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰔏"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Thermal.ok ? root.tempColor : Theme.subtext0
        }

        Text {
            text: Thermal.ok ? Math.round(Thermal.tctl) + "°C" : "—"
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: Thermal.ok ? root.tempColor : Theme.subtext0
        }

    }

    MouseArea {
        id: pillMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    // Detail card, pinned a fixed distance under the pill.
    TooltipCard {
        id: cpuCard

        anchorItem: root
        // Grows leftwards from the pill's bottom-left so it stays on screen at the
        // right end of the bar.
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        shown: root.hovered

        Item {
            implicitWidth: 210
            implicitHeight: cardColumn.implicitHeight

            ColumnLayout {
                id: cardColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                // Header: what this card is, and whether the guard is live.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰔏"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Thermal.ok ? root.tempColor : Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "CPU"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        text: Thermal.ok ? Thermal.state : "no sensor"
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                }

                // Load bar, so the number reads at a glance.
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surface0

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.load))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.mauve
                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 4

                    Text {
                        text: "Load"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Math.round(root.load * 100) + "%"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Average"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.load1.toFixed(2) + "  " + root.load5.toFixed(2) + "  " + root.load15.toFixed(2)
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Cores"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.cores > 0 ? String(root.cores) : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Temp"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Thermal.ok ? Thermal.tctl.toFixed(1) + " °C" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Thermal.ok ? root.tempColor : Theme.subtext0
                    }

                    Text {
                        text: "Guard"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        // Only meaningful once the guard reports a target.
                        text: Thermal.ok ? Thermal.target.toFixed(0) + " °C" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Ceiling"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Thermal.ok ? Thermal.ceilingGhz.toFixed(2) + " / " + Thermal.maxGhz.toFixed(2) + " GHz" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        // A reduced ceiling is the guard doing its job, so it is worth
                        // seeing at a glance.
                        color: Thermal.throttled ? Theme.red : Theme.text
                    }

                }

            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

}
