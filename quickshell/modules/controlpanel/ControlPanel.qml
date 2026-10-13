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
    property bool shown: false

    function open() {
        controlPanel.shown = true;
    }

    function close() {
        if (!controlPanel.shown) return;
        controlPanel.shown = false;
    }

    function toggle() {
        if (controlPanel.shown) {
            controlPanel.close();
        } else {
            controlPanel.open();
        }
    }

    anchor.item: triggerItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 40
    anchor.margins.right: 100
    visible: shown || container.opacity > 0.001
    color: "transparent"
    implicitWidth: 360
    implicitHeight: container.implicitHeight

    HyprlandFocusGrab {
        active: controlPanel.backingWindowVisible && controlPanel.shown
        windows: [controlPanel]
        onCleared: controlPanel.close()
    }

    Shortcut {
        sequence: "Escape"
        enabled: controlPanel.shown
        onActivated: controlPanel.close()
    }

    Connections {
        function onFocusedWorkspaceChanged() {
            controlPanel.close();
        }

        target: Hyprland
    }

    IpcHandler {
        function toggle() {
            controlPanel.toggle();
        }

        function open() {
            controlPanel.open();
        }

        function close() {
            controlPanel.close();
        }

        target: "controlpanel"
    }

    Rectangle {
        id: container

        anchors.left: parent.left
        anchors.right: parent.right
        enabled: controlPanel.shown
        y: {
            if (controlPanel.shown) return 0;
            if (Theme.panelSlideDirection === "fromTop") return -Theme.slideDistancePanel;
            if (Theme.panelSlideDirection === "fromBottom") return Theme.slideDistancePanel;
            return 0;
        }
        x: {
            if (controlPanel.shown) return 0;
            if (Theme.panelSlideDirection === "fromRight") return Theme.slideDistancePanel;
            if (Theme.panelSlideDirection === "fromLeft") return -Theme.slideDistancePanel;
            return 0;
        }

        opacity: controlPanel.shown ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                duration: controlPanel.shown ? Theme.animNormal : Theme.animExit
                easing.type: controlPanel.shown ? Theme.easeEntrance : Theme.easeExit
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: controlPanel.shown ? Theme.animNormal : Theme.animExit
                easing.type: controlPanel.shown ? Theme.easeEntrance : Theme.easeExit
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: controlPanel.shown ? Theme.animNormal : Theme.animExit
                easing.type: controlPanel.shown ? Theme.easeEntrance : Theme.easeExit
            }
        }

        onOpacityChanged: {
            // When exit finishes and opacity hits 0, reset subview to main
            if (!controlPanel.shown && opacity <= 0.001) {
                controlPanel.currentView = "main";
            }
        }

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
                        controlPanel.close();
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

                // InferHub AI Usage (via PakAI)
                InferhubSection {
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
