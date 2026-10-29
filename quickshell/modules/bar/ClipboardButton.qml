import "../../components"
import "../../theme"
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusSm
    color: clipMouse.containsMouse ? Theme.bodyMid : Theme.bodyLow
    border.color: clipMouse.containsMouse ? Theme.accent : Theme.bodyMid
    border.width: Theme.borderWidth

    Process {
        id: proc
    }

    Text {
        anchors.centerIn: parent
        text: "󰅌"
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontLg
        color: clipMouse.containsMouse ? Theme.accent : Theme.inkFaint
    }

    MouseArea {
        id: clipMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            proc.exec(["qs", "ipc", "call", "clipboard", "toggle"]);
        }
    }

    TooltipCard {
        anchorItem: root
        shown: clipMouse.containsMouse
        text: "Clipboard History"
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
