import "../../theme"
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusSm
    color: powerMouse.containsMouse ? "#312026" : Theme.mantle
    border.color: powerMouse.containsMouse ? Theme.red : Theme.surface0
    border.width: Theme.borderWidth

    Process {
        id: proc
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontLg
        color: powerMouse.containsMouse ? Theme.red : Theme.subtext0
    }

    MouseArea {
        id: powerMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const Process = proc;
            Process.exec(["wlogout"]);
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }

    }

}
