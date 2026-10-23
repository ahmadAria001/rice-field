// Hover detail card for bar items. A PopupWindow pinned a fixed distance below its
// anchor item, so it neither follows the cursor nor covers the item's click area.

import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell

// For a one-line label set `text`. For richer content leave `text` empty and declare
// children instead; they are laid out in a column inside the card.
PopupWindow {
    id: root

    // The bar item the card hangs under.
    required property Item anchorItem
    // Drives visibility; bind it to the item's hover state.
    property bool shown: false
    // Convenience label. Ignored when children are declared.
    property string text: ""
    default property alias content: contentLayout.data

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // Margins inset the anchor rect, so a negative bottom margin is what pushes the
    // card's top edge below the item instead of moving the rect's top.
    anchor.margins.bottom: -10
    color: "transparent"
    implicitWidth: cardBox.implicitWidth
    implicitHeight: cardBox.implicitHeight
    visible: shown || cardBox.opacity > 0.001
    onVisibleChanged: {
        if (visible)
            root.anchor.updateAnchor();

    }

    // The anchor rect is captured when the popup is positioned, so refresh it if the
    // item moves or resizes while the card is open.
    Connections {
        function onWidthChanged() {
            if (root.visible)
                root.anchor.updateAnchor();

        }

        target: root.anchorItem
    }

    Rectangle {
        id: cardBox

        color: Theme.mantle
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusMd
        implicitWidth: Math.max(120, contentLayout.implicitWidth + 16)
        implicitHeight: contentLayout.implicitHeight + 16
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.scaleDown
        transformOrigin: Item.Top

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Loader {
                active: root.text !== ""
                visible: active
                sourceComponent: labelComponent
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? Theme.animFast : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: root.shown ? Theme.animFast : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }

        }

    }

    Component {
        id: labelComponent

        Text {
            text: root.text
            font.family: "sans-serif"
            font.pixelSize: Theme.fontSm
            color: Theme.text
        }

    }

}
