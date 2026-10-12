import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var modelData
    required property int index
    property bool isCurrent: false

    signal launched()

    function launch() {
        if (modelData)
            modelData.execute();

        launched();
    }

    width: ListView.view ? ListView.view.width : 0
    implicitHeight: 52
    radius: Theme.radiusSm
    color: isCurrent ? Theme.surface1 : (itemMouse.containsMouse ? Theme.surface0 : "transparent")

    MouseArea {
        id: itemMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.launch()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        IconImage {
            source: Quickshell.iconPath((root.modelData && root.modelData.icon) ? root.modelData.icon : "application-x-executable")
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: (root.modelData && root.modelData.name) ? root.modelData.name : ""
                color: Theme.text
                font.pixelSize: Theme.fontXl
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.modelData ? (root.modelData.comment || root.modelData.genericName || "") : ""
                color: Theme.subtext1
                font.pixelSize: Theme.fontSm
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: 100
        }

    }

}
