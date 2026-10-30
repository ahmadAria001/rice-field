import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root

    property int volumeLevel: 50
    property bool isMuted: false
    property int brightnessLevel: 80

    signal openAudioMixer()
    signal openBrightness()

    function queryVolume() {
        volProc.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
    }

    function queryBrightness() {
        brightProc.exec(["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m | cut -d, -f4 | tr -d % || echo $(( $(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1) * 100 / $(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1) ))"]);
    }

    spacing: 12
    Layout.fillWidth: true
    Component.onCompleted: {
        queryVolume();
        queryBrightness();
    }

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!volSlider.pressed)
                root.queryVolume();

            if (!brightSlider.pressed)
                root.queryBrightness();

        }
    }

    Process {
        id: volProc

        stdout: SplitParser {
            onRead: (data) => {
                var text = data.trim();
                var match = text.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    root.volumeLevel = Math.round(parseFloat(match[1]) * 100);
                    root.isMuted = text.indexOf("[MUTED]") !== -1;
                    if (!volSlider.pressed)
                        volSlider.value = root.volumeLevel;

                }
            }
        }

    }

    Process {
        id: brightProc

        stdout: SplitParser {
            onRead: (data) => {
                var val = parseInt(data.trim());
                if (!isNaN(val) && val >= 0) {
                    root.brightnessLevel = val;
                    if (!brightSlider.pressed)
                        brightSlider.value = val;

                }
            }
        }

    }

    Process {
        id: execProc
    }

    // Volume Slider Row
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        // Mute / Unmute Button
        Rectangle {
            id: muteBtn

            implicitWidth: 32
            implicitHeight: 32
            radius: Theme.radiusSm
            color: muteMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid

            Text {
                anchors.centerIn: parent
                text: root.isMuted ? "󰝟" : (root.volumeLevel < 33 ? "󰕿" : (root.volumeLevel < 66 ? "󰖀" : "󰕾"))
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontLg
                color: root.isMuted ? Theme.danger : Theme.ink
            }

            MouseArea {
                id: muteMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    execProc.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                    root.queryVolume();
                }
            }

        }

        // Volume Slider
        RiceSlider {
            id: volSlider

            from: 0
            to: 100
            value: root.volumeLevel
            Layout.fillWidth: true
            fillColor: root.isMuted ? Theme.bodyTop : Theme.accent
            onMoved: {
                var val = Math.round(value);
                root.volumeLevel = val;
                execProc.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", val + "%"]);
            }
        }

        // Drill-down button for Audio Mixer
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSm
            color: audioDrillMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid

            Text {
                anchors.centerIn: parent
                text: "󰅂"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.ink
            }

            MouseArea {
                id: audioDrillMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openAudioMixer()
            }

            // The card every other surface uses, pinned below the button instead
            // of the default tooltip that followed the cursor and ate the click.
            TooltipCard {
                anchorItem: audioDrillMouse
                shown: audioDrillMouse.containsMouse
                text: "Audio & Mixer Settings"
            }

        }

    }

    // Brightness Slider Row
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        // Brightness Icon Box
        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: Theme.radiusSm
            color: Theme.bodyMid

            Text {
                anchors.centerIn: parent
                text: root.brightnessLevel < 33 ? "󰃞" : (root.brightnessLevel < 66 ? "󰃟" : "󰃠")
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontLg
                color: Theme.ink
            }

        }

        // Brightness Slider
        RiceSlider {
            id: brightSlider

            from: 5
            to: 100
            value: root.brightnessLevel
            Layout.fillWidth: true
            onMoved: {
                var val = Math.round(value);
                root.brightnessLevel = val;
                execProc.exec(["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -q set " + val + "% || busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetBrightness ssu backlight \"$(basename $(ls -d /sys/class/backlight/* 2>/dev/null | head -n1))\" $(( " + val + " * $(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1) / 100 ))"]);
            }
        }

        // Drill-down button for Multi-Monitor Brightness
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSm
            color: brightDrillMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid

            Text {
                anchors.centerIn: parent
                text: "󰅂"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.ink
            }

            MouseArea {
                id: brightDrillMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openBrightness()
            }

            TooltipCard {
                anchorItem: brightDrillMouse
                shown: brightDrillMouse.containsMouse
                text: "Display Brightness Settings"
            }

        }

    }

}
