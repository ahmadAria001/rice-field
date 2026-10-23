import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Power control. The four session actions live here, behind the single Power row in
// the dashboard and behind the bar's power button, so both entry points open the
// same panel instead of each drawing its own set of buttons.
GridLayout {
    id: root

    signal requestClose()

    columns: 2
    columnSpacing: 10
    rowSpacing: 10
    Layout.fillWidth: true

    Process {
        id: proc
    }

    component Action: Rectangle {
        id: tile

        required property string glyph
        required property string label
        property bool danger: false

        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 62
        radius: Theme.radiusSm
        color: tileMouse.containsMouse ? (tile.danger ? "#312026" : Theme.surface1) : Theme.surface0
        border.color: tileMouse.containsMouse && tile.danger ? Theme.red : "transparent"
        border.width: Theme.borderWidth

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tile.glyph
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: tile.danger ? Theme.red : Theme.text
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tile.label
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                color: tileMouse.containsMouse ? Theme.text : Theme.subtext0
            }

        }

        MouseArea {
            id: tileMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.triggered()
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

    Action {
        glyph: ""
        label: "Lock"
        onTriggered: {
            // The Quickshell lock screen, not hyprlock: this rice replaced it.
            // Same call the SUPER+L bind makes, so both routes land on one lock.
            root.requestClose();
            proc.exec(["qs", "ipc", "call", "lockscreen", "lock"]);
        }
    }

    Action {
        glyph: "󰤄"
        label: "Sleep"
        onTriggered: {
            root.requestClose();
            proc.exec(["systemctl", "suspend"]);
        }
    }

    Action {
        glyph: "󰑓"
        label: "Restart"
        onTriggered: {
            root.requestClose();
            proc.exec(["systemctl", "reboot"]);
        }
    }

    Action {
        glyph: ""
        label: "Shut down"
        danger: true
        onTriggered: {
            root.requestClose();
            proc.exec(["systemctl", "poweroff"]);
        }
    }

}
