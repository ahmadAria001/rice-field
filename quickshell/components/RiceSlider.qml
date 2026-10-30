import "../theme"
import QtQuick
import QtQuick.Controls

// The shell's slider. Volume, brightness and the motion speed all use this, so a
// slider looks the same wherever it appears -- the same premise as the card
// surface, applied to the one control that had been hand-rolled three times.
//
// The value sits inside the filled track rather than beside it: the track is
// already wide enough for it, and a separate label makes the row taller than the
// button sitting next to it.
Slider {
    id: root

    // Appended to the rounded value unless `valueText` overrides it.
    property string suffix: "%"
    // A caller can tint the fill -- mute greys the volume track out.
    property color fillColor: Theme.accent
    property string valueText: Math.round(root.value) + root.suffix

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 28
        width: root.availableWidth
        height: implicitHeight
        radius: Theme.radiusSm
        color: Theme.bodyMid

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: root.fillColor
            radius: Theme.radiusSm
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.valueText
            font.family: "sans-serif"
            font.pixelSize: Theme.fontSm
            font.bold: true
            color: Theme.ink
        }

    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 12
        implicitHeight: 28
        radius: 4
        color: Theme.ink
        visible: root.pressed
    }

}