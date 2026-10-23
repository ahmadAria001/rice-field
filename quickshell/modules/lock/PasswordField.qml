// Password entry for the lock screen.
// The real TextInput is always enabled, always visible to the focus system, and
// always holds keyboard focus, but draws nothing. The visible dots are painted by
// this component. That keeps rendering fully on-language while input handling stays
// with a real text input.
// Focus is deliberately not gated on the revealed state: an item that is invisible
// or disabled cannot take keyboard focus, so gating it makes typing silently do
// nothing until the field has been clicked.

import "../../theme"
import QtQuick

Item {
    id: root

    property alias text: input.text
    property string placeholder: "Enter password"
    property string message: ""
    property bool messageIsError: false
    property bool busy: false
    // True while the caret should be drawn. Follows the real input focus.
    readonly property bool focused: input.activeFocus

    signal submitted(string value)

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    implicitWidth: 320
    implicitHeight: 46

    Rectangle {
        id: field

        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.mantle
        border.color: root.focused ? Theme.accentMauve : Theme.surface0
        border.width: root.focused ? 2 : Theme.borderWidth

        // Caret indicator: a soft accent bar that breathes while the field is active.
        Rectangle {
            id: caret

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: root.focused
            width: 2
            height: 18
            radius: 1
            color: Theme.accentMauve

            SequentialAnimation on opacity {
                running: root.focused
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.25
                    duration: 700
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    to: 1
                    duration: 700
                    easing.type: Easing.InOutQuad
                }

            }

        }

        Text {
            anchors.left: caret.right
            anchors.leftMargin: 8
            // Bounded to the field: an unbounded Text takes its implicit width and paints
            // outside the box when the placeholder is long.
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: root.placeholder
            elide: Text.ElideRight
            font.family: "sans-serif"
            font.pixelSize: Theme.fontMd
            color: Theme.subtext0
        }

        // One dot per typed character, inside a clipped viewport so a long password
        // cannot paint outside the field. A Row takes the natural width of its dots, so
        // without a bound it grew past the field. The row shifts left once it no longer
        // fits, which keeps the newest dots visible.
        Item {
            id: dotsViewport

            anchors.left: caret.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            height: 10
            clip: true
            visible: input.text.length > 0

            Row {
                id: dotsRow

                x: Math.min(0, dotsViewport.width - width)
                y: (dotsViewport.height - height) / 2
                spacing: 7

                Repeater {
                    model: input.text.length

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.accentPink
                    }

                }

            }

        }

        // Busy shimmer while PAM is working.
        Rectangle {
            anchors.fill: parent
            radius: field.radius
            color: Theme.accentMauve
            opacity: 0
            visible: root.busy

            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.07
                    duration: 600
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    to: 0.02
                    duration: 600
                    easing.type: Easing.InOutQuad
                }

            }

        }

        // The real input. Always enabled and focused; renders nothing so this
        // component controls every visible pixel.
        TextInput {
            id: input

            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            passwordCharacter: " "
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorVisible: false
            activeFocusOnTab: true
            focus: true
            font.pixelSize: Theme.fontMd
            onAccepted: root.submitted(input.text)
            onActiveFocusChanged: {
                // If focus is ever lost (for example after a reload), take it back.
                if (!activeFocus)
                    retakeTimer.restart();

            }
        }

        Timer {
            id: retakeTimer

            interval: 150
            onTriggered: {
                if (!input.activeFocus)
                    input.forceActiveFocus();

            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.focusInput()
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animFast
            }

        }

    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: field.bottom
        anchors.topMargin: 8
        // Bounded and wrapped: an unbounded Text takes its implicit width and paints
        // outside the component when the message is long. Wrapped rather than elided so
        // an error stays readable.
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.message
        visible: root.message !== ""
        font.family: "sans-serif"
        font.pixelSize: Theme.fontSm
        color: root.messageIsError ? Theme.red : Theme.subtext0
    }

}
