import "../../theme"
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

// The lock screen for one screen. Created per monitor by WlSessionLock, so it reads
// the screen it lands on rather than assuming a resolution.
Item {
    id: root

    // Guarded rather than assumed: WlSessionLock instantiates this surface before the
    // binding lands, so unguarded reads log TypeErrors and can leave a binding broken.
    property var auth: null
    readonly property bool authReady: auth !== null && auth !== undefined
    // Wallpaper and avatar, both resolved from ~/Pictures/Wallpapers/.
    required property string wallpaperSource
    required property string avatarSource
    property string userName: authReady ? auth.userName : ""
    property string displayName: authReady ? auth.displayName : ""
    property bool revealed: false
    // Set during the unlock animation, so the surface can fade out before the
    // compositor drops the lock.
    property bool unlocking: false
    property bool ready: false

    // Clearing the field after a failure must not drop keyboard focus.
    function onAuthFailed() {
        field.clear();
        field.focusInput();
    }

    function reveal() {
        if (root.unlocking)
            return ;

        root.revealed = true;
        field.focusInput();
    }

    // Fade and settle in, so the lock does not appear as a hard cut.
    Component.onCompleted: {
        if (authReady)
            auth.failed.connect(onAuthFailed);

        ready = true;
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        layer.enabled: true

        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: -0.25
            brightness: -0.18
        }

    }

    // Scrim: deepens the corners and keeps text legible over any wallpaper.
    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(0.06, 0.06, 0.08, 0.72)
            }

            GradientStop {
                position: 0.45
                color: Qt.rgba(0.06, 0.06, 0.08, 0.55)
            }

            GradientStop {
                position: 1
                color: Qt.rgba(0.06, 0.06, 0.08, 0.82)
            }

        }

    }

    // Click anywhere to reveal and focus the field.
    MouseArea {
        anchors.fill: parent
        onClicked: root.reveal()
    }

    // Fallback for the case where the field's input does not hold focus: reveal on a
    // keypress without consuming it. Normally the TextInput owns focus, so this never
    // fires, and no keystroke is ever swallowed.
    Item {
        anchors.fill: parent
        Keys.onPressed: (event) => {
            if (!root.revealed)
                root.reveal();

        }
    }

    Item {
        id: stage

        anchors.fill: parent
        // Unlock animation: the content lifts and dissolves as the session is handed
        // back. Opacity leads, the transform follows, which reads as a release rather
        // than a plain fade. Kept under the release timer in LockScreen so the
        // animation always finishes before the compositor drops the lock.
        opacity: root.unlocking ? 0 : (root.ready ? 1 : 0)
        scale: root.unlocking ? 1.06 : 1
        y: root.unlocking ? -16 : 0
        // A soft defocus while unlocking, so the fade feels like dissolving into the
        // wallpaper instead of a hard dim. Only enabled during the unlock.
        layer.enabled: root.unlocking

        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -24
            spacing: 18
            width: Math.min(root.width - 64, 460)

            Avatar {
                Layout.alignment: Qt.AlignHCenter
                size: 104
                source: root.avatarSource
                name: root.userName
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.displayName
                    font.family: "sans-serif"
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.text
                }

                Text {
                    id: hint

                    Layout.alignment: Qt.AlignHCenter
                    // The text stays put and only its opacity animates. Swapping the
                    // string for "" would collapse the item's height mid-reveal and
                    // shift the clock and field upward.
                    text: "click or type to unlock"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                    opacity: root.revealed ? 0 : 0.75

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animNormal
                            easing.type: root.revealed ? Theme.easeExit : Theme.easeEntrance
                        }

                    }

                }

            }

            // Clock + date
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 0

                Text {
                    id: clock

                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(new Date(), "hh:mm")
                    font.family: "sans-serif"
                    font.pixelSize: 84
                    font.weight: Font.Light
                    color: Theme.text
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.35)

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
                    }

                }

                Text {
                    id: dateText

                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                    font.family: "sans-serif"
                    font.pixelSize: 15
                    color: Theme.subtext1
                    opacity: 0.9

                    Timer {
                        interval: 30000
                        running: true
                        repeat: true
                        onTriggered: dateText.text = Qt.formatDateTime(new Date(), "dddd, d MMMM")
                    }

                }

            }

            // Password field: fades in, rising slightly into place.
            PasswordField {
                id: field

                Layout.alignment: Qt.AlignHCenter
                // A fixed layout slot. The rise is the transform below rather than an
                // animated margin: a margin animation changes the column's total height,
                // so centering dragged the avatar, name and clock along with the field.
                // Measured before this change: the clock drifted 12px down on reveal.
                Layout.topMargin: 22
                Layout.preferredWidth: 320
                placeholder: "Enter password"
                message: root.authReady ? root.auth.message : ""
                messageIsError: root.authReady ? root.auth.messageIsError : false
                busy: root.authReady ? root.auth.busy : false
                // Never `visible: false` or `enabled: false` here: either one makes the
                // inner TextInput unable to hold keyboard focus, which silently breaks
                // typing. The reveal is expressed purely through opacity, scale and the
                // transform below.
                opacity: root.revealed ? 1 : 0
                // A hair of scale so the field settles into place instead of just
                // appearing.
                scale: root.revealed ? 1 : 0.985
                // Layout-neutral rise: only the field moves, so nothing above it shifts.
                // Eased with the same curve as the opacity, so the field reads as rising
                // into place as it appears rather than snapping and settling.
                transform: Translate {
                    y: root.revealed ? 0 : 10

                    Behavior on y {
                        NumberAnimation {
                            duration: Theme.animView
                            easing.type: Theme.easeEntrance
                        }

                    }

                }
                onSubmitted: (value) => {
                    if (!root.authReady)
                        return ;

                    root.auth.clearMessage();
                    root.auth.submit(value);
                }
                onTextChanged: {
                    if (text.length > 0) {
                        // Typing alone reveals and unlocks, with no click needed.
                        if (!root.revealed)
                            root.reveal();

                        if (root.authReady)
                            root.auth.clearMessage();

                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animSlow
                        easing.type: Theme.easeEntrance
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animView
                        easing.type: Theme.easeEntrance
                    }

                }

            }

            // Media controls: only rendered when something is playing.
            MediaControls {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
            }

        }

        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.3
            blurMax: 32
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.unlocking ? 360 : 520
                easing.type: root.unlocking ? Theme.easeExit : Theme.easeEntrance
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: root.unlocking ? 440 : 520
                easing.type: root.unlocking ? Theme.easeExit : Theme.easeEntrance
            }

        }

        Behavior on y {
            NumberAnimation {
                duration: root.unlocking ? 440 : 520
                easing.type: root.unlocking ? Theme.easeExit : Theme.easeEntrance
            }

        }

    }

    StatusRow {
        id: statusRow

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        opacity: root.unlocking ? 0 : (root.ready ? 1 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: root.unlocking ? 360 : 520
                easing.type: root.unlocking ? Theme.easeExit : Theme.easeEntrance
            }

        }

    }

}
