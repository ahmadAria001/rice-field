import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland

GridLayout {
    id: root

    property bool wifiEnabled: false
    property string wifiSsid: "Disconnected"
    property bool btEnabled: false
    property string btDevice: "Off"
    property bool nightLightEnabled: false
    property bool caffeineEnabled: false

    signal requestClose()

    function refreshNetwork() {
        netProc.exec(["sh", "-c", "echo WIFI:$(nmcli -t -f WIFI g 2>/dev/null); echo SSID:$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2)"]);
    }

    function refreshBluetooth() {
        btProc.exec(["sh", "-c", "echo POWER:$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}'); echo DEV:$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)"]);
    }

    columns: 2
    columnSpacing: 10
    rowSpacing: 10
    Layout.fillWidth: true
    Component.onCompleted: {
        refreshNetwork();
        refreshBluetooth();
    }

    IdleInhibitor {
        enabled: root.caffeineEnabled
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: {
            root.refreshNetwork();
            root.refreshBluetooth();
        }
    }

    Process {
        id: netProc

        stdout: SplitParser {
            onRead: (data) => {
                var lines = data.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i];
                    if (l.startsWith("WIFI:")) {
                        root.wifiEnabled = (l.substring(5).trim() === "enabled");
                    } else if (l.startsWith("SSID:")) {
                        var ssid = l.substring(5).trim();
                        root.wifiSsid = ssid !== "" ? ssid : (root.wifiEnabled ? "Disconnected" : "Off");
                    }
                }
            }
        }

    }

    Process {
        id: btProc

        stdout: SplitParser {
            onRead: (data) => {
                var lines = data.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i];
                    if (l.startsWith("POWER:")) {
                        root.btEnabled = (l.substring(6).trim() === "yes");
                    } else if (l.startsWith("DEV:")) {
                        var dev = l.substring(4).trim();
                        root.btDevice = dev !== "" ? dev : (root.btEnabled ? "On" : "Off");
                    }
                }
            }
        }

    }

    Process {
        id: execProc
    }

    Process {
        id: screenshotProc
    }

    Timer {
        id: screenshotTimer

        interval: 200
        repeat: false
        onTriggered: {
            screenshotProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/screenshot.sh", "area"]);
        }
    }

    // Toggle 1: Wi-Fi
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: root.wifiEnabled ? Theme.mauve : (wifiMouse.containsMouse ? Theme.surface1 : Theme.surface0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: root.wifiEnabled ? "󰤨" : "󰤮"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: root.wifiEnabled ? Theme.mantle : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Wi-Fi"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: root.wifiEnabled ? Theme.mantle : Theme.text
                }

                Text {
                    text: root.wifiSsid
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: root.wifiEnabled ? "#313244" : Theme.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        MouseArea {
            id: wifiMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var target = root.wifiEnabled ? "off" : "on";
                execProc.exec(["nmcli", "radio", "wifi", target]);
                root.wifiEnabled = !root.wifiEnabled;
                root.refreshNetwork();
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // Toggle 2: Bluetooth
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: root.btEnabled ? Theme.mauve : (btMouse.containsMouse ? Theme.surface1 : Theme.surface0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: root.btEnabled ? "󰂯" : "󰂲"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: root.btEnabled ? Theme.mantle : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Bluetooth"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: root.btEnabled ? Theme.mantle : Theme.text
                }

                Text {
                    text: root.btDevice
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: root.btEnabled ? "#313244" : Theme.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        MouseArea {
            id: btMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var target = root.btEnabled ? "off" : "on";
                execProc.exec(["bluetoothctl", "power", target]);
                root.btEnabled = !root.btEnabled;
                root.refreshBluetooth();
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // Toggle 3: Night Light
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: root.nightLightEnabled ? Theme.mauve : (nlMouse.containsMouse ? Theme.surface1 : Theme.surface0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: "󰖔"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: root.nightLightEnabled ? Theme.mantle : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Night Light"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: root.nightLightEnabled ? Theme.mantle : Theme.text
                }

                Text {
                    text: root.nightLightEnabled ? "Warm" : "Off"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: root.nightLightEnabled ? "#313244" : Theme.subtext0
                }

            }

        }

        MouseArea {
            id: nlMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.nightLightEnabled = !root.nightLightEnabled;
                if (root.nightLightEnabled)
                    execProc.exec(["sh", "-c", "command -v hyprsunset >/dev/null && hyprsunset -t 4500 &"]);
                else
                    execProc.exec(["sh", "-c", "pkill -f hyprsunset 2>/dev/null || true"]);
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // Toggle 4: Caffeine / Idle Inhibitor
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: root.caffeineEnabled ? Theme.mauve : (caffMouse.containsMouse ? Theme.surface1 : Theme.surface0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: "󰅶"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: root.caffeineEnabled ? Theme.mantle : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Caffeine"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: root.caffeineEnabled ? Theme.mantle : Theme.text
                }

                Text {
                    text: root.caffeineEnabled ? "Awake" : "Off"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: root.caffeineEnabled ? "#313244" : Theme.subtext0
                }

            }

        }

        MouseArea {
            id: caffMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.caffeineEnabled = !root.caffeineEnabled;
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // Toggle 5: Do Not Disturb
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: Theme.dndEnabled ? Theme.mauve : (dndMouse.containsMouse ? Theme.surface1 : Theme.surface0)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: Theme.dndEnabled ? "󰂛" : "󰂚"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: Theme.dndEnabled ? Theme.mantle : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Do Not Disturb"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: Theme.dndEnabled ? Theme.mantle : Theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: Theme.dndEnabled ? "Silenced" : "Normal"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.dndEnabled ? "#313244" : Theme.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        MouseArea {
            id: dndMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Theme.dndEnabled = !Theme.dndEnabled;
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    // Toggle 6: Screenshot
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 46
        radius: Theme.radiusSm
        color: screenshotMouse.containsMouse ? Theme.surface1 : Theme.surface0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: "󰄀"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: Theme.mauve
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Screenshot"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: Theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "Capture area"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        MouseArea {
            id: screenshotMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.requestClose();
                if (typeof controlPanel !== "undefined" && controlPanel)
                    controlPanel.visible = false;

                screenshotTimer.start();
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

}
