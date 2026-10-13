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

    property string previousView: "main"
    property bool isNavigatingBack: false
    property real viewOffset: 28

    function navigateTo(viewName) {
        if (currentView === viewName) return;
        isNavigatingBack = false;
        previousView = currentView;
        currentView = viewName;
    }

    function navigateBack() {
        if (currentView === "main") return;
        isNavigatingBack = true;
        previousView = currentView;
        currentView = "main";
    }

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

    property real targetHeight: headerRow.implicitHeight + targetViewportHeight + 42
    readonly property real targetViewportHeight: {
        if (controlPanel.currentView === "main") return mainView.implicitHeight;
        if (controlPanel.currentView === "audio") return audioView.implicitHeight;
        if (controlPanel.currentView === "brightness") return brightView.implicitHeight;
        if (controlPanel.currentView === "wallpapers") return wallView.implicitHeight;
        if (controlPanel.currentView === "wifi") return wifiView.implicitHeight;
        if (controlPanel.currentView === "bluetooth") return btView.implicitHeight;
        return mainView.implicitHeight;
    }
    property real windowHeight: targetHeight

    onTargetHeightChanged: {
        // Grow immediately if new view is taller to prevent frame clipping
        if (targetHeight > windowHeight) {
            windowHeight = targetHeight;
        }
    }

    implicitHeight: Math.max(windowHeight, container.implicitHeight)

    HyprlandFocusGrab {
        active: controlPanel.backingWindowVisible && controlPanel.shown
        windows: [controlPanel]
        onCleared: controlPanel.close()
    }

    Shortcut {
        sequence: "Escape"
        enabled: controlPanel.shown
        onActivated: {
            if (controlPanel.currentView !== "main") {
                controlPanel.navigateBack();
            } else {
                controlPanel.close();
            }
        }
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
                controlPanel.previousView = "main";
            }
        }

        color: Theme.mantle
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusLg
        implicitHeight: headerRow.implicitHeight + viewViewport.implicitHeight + 42

        ColumnLayout {
            id: mainLayout

            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            // Header Row (Crossfades between subpage title/back button and battery status)
            RowLayout {
                id: headerRow

                Layout.fillWidth: true
                spacing: 8

                // Subpage title + back button group
                RowLayout {
                    spacing: 8
                    opacity: controlPanel.currentView !== "main" ? 1.0 : 0.0
                    visible: opacity > 0.001

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Theme.easeGeneral
                        }
                    }

                    Rectangle {
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
                            onClicked: controlPanel.navigateBack()
                        }
                    }

                    Text {
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
                }

                Item {
                    Layout.fillWidth: true
                }

                // Battery indicator group (shown on main page)
                RowLayout {
                    spacing: 6
                    opacity: controlPanel.currentView === "main" ? 1.0 : 0.0
                    visible: opacity > 0.001 && UPower.displayDevice && UPower.displayDevice.isPresent

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Theme.easeGeneral
                        }
                    }

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

            // Single Clipped Viewport for Subviews
            Item {
                id: viewViewport

                Layout.fillWidth: true
                clip: true
                implicitHeight: {
                    if (controlPanel.currentView === "main") return mainView.implicitHeight;
                    if (controlPanel.currentView === "audio") return audioView.implicitHeight;
                    if (controlPanel.currentView === "brightness") return brightView.implicitHeight;
                    if (controlPanel.currentView === "wallpapers") return wallView.implicitHeight;
                    if (controlPanel.currentView === "wifi") return wifiView.implicitHeight;
                    if (controlPanel.currentView === "bluetooth") return btView.implicitHeight;
                    return mainView.implicitHeight;
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Theme.animNormal
                        easing.type: Theme.easeEntrance
                        onFinished: {
                            controlPanel.windowHeight = controlPanel.targetHeight;
                        }
                    }
                }

                // View 1: Main Dashboard
                Item {
                    id: mainWrapper
                    width: parent.width
                    height: mainView.implicitHeight
                    property bool isActive: controlPanel.currentView === "main"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? controlPanel.viewOffset : -controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animNormal
                            easing.type: Theme.easeEntrance
                        }
                    }
                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animNormal
                            easing.type: Theme.easeEntrance
                        }
                    }

                    ColumnLayout {
                        id: mainView
                        width: parent.width
                        spacing: 14

                        SliderSection {
                            onOpenAudioMixer: controlPanel.navigateTo("audio")
                            onOpenBrightness: controlPanel.navigateTo("brightness")
                        }

                        QuickToggles {
                            onRequestClose: controlPanel.close()
                            onOpenWallpapers: controlPanel.navigateTo("wallpapers")
                            onOpenWifi: controlPanel.navigateTo("wifi")
                            onOpenBluetooth: controlPanel.navigateTo("bluetooth")
                        }

                        MediaSection {}
                        InferhubSection {}
                        SessionSection {}
                    }
                }

                // View 2: Audio Mixer
                Item {
                    id: audioWrapper
                    width: parent.width
                    height: audioView.implicitHeight
                    property bool isActive: controlPanel.currentView === "audio"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? -controlPanel.viewOffset : controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }

                    AudioMixer {
                        id: audioView
                        width: parent.width
                    }
                }

                // View 3: Brightness
                Item {
                    id: brightWrapper
                    width: parent.width
                    height: brightView.implicitHeight
                    property bool isActive: controlPanel.currentView === "brightness"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? -controlPanel.viewOffset : controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }

                    BrightnessSection {
                        id: brightView
                        width: parent.width
                    }
                }

                // View 4: Wallpapers
                Item {
                    id: wallWrapper
                    width: parent.width
                    height: wallView.implicitHeight
                    property bool isActive: controlPanel.currentView === "wallpapers"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? -controlPanel.viewOffset : controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }

                    WallpaperSection {
                        id: wallView
                        width: parent.width
                        visible: wallWrapper.isActive
                    }
                }

                // View 5: Wi-Fi Networks
                Item {
                    id: wifiWrapper
                    width: parent.width
                    height: wifiView.implicitHeight
                    property bool isActive: controlPanel.currentView === "wifi"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? -controlPanel.viewOffset : controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }

                    WifiSection {
                        id: wifiView
                        width: parent.width
                        visible: wifiWrapper.isActive
                    }
                }

                // View 6: Bluetooth Devices
                Item {
                    id: btWrapper
                    width: parent.width
                    height: btView.implicitHeight
                    property bool isActive: controlPanel.currentView === "bluetooth"
                    visible: isActive || opacity > 0.001
                    opacity: isActive ? 1.0 : 0.0
                    x: {
                        if (isActive) return 0;
                        return controlPanel.isNavigatingBack ? -controlPanel.viewOffset : controlPanel.viewOffset;
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easeEntrance }
                    }

                    BluetoothSection {
                        id: btView
                        width: parent.width
                        visible: btWrapper.isActive
                    }
                }
            }
        }
    }
}
