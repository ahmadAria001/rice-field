import "../../theme"
import QtQuick

// The bar's single power button. It opens the control panel's power view rather than
// running its own menu, so lock, sleep, restart and shut down have one home.
Rectangle {
    id: root

    // Held true while the power view is the open one, so the button reads as the
    // active entry instead of just a hover target.
    property bool active: false

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.radiusSm
    color: root.active ? "#312026" : (powerMouse.containsMouse ? "#312026" : Theme.bodyLow)
    border.color: (root.active || powerMouse.containsMouse) ? Theme.danger : Theme.bodyMid
    border.width: Theme.borderWidth

    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontLg
        color: (root.active || powerMouse.containsMouse) ? Theme.danger : Theme.inkFaint
    }

    MouseArea {
        id: powerMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
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
