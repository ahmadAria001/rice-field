import "../../theme"
import QtQuick
import QtQuick.Layouts

// The dashboard's single power entry. The four session buttons that used to sit here
// now live in the power view (PowerOptions.qml), which the bar's power button opens
// too, so there is one set of actions and two ways in.
Rectangle {
    id: root

    signal openPower()

    Layout.fillWidth: true
    implicitHeight: 40
    radius: Theme.radiusSm
    color: rowMouse.containsMouse ? Theme.surface1 : Theme.surface0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        Text {
            text: ""
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontLg
            color: rowMouse.containsMouse ? Theme.red : Theme.subtext0
        }

        Text {
            Layout.fillWidth: true
            text: "Power"
            font.family: "sans-serif"
            font.pixelSize: Theme.fontMd
            font.bold: true
            color: Theme.text
        }

        Text {
            text: "󰁔"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.subtext0
        }

    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openPower()
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

}
