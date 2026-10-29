import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root

    property int internalBrightness: 80
    property bool hasExternalDisplay: false
    property string externalDisplayName: "External Display"
    property int externalDisplayId: 1
    property int externalBrightness: 50
    property int pendingExternalBrightness: 50

    function queryInternalBrightness() {
        internalProc.exec(["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m | cut -d, -f4 | tr -d % || echo $(( $(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1) * 100 / $(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1) ))"]);
    }

    function queryExternalDisplays() {
        ddcDetectProc.exec(["sh", "-c", "command -v ddcutil >/dev/null && ddcutil detect --brief 2>/dev/null | awk '/^Display/ {print $2; exit}' || echo ''"]);
    }

    function queryExternalBrightness(dispId) {
        ddcValProc.exec(["sh", "-c", "command -v ddcutil >/dev/null && ddcutil getvcp 10 --display " + dispId + " --brief 2>/dev/null | awk '{print $4}' || echo ''"]);
    }

    spacing: 16
    Layout.fillWidth: true
    Component.onCompleted: {
        queryInternalBrightness();
        queryExternalDisplays();
    }

    Process {
        id: execProc
    }

    // 150ms Debounce Timer for DDC/CI commands across the I2C bus
    Timer {
        id: ddcDebounceTimer

        interval: 150
        repeat: false
        onTriggered: {
            execProc.exec(["sh", "-c", "command -v ddcutil >/dev/null && ddcutil setvcp 10 " + root.pendingExternalBrightness + " --display " + root.externalDisplayId + " --noverify >/dev/null 2>&1"]);
        }
    }

    Process {
        id: internalProc

        stdout: SplitParser {
            onRead: (data) => {
                var val = parseInt(data.trim());
                if (!isNaN(val) && val >= 0) {
                    root.internalBrightness = val;
                    if (!internalSlider.pressed)
                        internalSlider.value = val;

                }
            }
        }

    }

    Process {
        id: ddcDetectProc

        stdout: SplitParser {
            onRead: (data) => {
                var d = data.trim();
                if (d !== "" && !isNaN(parseInt(d))) {
                    root.hasExternalDisplay = true;
                    root.externalDisplayId = parseInt(d);
                    root.externalDisplayName = "AOC 24G4 (Display " + d + ")";
                    root.queryExternalBrightness(root.externalDisplayId);
                } else {
                    root.hasExternalDisplay = false;
                }
            }
        }

    }

    Process {
        id: ddcValProc

        stdout: SplitParser {
            onRead: (data) => {
                var val = parseInt(data.trim());
                if (!isNaN(val) && val >= 0) {
                    root.externalBrightness = val;
                    if (!externalSlider.pressed)
                        externalSlider.value = val;

                }
            }
        }

    }

    // Display 1: Built-in Display (eDP-1)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "󰃠"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.accent
            }

            Text {
                text: "Built-in Display (eDP-1)"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontMd
                font.bold: true
                color: Theme.ink
                Layout.fillWidth: true
            }

            Text {
                text: Math.round(internalSlider.value) + "%"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                font.bold: true
                color: Theme.inkFaint
            }

        }

        Slider {
            id: internalSlider

            Layout.fillWidth: true
            from: 5
            to: 100
            value: root.internalBrightness
            onMoved: {
                var val = Math.round(value);
                root.internalBrightness = val;
                execProc.exec(["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -q set " + val + "% || busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetBrightness ssu backlight \"$(basename $(ls -d /sys/class/backlight/* 2>/dev/null | head -n1))\" $(( " + val + " * $(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1) / 100 ))"]);
            }

            background: Rectangle {
                x: internalSlider.leftPadding
                y: internalSlider.topPadding + internalSlider.availableHeight / 2 - height / 2
                implicitHeight: 28
                width: internalSlider.availableWidth
                height: implicitHeight
                radius: Theme.radiusSm
                color: Theme.bodyMid

                Rectangle {
                    width: internalSlider.visualPosition * parent.width
                    height: parent.height
                    color: Theme.accent
                    radius: Theme.radiusSm
                }

            }

            handle: Rectangle {
                x: internalSlider.leftPadding + internalSlider.visualPosition * (internalSlider.availableWidth - width)
                y: internalSlider.topPadding + internalSlider.availableHeight / 2 - height / 2
                implicitWidth: 12
                implicitHeight: 28
                radius: 4
                color: Theme.ink
                visible: internalSlider.pressed
            }

        }

    }

    // Display 2: External Display (DDC/CI via ddcutil)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: root.hasExternalDisplay

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "󰍹"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.accent
            }

            Text {
                text: root.externalDisplayName
                font.family: "sans-serif"
                font.pixelSize: Theme.fontMd
                font.bold: true
                color: Theme.ink
                Layout.fillWidth: true
            }

            Text {
                text: Math.round(externalSlider.value) + "%"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                font.bold: true
                color: Theme.inkFaint
            }

        }

        Slider {
            id: externalSlider

            Layout.fillWidth: true
            from: 0
            to: 100
            value: root.externalBrightness
            onMoved: {
                var val = Math.round(value);
                root.pendingExternalBrightness = val;
                ddcDebounceTimer.restart();
            }

            background: Rectangle {
                x: externalSlider.leftPadding
                y: externalSlider.topPadding + externalSlider.availableHeight / 2 - height / 2
                implicitHeight: 28
                width: externalSlider.availableWidth
                height: implicitHeight
                radius: Theme.radiusSm
                color: Theme.bodyMid

                Rectangle {
                    width: externalSlider.visualPosition * parent.width
                    height: parent.height
                    color: Theme.accent
                    radius: Theme.radiusSm
                }

            }

            handle: Rectangle {
                x: externalSlider.leftPadding + externalSlider.visualPosition * (externalSlider.availableWidth - width)
                y: externalSlider.topPadding + externalSlider.availableHeight / 2 - height / 2
                implicitWidth: 12
                implicitHeight: 28
                radius: 4
                color: Theme.ink
                visible: externalSlider.pressed
            }

        }

    }

}
