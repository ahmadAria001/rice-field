import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: root

    required property var modelData

    Layout.fillWidth: true
    implicitHeight: cardLayout.implicitHeight + 20
    radius: Theme.radiusLg
    // Same surface as GlassCard: bodyMid under a rim edge, with her gradient as the
    // top rule. Not GlassCard itself because that component owns a ColumnLayout, and
    // this card needs a full-bleed click target behind its content.
    color: Theme.bodyMid
    border.color: (root.modelData && root.modelData.urgency === NotificationUrgency.Critical) ? Theme.danger : Theme.rim
    border.width: Theme.borderWidth

    HairBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        anchors.topMargin: 1
        height: 2
        radius: 0
        opacity: 0.34
        fadeTo: "end"
    }

    // A notification is the one surface that arrives uninvited, so it resolves on
    // the same scan as a panel instead of just being there. Fired from a timer
    // rather than Component.onCompleted because the band travels `root.height`,
    // and at completion the Layout has not given this card its height yet.
    ScanReveal {
        id: scan

        anchors.fill: parent
        z: 100
    }

    Timer {
        interval: 16
        running: true
        onTriggered: scan.fire()
    }

    // Auto-dismiss Timer
    Timer {
        interval: (root.modelData && root.modelData.expireTimeout > 0) ? root.modelData.expireTimeout : 5000
        running: Boolean(root.modelData && root.modelData.urgency !== NotificationUrgency.Critical)
        onTriggered: {
            if (root.modelData)
                root.modelData.dismiss();

        }
    }

    // Click card to dismiss
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.modelData)
                root.modelData.dismiss();

        }
    }

    ColumnLayout {
        id: cardLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 6

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconImage {
                source: {
                    const icon = (root.modelData && root.modelData.appIcon) ? root.modelData.appIcon : "dialog-information";
                    return (icon.startsWith("/") || icon.startsWith("file://")) ? icon : Quickshell.iconPath(icon);
                }
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
            }

            // Monospace and tracked out: the header reads as a source line on a
            // transmission rather than as a caption under an icon.
            Text {
                text: (root.modelData && root.modelData.appName) ? root.modelData.appName : "Notification"
                color: Theme.inkFaint
                font.family: "monospace"
                font.pixelSize: Theme.fontSm
                font.letterSpacing: 1.2
                Layout.fillWidth: true
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }

            // Close button
            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: closeMouse.containsMouse ? Theme.bodyMid : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? Theme.danger : Theme.inkFaint
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.modelData)
                            root.modelData.dismiss();

                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }

                }

            }

        }

        // Summary / Title
        Text {
            text: (root.modelData && root.modelData.summary) ? root.modelData.summary : ""
            color: Theme.ink
            font.bold: true
            font.pixelSize: Theme.fontLg
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        // Body text
        Text {
            text: (root.modelData && root.modelData.body) ? root.modelData.body : ""
            color: Theme.inkDim
            font.pixelSize: Theme.fontMd
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Boolean(root.modelData && root.modelData.actions && root.modelData.actions.length > 0)

            Repeater {
                model: (root.modelData && root.modelData.actions) ? root.modelData.actions : []

                Rectangle {
                    id: actionBtn

                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Theme.radiusSm
                    color: actionMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid
                    border.color: actionMouse.containsMouse ? Theme.accent : Theme.bodyTop
                    border.width: Theme.borderWidth

                    Text {
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: Theme.ink
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
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

    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

}
