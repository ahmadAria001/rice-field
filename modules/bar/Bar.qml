import "../../theme"
import "../controlpanel"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: barRoot

    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: 8
    margins.left: 12
    margins.right: 12
    implicitHeight: 42
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: container

        anchors.fill: parent
        color: Theme.base
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusLg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            // Left: LauncherButton + Workspaces
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                LauncherButton {
                }

                Workspaces {
                }

            }

            // Center: Clock
            Clock {
            }

            // Right Module
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Tray {
                }

                StatusPill {
                    id: statusPill

                    onClicked: {
                        controlPanel.visible = !controlPanel.visible;
                    }
                }

                PowerButton {
                }

            }

        }

    }

    ControlPanel {
        id: controlPanel

        triggerItem: statusPill
    }

}
