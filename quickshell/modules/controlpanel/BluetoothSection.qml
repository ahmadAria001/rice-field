import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root

    property var devices: []
    property bool isScanning: false
    property string connectingMac: ""
    readonly property bool isConnecting: connectingMac !== ""

    spacing: 12
    Layout.fillWidth: true

    function scanDevices() {
        if (isScanning) return;
        isScanning = true;
        listProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.sh", "list"]);
    }

    function toggleDevice(mac, currentlyConnected) {
        if (root.isConnecting) return;
        root.connectingMac = mac;
        var action = currentlyConnected ? "disconnect" : "connect";
        actionProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth.sh", action, mac]);
    }

    Timer {
        id: deferScanTimer
        interval: Theme.animNormal
        repeat: false
        onTriggered: root.scanDevices()
    }

    Component.onCompleted: {
        deferScanTimer.start();
    }

    onVisibleChanged: {
        if (visible) {
            deferScanTimer.restart();
        } else {
            deferScanTimer.stop();
        }
    }

    Process {
        id: listProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false;
                try {
                    var parsed = JSON.parse(this.text.trim());
                    if (Array.isArray(parsed)) {
                        root.devices = parsed;
                    }
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: actionProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.connectingMac = "";
                root.scanDevices();
            }
        }
    }

    // Top action bar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: root.isConnecting ? "Connecting / Disconnecting..." : (root.devices.length + " paired / known devices")
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.isConnecting ? Theme.accent : Theme.inkFaint
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Refresh button
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSm
            color: rescanMouse.containsMouse && !root.isConnecting ? Theme.bodyTop : Theme.bodyMid
            opacity: (root.isScanning || root.isConnecting) ? 0.5 : 1.0

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.ink
                rotation: root.isScanning ? 360 : 0
                Behavior on rotation {
                    NumberAnimation { duration: 800; loops: Animation.Infinite }
                }
            }

            MouseArea {
                id: rescanMouse
                anchors.fill: parent
                enabled: !root.isScanning && !root.isConnecting
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.scanDevices()
            }
        }
    }

    // Devices list
    ScrollView {
        id: btScroll
        Layout.fillWidth: true
        Layout.maximumHeight: 340
        Layout.preferredHeight: Math.min(340, devCol.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: devCol
            width: btScroll.availableWidth
            spacing: 6

            Repeater {
                model: root.devices

                delegate: Rectangle {
                    id: devCard
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: modelData.connected ? Theme.bodyTop : (devMouse.containsMouse && !root.isConnecting ? Theme.bodyMid : "transparent")
                    border.color: modelData.connected ? Theme.accent : "transparent"
                    border.width: modelData.connected ? 1 : 0
                    opacity: (root.isConnecting && root.connectingMac !== modelData.mac) ? 0.45 : 1.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Device Icon
                        Text {
                            text: {
                                var name = (modelData.name || "").toLowerCase();
                                if (name.indexOf("moca") !== -1 || name.indexOf("head") !== -1 || name.indexOf("ear") !== -1 || name.indexOf("pma") !== -1) {
                                    return "󰋋";
                                }
                                return "󰂯";
                            }
                            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                            font.pixelSize: Theme.fontLg
                            color: modelData.connected ? Theme.accent : Theme.inkFaint
                        }

                        // Name & MAC
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name || modelData.mac
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontSm
                                font.bold: modelData.connected
                                color: modelData.connected ? Theme.accent : Theme.ink
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : modelData.mac)
                                font.family: "sans-serif"
                                font.pixelSize: 10
                                color: modelData.connected ? Theme.accent : Theme.inkFaint
                            }
                        }

                        // Status / Spinner
                        Item {
                            implicitWidth: 32
                            implicitHeight: 32

                            Text {
                                visible: root.connectingMac === modelData.mac
                                anchors.centerIn: parent
                                text: "󰑐"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontMd
                                color: Theme.accent
                            }

                            Text {
                                visible: modelData.connected && root.connectingMac !== modelData.mac
                                anchors.centerIn: parent
                                text: "󰄴"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontMd
                                color: Theme.accent
                            }
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        enabled: !root.isConnecting
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.toggleDevice(modelData.mac, modelData.connected);
                        }
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        visible: root.devices.length === 0 && !root.isScanning
        Layout.alignment: Qt.AlignHCenter
        text: "No paired Bluetooth devices found"
        font.family: "JetBrainsMono Nerd Font, sans-serif"
        font.pixelSize: Theme.fontSm
        color: Theme.inkFaint
    }
}
