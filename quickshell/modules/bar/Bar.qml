import "../../components"
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

    // Arrival: the bar settles in when the shell starts, left to right, and the
    // hairline draws itself across rather than appearing whole. One value drives
    // every group, each with its own slice of it, so the order is stated once here
    // instead of as three timers that can drift apart.
    property real revealT: 0

    // A group's slice of the arrival: 0 until `start`, then eased to 1 over `span`.
    function slice(start, span) {
        return Math.max(0, Math.min(1, (revealT - start) / span));
    }

    NumberAnimation on revealT {
        from: 0
        to: 1
        duration: Math.round(620 * Theme.motionScale)
        easing.type: Theme.easeEntrance
        running: true
    }

    Rectangle {
        id: container

        anchors.fill: parent
        color: Theme.base
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusLg

        // Her hairline along the top edge of the bar. This is the one hairline
        // that is on screen the whole time: on a card the same line is 1px of
        // light you have to go looking for, and the drift is invisible because
        // the card is only open for a few seconds. On the bar it just runs.
        HairBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: parent.radius
            anchors.rightMargin: parent.radius
            anchors.topMargin: 1
            height: 2
            radius: 0
            opacity: 0.55
            fadeTo: "end"
            progress: barRoot.revealT
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            // Left: LauncherButton + Workspaces
            RowLayout {
                id: leftGroup

                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                opacity: barRoot.slice(0.00, 0.60)
                transform: Translate {
                    y: (1 - leftGroup.opacity) * 5
                }

                LauncherButton {
                }

                ClipboardButton {
                }

                Workspaces {
                }

            }

            // Center: Clock
            Clock {
                id: centerGroup

                opacity: barRoot.slice(0.12, 0.60)
                transform: Translate {
                    y: (1 - centerGroup.opacity) * 5
                }
            }

            // Right Module
            RowLayout {
                id: rightGroup

                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                opacity: barRoot.slice(0.24, 0.60)
                transform: Translate {
                    y: (1 - rightGroup.opacity) * 5
                }

                CpuTempPill {
                }

                RamPill {
                }

                GpuPill {
                }

                BluetoothBatteryPill {
                }

                UsagePill {
                }

                Tray {
                }

                StatusPill {
                    id: statusPill

                    onClicked: {
                        controlPanel.toggle();
                    }
                }

                PowerButton {
                    active: controlPanel.shown && controlPanel.currentView === "power"
                    onClicked: controlPanel.togglePower()
                }

            }

        }

    }

    ControlPanel {
        id: controlPanel

        triggerItem: statusPill
    }

}
