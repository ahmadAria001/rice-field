import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root

    property int volumeLevel: 50
    property bool isMuted: false
    property string netIcon: "󰤨"

    signal clicked()

    function refreshStatus() {
        volProc.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
        netProc.exec(["sh", "-c", "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep ':connected$' | cut -d: -f1 | head -n1"]);
    }

    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: pillMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth
    Component.onCompleted: {
        refreshStatus();
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: {
            root.refreshStatus();
        }
    }

    Process {
        id: volProc

        stdout: SplitParser {
            onRead: (data) => {
                var text = data.trim();
                var match = text.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    root.volumeLevel = Math.round(parseFloat(match[1]) * 100);
                    root.isMuted = text.indexOf("[MUTED]") !== -1;
                }
            }
        }

    }

    Process {
        id: netProc

        stdout: SplitParser {
            onRead: (data) => {
                var type = data.trim();
                if (type === "ethernet")
                    root.netIcon = "󰈀";
                else if (type === "wifi")
                    root.netIcon = "󰤨";
                else
                    root.netIcon = "󰤮";
            }
        }

    }

    RowLayout {
        id: pillLayout

        anchors.centerIn: parent
        spacing: 8

        // Network Icon
        Text {
            text: root.netIcon
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.text
        }

        // Volume Icon
        Text {
            text: root.isMuted ? "󰝟" : (root.volumeLevel < 33 ? "󰕿" : (root.volumeLevel < 66 ? "󰖀" : "󰕾"))
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: root.isMuted ? Theme.red : Theme.text
        }

        // Battery Icon & Percent (if present)
        RowLayout {
            spacing: 4
            visible: UPower.displayDevice && UPower.displayDevice.isPresent

            Text {
                text: {
                    var pct = UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 100;
                    var isCharging = UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging;
                    if (isCharging)
                        return "󰂄";

                    if (pct >= 90)
                        return "󰁹";

                    if (pct >= 80)
                        return "󰂂";

                    if (pct >= 70)
                        return "󰂁";

                    if (pct >= 60)
                        return "󰂀";

                    if (pct >= 50)
                        return "󰁿";

                    if (pct >= 40)
                        return "󰁾";

                    if (pct >= 30)
                        return "󰁽";

                    if (pct >= 20)
                        return "󰁼";

                    return "󰁺";
                }
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: (UPower.displayDevice && UPower.displayDevice.percentage < 0.2) ? Theme.red : Theme.text
            }

            Text {
                text: (UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 0) + "%"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                color: Theme.text
            }

        }

    }

    MouseArea {
        id: pillMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
        }
    }

    TooltipCard {
        anchorItem: root
        shown: pillMouse.containsMouse
        text: "Quick Settings"
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
