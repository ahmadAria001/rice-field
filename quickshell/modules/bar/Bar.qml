import "../../theme"
import "../controlpanel"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: barRoot

    screen: {
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === mon.name)
                    return Quickshell.screens[i];

            }
        }
        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor) {
            const wsMonName = Hyprland.focusedWorkspace.monitor.name;
            for (let j = 0; j < Quickshell.screens.length; j++) {
                if (Quickshell.screens[j].name === wsMonName)
                    return Quickshell.screens[j];

            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }
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

                ClipboardButton {
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
                        controlPanel.toggle();
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
