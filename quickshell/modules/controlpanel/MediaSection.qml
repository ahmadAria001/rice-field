import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets

Rectangle {
    id: root

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    visible: player !== null
    Layout.fillWidth: true
    implicitHeight: 74
    radius: Theme.radiusSm
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: Theme.borderWidth

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Album Art
        Rectangle {
            implicitWidth: 54
            implicitHeight: 54
            radius: Theme.radiusSm
            color: Theme.surface1
            clip: true

            IconImage {
                anchors.fill: parent
                source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                visible: source !== ""
            }

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontXl
                color: Theme.subtext0
                visible: !root.player || !root.player.trackArtUrl
            }

        }

        // Track Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: root.player && root.player.trackTitle ? root.player.trackTitle : "Unknown Title"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontMd
                font.bold: true
                color: Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.player && root.player.trackArtist ? root.player.trackArtist : (root.player && root.player.identity ? root.player.identity : "Media Player")
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                color: Theme.subtext0
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

        }

        // Playback Controls
        RowLayout {
            spacing: 6

            // Previous
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: prevMouse.containsMouse ? Theme.surface1 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontLg
                    color: root.player && root.player.canGoPrevious ? Theme.text : Theme.surface1
                }

                MouseArea {
                    id: prevMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player)
                            root.player.previous();

                    }
                }

            }

            // Play / Pause
            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: playMouse.containsMouse ? Theme.mauve : Theme.surface1

                Text {
                    anchors.centerIn: parent
                    text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontLg
                    color: playMouse.containsMouse ? Theme.mantle : Theme.text
                }

                MouseArea {
                    id: playMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player)
                            root.player.togglePlaying();

                    }
                }

            }

            // Next
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: nextMouse.containsMouse ? Theme.surface1 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontLg
                    color: root.player && root.player.canGoNext ? Theme.text : Theme.surface1
                }

                MouseArea {
                    id: nextMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player)
                            root.player.next();

                    }
                }

            }

        }

    }

}
