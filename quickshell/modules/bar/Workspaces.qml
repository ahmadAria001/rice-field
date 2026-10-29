import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    spacing: 4
    Layout.alignment: Qt.AlignVCenter

    Repeater {
        model: 5

        Rectangle {
            id: wsButton

            readonly property int wsId: index + 1
            readonly property bool isActive: Boolean(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)

            implicitWidth: isActive ? 28 : 24
            implicitHeight: 24
            radius: Theme.radiusSm
            color: isActive ? Theme.mauve : (wsMouse.containsMouse ? Theme.surface0 : "transparent")
            border.color: isActive ? Theme.mauve : (wsMouse.containsMouse ? Theme.surface1 : "transparent")
            border.width: Theme.borderWidth

            Text {
                anchors.centerIn: parent
                text: wsId.toString()
                font.pixelSize: Theme.fontMd
                font.bold: isActive
                color: isActive ? "#11111b" : (wsMouse.containsMouse ? Theme.text : Theme.subtext0)
            }

            MouseArea {
                id: wsMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
                }
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Theme.easeGeneral
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

    }

}
