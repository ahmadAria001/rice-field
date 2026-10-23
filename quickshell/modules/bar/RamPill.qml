import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Memory usage on the bar, with the exact amounts behind a hover card.
//
// "Used" is MemTotal - MemAvailable, not MemTotal - MemFree. MemFree counts page
// cache and reclaimable slabs as unavailable, so it reports a machine as nearly full
// while almost all of that memory is immediately reusable. MemAvailable is the
// kernel's own estimate of what a new allocation could get without swapping, which is
// the number every other system monitor shows.
Rectangle {
    id: root

    property real usedBytes: 0
    property real totalBytes: 0
    property real availableBytes: 0
    property real cachedBytes: 0
    property real buffersBytes: 0
    property real swapUsedBytes: 0
    property real swapTotalBytes: 0
    property bool hovered: false

    readonly property bool ok: root.totalBytes > 0
    // 0..1, clamped: the kernel's own figures can drift by a few kB between reads.
    readonly property real fraction: root.ok ? Math.max(0, Math.min(1, root.usedBytes / root.totalBytes)) : 0

    // The bar shows one decimal: enough to see the value move without the pill
    // changing width every second.
    function gb(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    // Warning thresholds on the used fraction, matching how the CPU pill escalates:
    // a warm step, then the palette's danger colour.
    readonly property real warnAt: 0.85
    readonly property real hotAt: 0.95
    readonly property color memColor: {
        if (!root.ok)
            return Theme.subtext0;

        if (root.fraction >= root.hotAt)
            return Theme.red;

        if (root.fraction >= root.warnAt)
            return "#f9e2af";

        return Theme.text;
    }

    // One block per tick, accumulated here and parsed when the sentinel arrives. The
    // sentinel matters because SplitParser drops the blank line that ends each block,
    // and meminfo's key order is not something to rely on.
    property var pending: ({})

    function ingest(line) {
        const text = line.trim();

        if (text === "---END---") {
            root.apply();
            root.pending = ({});
            return ;
        }

        if (text === "")
            return ;

        // "/proc/meminfo" lines are "Key:      12345 kB". Only the keys this module
        // needs are kept; the file has ~50 of them.
        const match = text.match(/^(\w+):\s+(\d+)/);
        if (match !== null)
            root.pending[match[1]] = Number(match[2]) * 1024;

    }

    // Applies one whole block at once, so no consumer ever sees a half-updated total.
    function apply() {
        const m = root.pending;

        if (m.MemTotal !== undefined)
            root.totalBytes = m.MemTotal;

        if (m.MemAvailable !== undefined)
            root.availableBytes = m.MemAvailable;

        if (m.Cached !== undefined)
            root.cachedBytes = m.Cached;

        if (m.Buffers !== undefined)
            root.buffersBytes = m.Buffers;

        if (m.SwapTotal !== undefined)
            root.swapTotalBytes = m.SwapTotal;

        if (m.SwapFree !== undefined)
            root.swapUsedBytes = Math.max(0, root.swapTotalBytes - m.SwapFree);

        // Used is derived from MemAvailable, never from MemFree: see the note at the top.
        if (root.totalBytes > 0 && root.availableBytes > 0)
            root.usedBytes = Math.max(0, root.totalBytes - root.availableBytes);

    }

    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: pillMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth

    // One sampler for the whole card: meminfo is cheap, and polling it once a second
    // matches the CPU pill's cadence so the two readouts move together.
    Process {
        id: sampler

        running: true
        command: ["sh", "-c", "while :; do cat /proc/meminfo; echo '---END---'; sleep 1; done"]

        stdout: SplitParser {
            onRead: (line) => root.ingest(line)
        }

    }

    RowLayout {
        id: pillLayout

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰍛"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: root.ok ? root.memColor : Theme.subtext0
        }

        Text {
            text: root.ok ? Math.round(root.fraction * 100) + "%" : "—"
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.ok ? root.memColor : Theme.subtext0
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
        id: ramCard

        anchorItem: root
        // Grows leftwards from the pill's bottom-left so it stays on screen at the
        // right end of the bar.
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        shown: root.hovered

        Item {
            implicitWidth: 210
            implicitHeight: ramColumn.implicitHeight

            ColumnLayout {
                id: ramColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                // Header: what this card is, and the headline used / total.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰍛"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: root.ok ? root.memColor : Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Memory"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        text: root.ok ? Math.round(root.fraction * 100) + "%" : "—"
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: root.ok ? root.memColor : Theme.subtext0
                    }

                }

                // Used fraction, so the number reads at a glance.
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surface0

                    Rectangle {
                        width: parent.width * root.fraction
                        height: parent.height
                        radius: parent.radius
                        color: root.fraction >= root.hotAt ? Theme.red : Theme.mauve
                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 4

                    Text {
                        text: "Used"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.ok ? root.gb(root.usedBytes) + " GB" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: root.ok ? root.memColor : Theme.subtext0
                    }

                    Text {
                        text: "Free"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.ok ? root.gb(root.totalBytes - root.usedBytes) + " GB" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Total"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.ok ? root.gb(root.totalBytes) + " GB" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Cached"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        // Reclaimable, and already counted as free by MemAvailable.
                        text: root.ok ? root.gb(root.cachedBytes + root.buffersBytes) + " GB" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Swap"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!root.ok)
                                return "—";

                            if (root.swapTotalBytes <= 0)
                                return "none";

                            return root.gb(root.swapUsedBytes) + " / " + root.gb(root.swapTotalBytes) + " GB";
                        }
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
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
