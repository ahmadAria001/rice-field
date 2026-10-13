import "../../theme"
import QtQuick
import QtQuick.Layouts

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

    Text {
        anchors.centerIn: parent
        text: root.formattedTime
        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
        font.pixelSize: Theme.fontLg
        font.bold: true
        color: Theme.text
    }

}
