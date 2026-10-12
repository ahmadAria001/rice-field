import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

PopupWindow {
    id: controlPanel

    property var triggerItem: null
    property string currentView: "main"

    anchor.item: triggerItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 40
    anchor.margins.right: 100
    visible: false
    color: "transparent"
    implicitWidth: 360
    implicitHeight: container.implicitHeight
    onVisibleChanged: {
        if (!visible)
            controlPanel.currentView = "main";

    }

    HyprlandFocusGrab {
        active: controlPanel.backingWindowVisible
        windows: [controlPanel]
        onCleared: controlPanel.visible = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: controlPanel.visible
        onActivated: controlPanel.visible = false
    }

    Connections {
        function onFocusedWorkspaceChanged() {
            if (controlPanel.visible)
                controlPanel.visible = false;

        }

        target: Hyprland
    }

    IpcHandler {
        function toggle() {
            controlPanel.visible = !controlPanel.visible;
        }

        target: "controlpanel"
    }

    Rectangle {
        id: container

        anchors.fill: parent
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusLg
        implicitHeight: mainLayout.implicitHeight + 28

        ColumnLayout {
            id: mainLayout

            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // Header Row (Dynamic based on currentView)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    visible: controlPanel.currentView !== "main"
                    text: {
                        if (controlPanel.currentView === "audio")
                            return "Audio & Mixer";

                        if (controlPanel.currentView === "brightness")
                            return "Display Brightness";

                        if (controlPanel.currentView === "wallpapers")
                            return "Wallpapers";

                        if (controlPanel.currentView === "wifi")
                            return "Wi-Fi Networks";

                        if (controlPanel.currentView === "bluetooth")
                            return "Bluetooth Devices";

                        return "";
                    }
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    color: Theme.text
                }

                // Back Button (shown only on subpages)
                Rectangle {
                    visible: controlPanel.currentView !== "main"
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Theme.radiusSm
                    color: backMouse.containsMouse ? Theme.surface1 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontLg
                        color: Theme.mauve
                    }

                    MouseArea {
                        id: backMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlPanel.currentView = "main";
                        }
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                // Battery indicator (shown on main page)
                RowLayout {
                    spacing: 6
                    visible: controlPanel.currentView === "main" && UPower.displayDevice && UPower.displayDevice.isPresent

                    Text {
                        text: {
                            var pct = UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 100;
                            var isCharging = UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging;
                            if (isCharging)
                                return "󰂄";

                            if (pct >= 90)
                                return "󰁹";

                            if (pct >= 80)
                                return "󰂂";

                            if (pct >= 70)
                                return "󰂁";

                            if (pct >= 60)
                                return "󰂀";

                            if (pct >= 50)
                                return "󰁿";

                            if (pct >= 40)
                                return "󰁾";

                            if (pct >= 30)
                                return "󰁽";

                            if (pct >= 20)
                                return "󰁼";

                            return "󰁺";
                        }
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontMd
                        color: (UPower.displayDevice && UPower.displayDevice.percentage < 0.2) ? Theme.red : Theme.mauve
                    }

                    Text {
                        text: (UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 0) + "%"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: Theme.subtext0
                    }

                }

            }

            // View 1: Main Dashboard
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: controlPanel.currentView === "main"

                // Sliders (Volume & Brightness)
                SliderSection {
                    onOpenAudioMixer: {
                        controlPanel.currentView = "audio";
                    }
                    onOpenBrightness: {
                        controlPanel.currentView = "brightness";
                    }
                }

                // Quick Toggles (Wi-Fi, Bluetooth, Night Light, Caffeine, DND, Screenshot, Wallpaper)
                QuickToggles {
                    onRequestClose: {
                        controlPanel.visible = false;
                    }
                    onOpenWallpapers: {
                        controlPanel.currentView = "wallpapers";
                    }
                    onOpenWifi: {
                        controlPanel.currentView = "wifi";
                    }
                    onOpenBluetooth: {
                        controlPanel.currentView = "bluetooth";
                    }
                }

                // MPRIS Media Player
                MediaSection {
                }

                // Session Actions (Lock, Suspend, Reboot, Power Off)
                SessionSection {
                }

            }

            // View 2: Audio Mixer & Sink Switcher
            AudioMixer {
                visible: controlPanel.currentView === "audio"
            }

            // View 3: Multi-Monitor Brightness
            BrightnessSection {
                visible: controlPanel.currentView === "brightness"
            }

            // View 4: Wallpaper Selector
            WallpaperSection {
                visible: controlPanel.currentView === "wallpapers"
            }

            // View 5: Wi-Fi Networks
            WifiSection {
                visible: controlPanel.currentView === "wifi"
            }

            // View 6: Bluetooth Devices
            BluetoothSection {
                visible: controlPanel.currentView === "bluetooth"
            }

        }

    }

}
