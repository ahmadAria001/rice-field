import "../../theme"
import QtQuick
import QtQuick.Layouts

// The bar clock. Also the entry point to the calendar / now-playing card, so the
// middle of the bar is not the one place with nothing to click.
Item {
    id: root

    property string formattedTime: Qt.formatDateTime(new Date(), "hh:mm:ss  •  ddd, d MMM")

    Layout.fillWidth: true
    Layout.fillHeight: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.formattedTime = Qt.formatDateTime(new Date(), "hh:mm:ss  •  ddd, d MMM");
        }
    }

    // Hover affordance: without it the clock reads as decoration, not a target.
    Rectangle {
        anchors.centerIn: parent
        width: clockText.implicitWidth + 20
        height: 26
        radius: Theme.radiusSm
        color: Theme.surface0
        opacity: (clockHit.containsMouse || panel.shown) ? 0.55 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Theme.easeGeneral
            }

        }

    }

    Text {
        id: clockText

        anchors.centerIn: parent
        text: root.formattedTime
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontLg
        font.bold: true
        color: Theme.text
    }

    MouseArea {
        id: clockHit

        // Only the text is a target. The item fills the bar's whole centre, and a
        // MouseArea that wide would swallow clicks meant for empty bar space.
        anchors.centerIn: parent
        width: clockText.implicitWidth + 24
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    ClockPanel {
        id: panel

        anchorItem: clockHit
    }

}