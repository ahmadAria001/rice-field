import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets

PopupWindow {
    id: root

    // DBus menu model from the tray item
    required property var menuSource
    // Visual item to anchor beneath
    required property Item targetItem

    anchor.item: targetItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 6
    color: "transparent"
    implicitWidth: menuBox.implicitWidth
    implicitHeight: menuBox.implicitHeight
    visible: false

    // Dismiss when clicking anywhere outside the popup
    HyprlandFocusGrab {
        id: focusGrab

        active: root.backingWindowVisible
        windows: [root]
        onCleared: root.visible = false
    }

    // Dismiss when pressing Escape
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.visible = false
    }

    // Dismiss on workspace or active window change
    Connections {
        function onFocusedWorkspaceChanged() {
            if (root.visible)
                root.visible = false;

        }

        function onActiveToplevelChanged() {
            if (root.visible)
                root.visible = false;

        }

        target: Hyprland
    }

    // Resolves DBus menu into an ObjectModel of QsMenuEntry items
    QsMenuOpener {
        id: opener

        menu: root.menuSource
    }

    Rectangle {
        id: menuBox

        color: Theme.bodyLow
        border.color: Theme.bodyMid
        border.width: Theme.borderWidth
        radius: Theme.radiusSm
        implicitWidth: Math.max(180, menuColumn.implicitWidth + 16)
        implicitHeight: menuColumn.implicitHeight + 12

        ColumnLayout {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: opener.children

                delegate: Rectangle {
                    id: entryRow

                    required property var modelData

                    visible: modelData.visible !== false
                    Layout.fillWidth: true
                    implicitHeight: modelData.isSeparator ? 1 : 28
                    radius: Theme.radiusSm
                    color: modelData.isSeparator ? Theme.bodyMid : (itemHover.containsMouse && modelData.enabled ? Theme.bodyMid : "transparent")

                    // Non-clickable separator spacer
                    Item {
                        anchors.fill: parent
                        visible: entryRow.modelData.isSeparator
                    }

                    // Standard item layout
                    RowLayout {
                        id: rowLayout

                        visible: !entryRow.modelData.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        // Checkable indicator
                        Text {
                            visible: entryRow.modelData.buttonType !== undefined && entryRow.modelData.buttonType !== 0
                            text: entryRow.modelData.checkState === Qt.Checked ? "󰄵" : "󰄱"
                            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                            font.pixelSize: Theme.fontSm
                            color: entryRow.modelData.checkState === Qt.Checked ? Theme.accent : Theme.inkFaint
                        }

                        IconImage {
                            visible: entryRow.modelData.icon !== ""
                            source: entryRow.modelData.icon
                            implicitWidth: 16
                            implicitHeight: 16
                        }

                        Text {
                            // Strip mnemonic accelerator ampersands (e.g. "&Quit" -> "Quit")
                            text: entryRow.modelData.text ? entryRow.modelData.text.replace(/&/g, "") : ""
                            color: entryRow.modelData.enabled ? Theme.ink : Theme.inkFaint
                            font.family: "sans-serif"
                            font.pixelSize: Theme.fontSm
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: entryRow.modelData.hasChildren
                            text: "›"
                            color: Theme.inkFaint
                            font.pixelSize: Theme.fontMd
                        }

                    }

                    MouseArea {
                        id: itemHover

                        visible: !entryRow.modelData.isSeparator && entryRow.modelData.enabled
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            entryRow.modelData.triggered();
                            root.visible = false;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }

                    }

                }

            }

        }

    }

}
