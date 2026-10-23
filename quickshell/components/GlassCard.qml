import "../theme"
import QtQuick
import QtQuick.Layouts

// The rice's shared card surface: Theme.mantle fill, Theme.surface0 border,
// radiusMd corners. Used by bar tooltips and by the lock screen so both share one
// visual language.
Rectangle {
    id: root

    default property alias content: inner.data
    // Optional accent ring, for focused or highlighted states.
    property bool accented: false

    radius: Theme.radiusMd
    color: Theme.mantle
    border.color: accented ? Theme.accentMauve : Theme.surface0
    border.width: Theme.borderWidth
    implicitWidth: inner.implicitWidth + 32
    implicitHeight: inner.implicitHeight + 32

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
