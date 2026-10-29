import "../../components"
import "../../components/tray"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: root

    property var activeMenu: null

    spacing: 6
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: delegate

            required property var modelData

            width: 28
            height: 28
            implicitWidth: 28
            implicitHeight: 28
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Theme.radiusSm
            color: hoverArea.containsMouse ? Theme.bodyMid : "transparent"

            TrayMenu {
                id: popupMenu

                targetItem: delegate
                menuSource: delegate.modelData.menu
                onVisibleChanged: {
                    if (visible) {
                        if (root.activeMenu && root.activeMenu !== popupMenu)
                            root.activeMenu.visible = false;

                        root.activeMenu = popupMenu;
                    } else if (root.activeMenu === popupMenu) {
                        root.activeMenu = null;
                    }
                }
            }

            TooltipCard {
                anchorItem: delegate
                text: delegate.modelData.tooltipTitle || delegate.modelData.title || ""
                shown: hoverArea.containsMouse && text !== ""
            }

            IconImage {
                anchors.centerIn: parent
                source: modelData.icon
                width: 18
                height: 18
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            MouseArea {
                id: hoverArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                        if (modelData.hasMenu && modelData.menu) {
                            if (root.activeMenu && root.activeMenu !== popupMenu)
                                root.activeMenu.visible = false;

                            popupMenu.visible = !popupMenu.visible;
                        } else {
                            if (root.activeMenu)
                                root.activeMenu.visible = false;

                            var win = (typeof barRoot !== "undefined" && barRoot) ? barRoot : delegate.Window.window;
                            var target = (win && win.contentItem) ? win.contentItem : win;
                            var pos = mapToItem(target, mouse.x, mouse.y);
                            modelData.display(win, Math.round(pos.x), Math.round(pos.y));
                        }
                    } else {
                        if (root.activeMenu)
                            root.activeMenu.visible = false;

                        if (mouse.button === Qt.MiddleButton)
                            modelData.secondaryActivate();
                        else if (mouse.button === Qt.LeftButton)
                            modelData.activate();
                    }
                }
                onWheel: (wheel) => {
                    if (root.activeMenu)
                        root.activeMenu.visible = false;

                    modelData.scroll(wheel.angleDelta.y, false);
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
