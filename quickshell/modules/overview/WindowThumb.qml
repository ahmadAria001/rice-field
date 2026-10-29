import "../../theme"
import QtQuick
import Quickshell.Wayland

// One window inside a workspace miniature. Position and size come from the client's
// own geometry, scaled by the card, so the preview reproduces the tiling instead of
// stacking every window into an equal box.
Item {
    id: root

    // Not `required`: a required binding is evaluated at creation, before the inner
    // Repeater's delegate context is attached, so `toplevel: modelData` would resolve
    // against the outer Repeater (the workspace id) instead of the window.
    property var toplevel: null
    property real scaleFactor: 1
    property bool selected: false
    property bool captureEnabled: false

    signal activated()

    readonly property var ipc: root.toplevel ? root.toplevel.lastIpcObject : null
    // Hyprland reports `at` in global layout coordinates, so a window on the second
    // monitor starts at x >= 1280. The miniature is per-monitor, so the monitor's own
    // origin has to come off or those windows land outside their card.
    readonly property var mon: root.toplevel ? root.toplevel.monitor : null
    readonly property int winX: ((ipc && ipc.at) ? ipc.at[0] : 0) - ((root.mon && root.mon.x) ? root.mon.x : 0)
    readonly property int winY: ((ipc && ipc.at) ? ipc.at[1] : 0) - ((root.mon && root.mon.y) ? root.mon.y : 0)
    readonly property int winW: (ipc && ipc.size) ? ipc.size[0] : 16
    readonly property int winH: (ipc && ipc.size) ? ipc.size[1] : 9

    readonly property string windowTitle: root.toplevel ? (root.toplevel.title || "") : ""

    x: Math.round(root.winX * root.scaleFactor)
    y: Math.round(root.winY * root.scaleFactor)
    width: Math.max(3, Math.round(root.winW * root.scaleFactor))
    height: Math.max(3, Math.round(root.winH * root.scaleFactor))

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Theme.base
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Theme.accentMauve : Theme.surface0
        clip: true

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animFast
                easing.type: Theme.easeGeneral
            }

        }

        ScreencopyView {
            id: view

            anchors.fill: parent
            // Gated on captureEnabled, not just `live`: ScreencopyView builds its capture
            // context as soon as a source is set, and one created while the overlay is
            // hidden fails ("Ending recording due to screencopy failure") and never
            // recovers when the overlay opens later.
            captureSource: (root.captureEnabled && root.toplevel && root.toplevel.wayland) ? root.toplevel.wayland : null
            // `live: false` only renders after an explicit captureFrame(); gating on
            // captureEnabled keeps a hidden overview from capturing continuously.
            live: root.captureEnabled
            paintCursor: false
            constraintSize: Qt.size(width, height)
            visible: hasContent && root.captureEnabled
        }

        // Placeholder while the frame is in flight, or when the compositor will not
        // export the window.
        Text {
            anchors.centerIn: parent
            visible: !view.hasContent
            text: "󰖯"
            font.family: "MesloLGS Nerd Font"
            font.pixelSize: Math.min(18, root.height * 0.35)
            color: Theme.surface1
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: titleLabel.implicitHeight + 6
            visible: titleLabel.visible

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "transparent"
                }

                GradientStop {
                    position: 1
                    color: Qt.rgba(0.06, 0.06, 0.08, 0.9)
                }

            }

        }

        Text {
            id: titleLabel

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            // Below this width the label is unreadable and just muddies the tile.
            visible: root.width > 88 && root.height > 30
            text: root.windowTitle
            color: Theme.subtext1
            font.family: "Inter"
            font.pixelSize: 9
            elide: Text.ElideRight
            maximumLineCount: 1
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: root.selected = true
        onExited: root.selected = false
        onClicked: root.activated()
    }

}