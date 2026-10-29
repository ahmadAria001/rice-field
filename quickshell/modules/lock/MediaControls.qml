import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Media controls for the lock screen. Hidden entirely until a player reports a
// track, so the lock screen stays quiet when nothing is playing.
GlassCard {
    id: root

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property bool hasTrack: player !== null && (player.trackTitle || "") !== ""

    visible: hasTrack
    opacity: hasTrack ? 1 : 0
    implicitWidth: 380

    RowLayout {
        // Fill the card so the middle column gets a bounded width. Without this the row
        // keeps its content width, the text column never narrows, and elide never runs.
        Layout.fillWidth: true
        spacing: 12

        // Album art, rounded to match the card language.
        Rectangle {
            implicitWidth: 52
            implicitHeight: 52
            radius: Theme.radiusSm
            color: Theme.bodyLow
            border.color: Theme.rim
            border.width: Theme.borderWidth
            clip: true

            IconImage {
                anchors.fill: parent
                source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                visible: source !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: !root.player || !root.player.trackArtUrl
                text: "󰎆"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: Theme.subtext0
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || "Unknown") : ""
                font.family: "sans-serif"
                font.pixelSize: Theme.fontMd
                font.bold: true
                color: Theme.text
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (!root.player)
                        return "";

                    const artist = root.player.trackArtist || "";
                    const album = root.player.trackAlbum || "";
                    if (artist !== "" && album !== "")
                        return artist + " · " + album;

                    return artist || album || root.player.identity || "";
                }
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                color: Theme.subtext0
                elide: Text.ElideRight
            }

        }

        RowLayout {
            spacing: 6

            MediaButton {
                glyph: "󰒮"
                enabledAction: root.player !== null && root.player.canGoPrevious
                onTriggered: root.player.previous()
            }

            MediaButton {
                glyph: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                enabledAction: root.player !== null
                tint: Theme.accent
                onTriggered: root.player.togglePlaying()
            }

            MediaButton {
                glyph: "󰒭"
                enabledAction: root.player !== null && root.player.canGoNext
                onTriggered: root.player.next()
            }

            component MediaButton: Rectangle {
                id: button

                required property string glyph
                required property bool enabledAction
                property color tint: Theme.text

                signal triggered()

                implicitWidth: 34
                implicitHeight: 34
                radius: 17
                color: buttonMouse.containsMouse && button.enabledAction ? Theme.bodyTop : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: button.glyph
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontXl
                    // Disabled is dim ink, not a surface token: bodyTop is a fill
                    // colour, and using it for text made a dead button look like a
                    // hovered one.
                    color: button.tint
                    opacity: button.enabledAction ? 1 : 0.35
                }

                MouseArea {
                    id: buttonMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (button.enabledAction)
                            button.triggered();

                    }
                }

            }

        }

    }

}
