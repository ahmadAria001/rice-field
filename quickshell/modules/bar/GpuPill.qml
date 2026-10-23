import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// NVIDIA GPU on the bar: utilisation in the pill, the full picture on hover.
//
// Sampling lives in scripts/gpu.sh rather than inline because the dGPU is in PCI
// runtime suspend on this laptop and any nvidia-smi call wakes it to D0. The script
// checks the sysfs runtime status first and skips the query entirely while the card
// sleeps, so an idle bar costs nothing and the card stays suspended. A QML Process
// running nvidia-smi on a timer would defeat that.
//
// A suspended card is not an error: the pill dims and shows a dash, and the card
// explains that it is asleep.
Rectangle {
    id: root

    property bool active: false
    property bool suspended: false
    property string errorText: ""

    property real util: 0
    property real memUsed: 0
    property real memTotal: 0
    property real temp: 0
    property real power: 0
    property real powerLimit: 0
    property real clk: 0
    property real clkMax: 0
    property string pstate: ""

    property bool hovered: false

    readonly property bool ok: root.active && root.memTotal > 0
    readonly property real memFraction: root.memTotal > 0 ? Math.max(0, Math.min(1, root.memUsed / root.memTotal)) : 0

    // Utilisation is the headline, so it drives the colour. The thresholds mirror the
    // CPU and RAM pills: a warm step, then the palette's danger colour.
    readonly property real warnAt: 0.75
    readonly property real hotAt: 0.9
    readonly property color gpuColor: {
        if (!root.ok)
            return Theme.subtext0;

        if (root.util / 100 >= root.hotAt)
            return Theme.red;

        if (root.util / 100 >= root.warnAt)
            return "#f9e2af";

        return Theme.text;
    }

    function ingest(line) {
        const text = line.trim();
        if (text === "")
            return ;

        // "suspended" carries no fields; the rest are pipe-separated.
        const f = text.split("|");

        if (f[0] === "suspended") {
            root.suspended = true;
            root.active = false;
            root.errorText = "";
            return ;
        }

        if (f[0] === "error") {
            root.suspended = false;
            root.active = false;
            root.errorText = f[1] || "unavailable";
            return ;
        }

        if (f[0] !== "active" || f.length < 10)
            return ;

        // Number("") is 0, so a field the driver does not expose reads as 0 and the
        // consumer can test it for "unknown" instead of parsing a sentinel.
        root.suspended = false;
        root.active = true;
        root.errorText = "";
        root.util = Number(f[1]) || 0;
        root.memUsed = Number(f[2]) || 0;
        root.memTotal = Number(f[3]) || 0;
        root.temp = Number(f[4]) || 0;
        root.power = Number(f[5]) || 0;
        root.powerLimit = Number(f[6]) || 0;
        root.clk = Number(f[7]) || 0;
        root.clkMax = Number(f[8]) || 0;
        root.pstate = f[9] || "";
    }

    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: pillMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth

    Process {
        id: sampler

        running: true
        // Two seconds is plenty for a GPU readout, and halves the wake-ups a 1 s loop
        // would cause while the card is active.
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/gpu.sh", "2"]

        stdout: SplitParser {
            onRead: (line) => root.ingest(line)
        }

    }

    RowLayout {
        id: pillLayout

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰢮"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: root.ok ? root.gpuColor : Theme.subtext0
        }

        Text {
            text: root.ok ? Math.round(root.util) + "%" : "—"
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.ok ? root.gpuColor : Theme.subtext0
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

    TooltipCard {
        id: gpuCard

        anchorItem: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        shown: root.hovered

        Item {
            implicitWidth: 210
            implicitHeight: gpuColumn.implicitHeight

            ColumnLayout {
                id: gpuColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰢮"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: root.ok ? root.gpuColor : Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "GPU"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: Theme.text
                    }

                    Text {
                        // P-state is the clearest "is it working" signal, so it sits in
                        // the header next to the utilisation.
                        text: root.ok ? root.pstate : (root.suspended ? "asleep" : "—")
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surface0

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.util / 100))
                        height: parent.height
                        radius: parent.radius
                        color: root.util / 100 >= root.hotAt ? Theme.red : Theme.mauve
                    }

                }

                // Explains the dash, so a sleeping card does not look like a broken
                // module.
                Text {
                    Layout.fillWidth: true
                    visible: !root.ok
                    text: {
                        if (root.errorText !== "")
                            return root.errorText;

                        if (root.suspended)
                            return "Runtime suspended";

                        return "Waiting for a sample";
                    }
                    wrapMode: Text.WordWrap
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: root.ok
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
                        text: root.ok ? Math.round(root.util) + "%" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: root.ok ? root.gpuColor : Theme.subtext0
                    }

                    Text {
                        text: "VRAM"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.ok ? Math.round(root.memUsed) + " / " + Math.round(root.memTotal) + " MiB" : "—"
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
                        text: root.ok && root.temp > 0 ? Math.round(root.temp) + " °C" : "—"
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Power"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        // The driver exposes the enforced limit but not power.limit on
                        // this laptop, so the limit may legitimately be empty.
                        text: {
                            if (!root.ok || root.power <= 0)
                                return "—";

                            if (root.powerLimit > 0)
                                return root.power.toFixed(1) + " / " + Math.round(root.powerLimit) + " W";

                            return root.power.toFixed(1) + " W";
                        }
                        horizontalAlignment: Text.AlignRight
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.text
                    }

                    Text {
                        text: "Clock"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.subtext0
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.ok && root.clk > 0 ? Math.round(root.clk) + " / " + Math.round(root.clkMax) + " MHz" : "—"
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
