import "../theme"
import QtQuick
import QtQuick.Layouts

// The rice's shared card surface. Used by bar tooltips and by the lock screen so
// both share one visual language.
//
// ===== Lacia =====
// bodyMid fill with a rim edge, not the old mantle-fill-plus-surface0-border.
// The pair matters: bodyMid (#1B1F29) under rim (#3A4152) is a 1.61:1 step, which
// reads as a moulded edge catching light. The old mantle/surface0 pair was a
// flat grey outline, which is why a card looked drawn on rather than raised.
//
// The 1px hairline of her gradient across the top is the card's only decoration,
// and it is the same gradient as everything else (components/HairBar.qml), so a
// card, a slider and the bar's active pill all read as the same material.
Rectangle {
    id: root

    default property alias content: inner.data
    // Optional accent ring, for focused or highlighted states.
    property bool accented: false
    // The hairline along the top edge. On by default; a card that already sits
    // inside a surface with its own rule can turn it off.
    property bool hairline: true

    radius: Theme.radiusMd
    color: Theme.bodyMid
    border.color: accented ? Theme.accent : Theme.rim
    border.width: Theme.borderWidth
    implicitWidth: inner.implicitWidth + 32
    implicitHeight: inner.implicitHeight + 32

    // Her gradient, held well down: a seam of light along the top edge, not a
    // coloured bar. At 0.45 the cyan stop read as a neon stripe across a card
    // that is otherwise all neutrals -- the hair is a signal, and a signal that
    // fires on every surface stops being one. 0.22 is a hint of warmth.
    HairBar {
        visible: root.hairline
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        anchors.topMargin: 1
        height: 1
        radius: 0
        opacity: 0.22
        fadeTo: "end"
    }

    // The content must be constrained to the card, or nothing inside it can be:
    // a Column only positions its children and never resizes them, so a child took its
    // own content width and painted outside the card. A ColumnLayout bound to the card
    // hands the available width down, which is what makes Layout.fillWidth and
    // Text.elide inside the content work.
    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: 16
        spacing: 6
    }

}
