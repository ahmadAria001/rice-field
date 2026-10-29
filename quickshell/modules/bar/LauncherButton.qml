import "../../theme"
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusSm
    color: launcherMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: launcherMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth

    Process {
        id: proc
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontXl
        color: launcherMouse.containsMouse ? Theme.mauve : "#89b4fa"
    }

    MouseArea {
        id: launcherMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const Process = proc;
            Process.exec(["qs", "ipc", "call", "launcher", "toggle"]);
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
