import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Minimal bottom status row: battery, network, volume. Deliberately light — icon
// plus value only, no chrome.
RowLayout {
    id: root

    property int volumeLevel: 0
    property bool muted: false
    property string netKind: "none"
    property string netName: ""

    function refresh() {
        volProc.exec(["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]);
        netProc.exec(["sh", "-c", "nmcli -t -f TYPE,NAME,STATE dev 2>/dev/null | grep ':connected$' | head -n1"]);
    }

    spacing: 22
    Component.onCompleted: refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: volProc

        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/Volume:\s+([0-9.]+)/);
                if (m)
                    root.volumeLevel = Math.round(parseFloat(m[1]) * 100);

                root.muted = line.indexOf("[MUTED]") !== -1;
            }
        }

    }

    Process {
        id: netProc

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split(":");
                root.netKind = parts[0] || "none";
                root.netName = parts[1] || "";
            }
        }

    }

    StatusItem {
        glyph: {
            if (!UPower.displayDevice || !UPower.displayDevice.isPresent)
                return "󰂑";

            const pct = Math.round(UPower.displayDevice.percentage * 100);
            if (UPower.displayDevice.state === UPowerDeviceState.Charging)
                return "󰂄";

            if (pct >= 90)
                return "󰁹";

            if (pct >= 70)
                return "󰂁";

            if (pct >= 50)
                return "󰁿";

            if (pct >= 30)
                return "󰁽";

            if (pct >= 15)
                return "󰁻";

            return "󰁺";
        }
        label: (UPower.displayDevice && UPower.displayDevice.isPresent) ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "AC"
        tint: (UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.percentage < 0.15) ? Theme.red : Theme.subtext0
    }

    StatusItem {
        glyph: root.netKind === "wifi" ? "󰤨" : (root.netKind === "ethernet" ? "󰈀" : "󰤮")
        label: root.netName !== "" ? root.netName : "offline"
    }

    StatusItem {
        glyph: root.muted ? "󰝟" : (root.volumeLevel < 34 ? "󰕿" : (root.volumeLevel < 67 ? "󰖀" : "󰕾"))
        label: root.muted ? "muted" : root.volumeLevel + "%"
        tint: root.muted ? Theme.red : Theme.subtext0
    }

    component StatusItem: RowLayout {
        id: statusItem

        required property string glyph
        required property string label
        property color tint: Theme.subtext0

        spacing: 7

        Text {
            text: statusItem.glyph
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: statusItem.tint
        }

        Text {
            text: statusItem.label
            font.family: "sans-serif"
            font.pixelSize: Theme.fontSm
            color: Theme.subtext1
        }

    }

}
