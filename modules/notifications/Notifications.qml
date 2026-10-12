import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: 58
    margins.right: 12
    implicitWidth: 360
    implicitHeight: notifColumn.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    NotificationServer {
        id: notifServer

        actionsSupported: true
        imageSupported: true
        bodySupported: true
        onNotification: (notification) => {
            if (!Theme.dndEnabled)
                notification.tracked = true;

        }
    }

    ColumnLayout {
        id: notifColumn

        width: parent.width
        spacing: 8

        Repeater {
            model: notifServer.trackedNotifications

            NotificationCard {
            }

        }

    }

}
