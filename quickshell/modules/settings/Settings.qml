import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Settings, on the same material as every other surface. One page for now --
// motion -- because the shell already had a motion switch that nothing could
// reach: motion.json existed, PaletteLoader read it, and the only way to change
// it was to edit the file by hand and wait for the watcher.
//
// The panel does not touch Theme directly. It writes motion.json, which
// PaletteLoader is already watching, so the change lands the same way a hand
// edit does -- one code path, and the file stays the source of truth.
//
//   qs ipc call settings toggle      (bound to SUPER + comma)
PanelWindow {
    id: root

    property bool shown: false
    readonly property bool onScreen: shown || card.opacity > 0.001
    // Where the switch writes. Overridable so the panel can be exercised without
    // editing the live setting.
    property string motionPath: Quickshell.shellDir + "/motion.json"

    // Bound to the live value until the user changes it here; after that the
    // panel is showing what it wrote, which is the same number.
    property real scale: Theme.motionScale
    readonly property bool motionOn: root.scale > 0.001
    // The slider's own range. Below 0.5 the shell reads as broken rather than
    // calm, and above 1.5 it reads as a different design.
    readonly property real speedMin: 0.5
    readonly property real speedMax: 1.5
    readonly property real speed: root.motionOn ? Math.max(root.speedMin, Math.min(root.speedMax, root.scale)) : 1.0

    // Written as {"scale": n} and never as {"enabled": ...}: PaletteLoader
    // prefers `enabled` when both keys are present, so writing both would make
    // the slider a no-op. The first write drops `enabled` from the file.
    function apply(value) {
        root.scale = value;
        try {
            motionFile.setText(JSON.stringify({ scale: value }, null, 2) + "\n");
        } catch (e) {
            console.warn("Failed to save motion.json:", e);
        }
    }

    function open() {
        root.scale = Theme.motionScale;
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    visible: onScreen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings"
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

        target: "settings"
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.close()
    }

    FileView {
        id: motionFile

        path: root.motionPath
        blockLoading: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.edge.r, Theme.edge.g, Theme.edge.b, 0.5)
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.shown ? Theme.animNormal : Theme.animExit
                    easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
                }

            }

        }

    }

    Rectangle {
        id: card

        width: 420
        anchors.centerIn: parent
        implicitHeight: body.implicitHeight + 40
        color: Theme.bodyMid
        radius: Theme.radiusLg
        border.color: Theme.rim
        border.width: Theme.borderWidth
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.scaleDown

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

        ScanReveal {
            anchors.fill: parent
            active: root.shown
            z: 100
        }

        ColumnLayout {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 16

            Text {
                text: "Settings"
                color: Theme.ink
                font.pixelSize: Theme.fontXl
                font.bold: true
            }

            // Section rule, the same way the cards mark a change of subject.
            HairBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                height: 1
                radius: 0
                opacity: 0.5
                fadeTo: "end"
            }

            Text {
                // The mono header, as on a notification: it reads as a label on a
                // panel rather than as body copy.
                text: "MOTION"
                color: Theme.inkFaint
                font.family: "monospace"
                font.pixelSize: Theme.fontSm
                font.letterSpacing: 1.2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Reduce motion"
                        color: Theme.ink
                        font.pixelSize: Theme.fontMd
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.motionOn ? "Scans, arrivals and the hairline are running." : "Everything settles instantly."
                        color: Theme.inkFaint
                        font.pixelSize: Theme.fontSm
                        wrapMode: Text.WordWrap
                    }

                }

                Toggle {
                    on: root.motionOn
                    onToggled: root.apply(root.motionOn ? 0 : root.speed)
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8
                opacity: root.motionOn ? 1 : 0.4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Speed"
                        color: Theme.ink
                        font.pixelSize: Theme.fontMd
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.motionOn ? root.speed.toFixed(2) + "x" : "off"
                        color: Theme.inkFaint
                        font.family: "monospace"
                        font.pixelSize: Theme.fontSm
                    }

                }

                SpeedSlider {
                    Layout.fillWidth: true
                    enabled: root.motionOn
                    value: root.speed
                    from: root.speedMin
                    to: root.speedMax
                    onMoved: (v) => root.apply(v)
                }

            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Writes motion.json. Takes effect immediately."
                color: Theme.inkFaint
                font.pixelSize: Theme.fontSm
                opacity: 0.8
            }

        }

    }

    component Toggle: Rectangle {
        id: sw

        required property bool on
        signal toggled()

        implicitWidth: 38
        implicitHeight: 20
        radius: 10
        color: sw.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) : Theme.bodyLow
        border.color: sw.on ? Theme.accent : Theme.rim
        border.width: Theme.borderWidth

        Rectangle {
            width: 14
            height: 14
            radius: 7
            y: (parent.height - height) / 2
            x: sw.on ? parent.width - width - 3 : 3
            color: sw.on ? Theme.accent : Theme.inkFaint

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Theme.easeEntrance
                }

            }

        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.toggled()
        }

    }

    // A slider whose filled track is the hairline itself -- which is what
    // HairBar's own header says it is for, and the reason `progress` had to
    // become a real clip rather than a shifted gradient.
    component SpeedSlider: Item {
        id: sl

        property real value: 1
        property real from: 0.5
        property real to: 1.5
        signal moved(real v)

        implicitHeight: 22

        function valueAt(px) {
            return sl.from + Math.max(0, Math.min(1, px / sl.width)) * (sl.to - sl.from);
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.bodyLow
            border.color: Theme.rim
            border.width: Theme.borderWidth
        }

        HairBar {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            opacity: sl.enabled ? 0.9 : 0.4
            progress: (sl.value - sl.from) / (sl.to - sl.from)
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(sl.width - width, (sl.value - sl.from) / (sl.to - sl.from) * sl.width - width / 2))
            color: sl.enabled ? Theme.accent : Theme.inkFaint
            border.color: Theme.bodyMid
            border.width: 2
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: sl.enabled
            onPressed: (mouse) => sl.moved(sl.valueAt(mouse.x))
            onPositionChanged: (mouse) => {
                if (pressed)
                    sl.moved(sl.valueAt(mouse.x));

            }
        }

    }

}