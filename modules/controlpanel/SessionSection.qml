import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root

    spacing: 12
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    Process {
        id: proc
    }

    // Lock
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.radiusSm
        color: lockMouse.containsMouse ? Theme.surface1 : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.text
        }

        MouseArea {
            id: lockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                proc.exec(["sh", "-c", "command -v hyprlock >/dev/null && hyprlock || loginctl lock-session"]);
            }
            ToolTip.visible: lockMouse.containsMouse
            ToolTip.text: "Lock Screen"
            ToolTip.delay: 300
        }

    }

    // Suspend
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.radiusSm
        color: suspMouse.containsMouse ? Theme.surface1 : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: "󰤄"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.text
        }

        MouseArea {
            id: suspMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                proc.exec(["systemctl", "suspend"]);
            }
            ToolTip.visible: suspMouse.containsMouse
            ToolTip.text: "Suspend"
            ToolTip.delay: 300
        }

    }

    // Reboot
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.radiusSm
        color: rebootMouse.containsMouse ? Theme.surface1 : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: "󰑓"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.text
        }

        MouseArea {
            id: rebootMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                proc.exec(["systemctl", "reboot"]);
            }
            ToolTip.visible: rebootMouse.containsMouse
            ToolTip.text: "Restart"
            ToolTip.delay: 300
        }

    }

    // Power Off
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.radiusSm
        color: powerMouse.containsMouse ? Theme.red : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: powerMouse.containsMouse ? Theme.mantle : Theme.red
        }

        MouseArea {
            id: powerMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                proc.exec(["systemctl", "poweroff"]);
            }
            ToolTip.visible: powerMouse.containsMouse
            ToolTip.text: "Power Off"
            ToolTip.delay: 300
        }

    }

}
