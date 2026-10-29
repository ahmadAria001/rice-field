import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool shown: false

    function open() {
        searchField.text = "";
        searchField.forceActiveFocus();
        appList.currentIndex = 0;
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown) {
            root.close();
        } else {
            root.open();
        }
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    visible: shown || cardWrapper.opacity > 0.001
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function close() {
            root.close();
        }

        target: "launcher"
    }

    // Backdrop Dismissal
    MouseArea {
        anchors.fill: parent
        enabled: root.shown
        onClicked: root.close()

        Rectangle {
            anchors.fill: parent
            color: "#80000000" // 50% opacity black backdrop
            opacity: root.shown ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.shown ? Theme.animNormal : Theme.animExit
                    easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
                }
            }
        }
    }

    // UI Layout (Center Modal Card with Scale + Opacity wrapper)
    Item {
        id: cardWrapper

        width: 580
        height: 480
        anchors.centerIn: parent

        opacity: root.shown ? 1.0 : 0.0
        scale: root.shown ? 1.0 : Theme.scaleDown

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? Theme.animNormal : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: root.shown ? Theme.animNormal : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }
        }

        Rectangle {
            id: card

            anchors.fill: parent
            // The shared surface: bodyMid under a rim edge with her gradient on top.
            color: Theme.bodyMid
            radius: Theme.radiusLg
            border.color: Theme.rim
            border.width: Theme.borderWidth

            HairBar {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: card.radius
                anchors.rightMargin: card.radius
                anchors.topMargin: 1
                height: 2
                radius: 0
                opacity: 0.34
                fadeTo: "end"
            }

            // Overlay only: nothing between opens, and no input taken.
            ScanReveal {
                anchors.fill: parent
                active: root.shown
                z: 100
            }

            MouseArea {
                // prevent click events from propagating to the backdrop
                anchors.fill: parent
            }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Top: TextField for real-time search
            TextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: "Search applications..."
                placeholderTextColor: Theme.subtext0
                font.pixelSize: Theme.fontXl
                color: Theme.text
                focus: true
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        appList.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        appList.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (appList.currentItem)
                            appList.currentItem.launch();

                        event.accepted = true;
                    }
                }

                background: Rectangle {
                    color: Theme.surface0
                    radius: Theme.radiusSm
                    border.color: searchField.activeFocus ? Theme.mauve : Theme.surface1
                    border.width: Theme.borderWidth
                }

            }

            // Bottom: ListView displaying matched applications
            ListView {
                id: appList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4

                model: ScriptModel {
                    id: appModel

                    values: {
                        const search = searchField.text.toLowerCase();
                        if (!DesktopEntries || !DesktopEntries.applications || !DesktopEntries.applications.values)
                            return [];

                        const allApps = DesktopEntries.applications.values;
                        const filtered = allApps.filter((app) => {
                            if (app.noDisplay)
                                return false;

                            if (!app.name)
                                return false;

                            return app.name.toLowerCase().includes(search);
                        });
                        filtered.sort((a, b) => {
                            const nameA = (a.name || "").toLowerCase();
                            const nameB = (b.name || "").toLowerCase();
                            if (nameA < nameB)
                                return -1;

                            if (nameA > nameB)
                                return 1;

                            return 0;
                        });
                        return filtered;
                    }
                }

                delegate: AppItem {
                    isCurrent: index === appList.currentIndex
                    onLaunched: root.close()
                }

            }

        }

    }

    }

}
