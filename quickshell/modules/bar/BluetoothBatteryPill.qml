import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Battery level of connected Bluetooth peripherals: earbuds, headsets, mice.
//
// The source is UPower rather than BlueZ directly. UPower already tracks the
// org.bluez.Battery1 property and publishes each peripheral as a device whose
// NativePath is the BlueZ object path, so one local D-Bus call covers every device
// that reports a level. BlueZ only exposes Battery1 on devices that support it, so
// "has a battery" needs no separate capability check: a peripheral without one simply
// never appears in the list.
//
// Only connected peripherals are listed. The script checks BlueZ's Connected property
// explicitly rather than assuming UPower has already dropped the device.
//
// The module hides entirely when nothing with a battery is connected, so a laptop used
// without earbuds does not carry an empty pill.
Rectangle {
    id: root

    // One entry per connected peripheral: { name, percent, path }
    property var devices: []
    property bool hovered: false

    readonly property bool any: root.devices.length > 0

    // The pill reports the lowest level, because that is the device about to die. With
    // two earbuds or a mouse and headset connected at once, the urgent one wins.
    readonly property var lowest: {
        if (root.devices.length === 0)
            return null;

        let low = root.devices[0];
        for (let i = 1; i < root.devices.length; i++) {
            if (root.devices[i].percent < low.percent)
                low = root.devices[i];
        }
        return low;
    }

    // Same escalation as the other system pills: warm, then the danger colour.
    readonly property real warnAt: 20
    readonly property real hotAt: 10
    readonly property color batteryColor: {
        if (root.lowest === null)
            return Theme.inkFaint;

        if (root.lowest.percent <= root.hotAt)
            return Theme.danger;

        if (root.lowest.percent <= root.warnAt)
            return "#f9e2af";

        return Theme.ink;
    }

    function parse(text) {
        const trimmed = text.trim();
        if (trimmed === "")
            return ;

        let data;
        try {
            data = JSON.parse(trimmed);
        } catch (e) {
            return ;
        }

        if (Array.isArray(data))
            root.devices = data;

    }

    visible: root.any
    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.bodyMid : Theme.bodyLow
    border.color: pillMouse.containsMouse ? Theme.accent : Theme.bodyMid
    border.width: Theme.borderWidth

    // Polled every 10 s: earbud batteries move on a scale of minutes, and a D-Bus
    // round-trip per second would be wasted work.
    Process {
        id: sampler

        running: true
        command: ["sh", "-c", "while :; do " + Quickshell.env("HOME") + "/.config/quickshell/scripts/bt-battery.sh; sleep 10; done"]

        stdout: SplitParser {
            onRead: (line) => root.parse(line)
        }

    }

    RowLayout {
        id: pillLayout

        anchors.centerIn: parent
        spacing: 6

        Text {
            // Earbuds, not a battery icon: the pill answers "what is connected", and
            // the number beside it carries the level.
            text: "󱡏"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: root.batteryColor
        }

        Text {
            text: root.lowest !== null ? Math.round(root.lowest.percent) + "%" : "—"
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.batteryColor
        }

    }

    MouseArea {
        id: pillMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    // The list, pinned under the pill like the other bar cards.
    TooltipCard {
        id: btCard

        anchorItem: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        shown: root.hovered

        Item {
            implicitWidth: 200
            implicitHeight: btColumn.implicitHeight

            ColumnLayout {
                id: btColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰂯"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.inkFaint
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        font.bold: true
                        color: Theme.ink
                    }

                    Text {
                        text: root.devices.length
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.inkFaint
                    }

                }

                Repeater {
                    model: root.devices

                    delegate: ColumnLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "󱡏"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontSm
                                color: modelData.percent <= root.warnAt ? root.batteryColor : Theme.inkFaint
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                elide: Text.ElideRight
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontSm
                                color: Theme.ink
                            }

                            Text {
                                text: Math.round(modelData.percent) + "%"
                                font.family: "JetBrainsMono Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontSm
                                color: modelData.percent <= root.warnAt ? root.batteryColor : Theme.ink
                            }

                        }

                        // A thin level bar per device, so two earbuds compare at a glance.
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 3
                            radius: 1.5
                            color: Theme.bodyMid

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.percent / 100))
                                height: parent.height
                                radius: parent.radius
                                color: modelData.percent <= root.hotAt ? Theme.danger : (modelData.percent <= root.warnAt ? "#f9e2af" : Theme.accent)
                            }

                        }

                    }

                }

            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

}
