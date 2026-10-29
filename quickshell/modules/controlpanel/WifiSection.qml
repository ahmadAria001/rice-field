import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root

    property var networks: []
    property bool isScanning: false
    property string connectingSsid: ""
    readonly property bool isConnecting: connectingSsid !== ""
    property string passwordInputSsid: ""
    property string passwordText: ""

    spacing: 12
    Layout.fillWidth: true

    function scanNetworks() {
        if (isScanning) return;
        isScanning = true;
        scanProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/network.sh", "list"]);
    }

    function connectToNetwork(ssid, password) {
        if (root.isConnecting) return;
        root.connectingSsid = ssid;
        var args = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network.sh", "connect", ssid];
        if (password) {
            args.push(password);
        }
        connectProc.exec(args);
    }

    function disconnectNetwork(ssid) {
        if (root.isConnecting) return;
        root.connectingSsid = ssid;
        disconnectProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/network.sh", "disconnect", ssid]);
    }

    Timer {
        id: deferScanTimer
        interval: Theme.animNormal
        repeat: false
        onTriggered: root.scanNetworks()
    }

    Component.onCompleted: {
        deferScanTimer.start();
    }

    onVisibleChanged: {
        if (visible) {
            root.passwordInputSsid = "";
            root.passwordText = "";
            deferScanTimer.restart();
        } else {
            deferScanTimer.stop();
        }
    }

    Process {
        id: scanProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false;
                try {
                    var parsed = JSON.parse(this.text.trim());
                    if (Array.isArray(parsed)) {
                        root.networks = parsed;
                    }
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: connectProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.connectingSsid = "";
                root.passwordInputSsid = "";
                root.passwordText = "";
                root.scanNetworks();
            }
        }
    }

    Process {
        id: disconnectProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.connectingSsid = "";
                root.scanNetworks();
            }
        }
    }

    // Top action bar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: root.isConnecting ? ("Connecting to " + root.connectingSsid + "...") : (root.isScanning ? "Scanning networks..." : (root.networks.length + " networks found"))
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.isConnecting ? Theme.accent : Theme.inkFaint
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Rescan button
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
                onClicked: root.scanNetworks()
            }
        }
    }

    // Password Prompt Card (if prompt active)
    Rectangle {
        visible: root.passwordInputSsid !== ""
        Layout.fillWidth: true
        implicitHeight: passCol.implicitHeight + 16
        radius: Theme.radiusSm
        color: Theme.bodyMid
        border.color: Theme.accent
        border.width: 1

        ColumnLayout {
            id: passCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                text: "Password for \"" + root.passwordInputSsid + "\":"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                font.bold: true
                color: Theme.ink
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                color: Theme.bodyLow
                border.color: pwdInput.activeFocus ? Theme.accent : Theme.bodyTop
                border.width: 1

                TextInput {
                    id: pwdInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.ink
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    echoMode: TextInput.Password
                    enabled: !root.isConnecting
                    onTextChanged: root.passwordText = text
                    onAccepted: {
                        if (text.length > 0) {
                            root.connectToNetwork(root.passwordInputSsid, text);
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 26
                    radius: 6
                    color: cancelMouse.containsMouse ? Theme.bodyTop : "transparent"
                    border.color: Theme.bodyTop
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.inkFaint
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        enabled: !root.isConnecting
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.passwordInputSsid = "";
                            root.passwordText = "";
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 68
                    implicitHeight: 26
                    radius: 6
                    color: root.isConnecting ? Theme.bodyTop : (joinMouse.containsMouse ? Theme.accent : Theme.bodyTop)

                    Text {
                        anchors.centerIn: parent
                        text: root.isConnecting ? "Joining..." : "Connect"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: root.isConnecting ? Theme.inkFaint : (joinMouse.containsMouse ? Theme.bodyLow : Theme.ink)
                    }

                    MouseArea {
                        id: joinMouse
                        anchors.fill: parent
                        enabled: !root.isConnecting && pwdInput.text.length > 0
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.connectToNetwork(root.passwordInputSsid, pwdInput.text);
                        }
                    }
                }
            }
        }
    }

    // Network list
    ScrollView {
        id: wifiScroll
        Layout.fillWidth: true
        Layout.maximumHeight: 340
        Layout.preferredHeight: Math.min(340, netCol.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: netCol
            width: wifiScroll.availableWidth
            spacing: 6

            Repeater {
                model: root.networks

                delegate: Rectangle {
                    id: itemCard
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: modelData.active ? Theme.bodyTop : (itemMouse.containsMouse && !root.isConnecting ? Theme.bodyMid : "transparent")
                    border.color: modelData.active ? Theme.accent : "transparent"
                    border.width: modelData.active ? 1 : 0
                    opacity: (root.isConnecting && root.connectingSsid !== modelData.ssid) ? 0.45 : 1.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Signal Icon
                        Text {
                            text: {
                                var sig = modelData.signal;
                                if (sig >= 75) return "󰤨";
                                if (sig >= 50) return "󰤥";
                                if (sig >= 25) return "󰤢";
                                return "󰤟";
                            }
                            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                            font.pixelSize: Theme.fontLg
                            color: modelData.active ? Theme.accent : Theme.inkFaint
                        }

                        // SSID & Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.ssid
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontSm
                                font.bold: modelData.active
                                color: modelData.active ? Theme.accent : Theme.ink
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 4
                                Text {
                                    text: modelData.active ? "Connected" : (modelData.secured ? "Secured" : "Open")
                                    font.family: "sans-serif"
                                    font.pixelSize: 10
                                    color: modelData.active ? Theme.accent : Theme.inkFaint
                                }
                                Text {
                                    visible: modelData.secured
                                    text: "󰌾"
                                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                    font.pixelSize: 10
                                    color: Theme.inkFaint
                                }
                            }
                        }

                        // Connecting spinner / status / action button
                        Item {
                            implicitWidth: 32
                            implicitHeight: 32

                            Text {
                                visible: root.connectingSsid === modelData.ssid
                                anchors.centerIn: parent
                                text: "󰑐"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontMd
                                color: Theme.accent
                            }

                            Text {
                                visible: modelData.active && root.connectingSsid !== modelData.ssid
                                anchors.centerIn: parent
                                text: "󰄴"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontMd
                                color: Theme.accent
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        enabled: !root.isConnecting
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (modelData.active) {
                                root.disconnectNetwork(modelData.ssid);
                            } else if (modelData.secured) {
                                root.passwordInputSsid = modelData.ssid;
                                root.passwordText = "";
                            } else {
                                root.connectToNetwork(modelData.ssid, "");
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        visible: root.networks.length === 0 && !root.isScanning
        Layout.alignment: Qt.AlignHCenter
        text: "No Wi-Fi networks found"
        font.family: "JetBrainsMono Nerd Font, sans-serif"
        font.pixelSize: Theme.fontSm
        color: Theme.inkFaint
    }
}
