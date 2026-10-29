import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ColumnLayout {
    id: root

    property var allWallpapers: []
    property string activeWallpaper: ""
    property string searchText: ""
    readonly property var filteredWallpapers: {
        if (!searchText || searchText.trim() === "")
            return allWallpapers;

        var query = searchText.trim().toLowerCase();
        return allWallpapers.filter(function(item) {
            return item.name.toLowerCase().indexOf(query) !== -1;
        });
    }

    function loadWallpapers() {
        listProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh", "list"]);
        getProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh", "get"]);
    }

    spacing: 12
    Layout.fillWidth: true
    Timer {
        id: deferLoadTimer
        interval: Theme.animNormal
        repeat: false
        onTriggered: root.loadWallpapers()
    }

    Component.onCompleted: {
        deferLoadTimer.start();
    }
    onVisibleChanged: {
        if (visible)
            deferLoadTimer.restart();
        else
            deferLoadTimer.stop();
    }

    Process {
        id: listProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text.trim());
                    if (Array.isArray(parsed))
                        root.allWallpapers = parsed;

                } catch (e) {
                }
            }
        }

    }

    Process {
        id: getProc

        stdout: StdioCollector {
            onStreamFinished: {
                var line = this.text.trim();
                if (line.length > 0)
                    root.activeWallpaper = line;

            }
        }

    }

    Process {
        id: setProc
    }

    Process {
        id: paletteProc
    }

    // Top Search & Count Bar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: Theme.radiusSm
            color: Theme.bodyMid
            border.color: searchInput.activeFocus ? Theme.accent : Theme.bodyTop
            border.width: Theme.borderWidth

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    text: "󰍉"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontMd
                    color: Theme.inkFaint
                }

                TextInput {
                    id: searchInput

                    Layout.fillWidth: true
                    color: Theme.ink
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontSm
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bodyLow
                    clip: true
                    onTextChanged: {
                        root.searchText = text;
                    }

                    Text {
                        anchors.fill: parent
                        text: "Search wallpapers..."
                        font: searchInput.font
                        color: Theme.inkFaint
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                }

                Text {
                    visible: searchInput.text.length > 0
                    text: "󰅖"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontMd
                    color: clearMouse.containsMouse ? Theme.danger : Theme.inkFaint

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchText = "";
                        }
                    }

                }

            }

        }

        // Refresh Button
        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.radiusSm
            color: refreshMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid
            border.color: Theme.bodyTop
            border.width: Theme.borderWidth

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: Theme.accent
            }

            MouseArea {
                id: refreshMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.loadWallpapers()
            }

        }

    }

    // Wallpapers Scrollable Grid
    ScrollView {
        id: scrollArea

        Layout.fillWidth: true
        Layout.preferredHeight: 360
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Flow {
            width: scrollArea.availableWidth
            spacing: 10

            Repeater {
                model: root.filteredWallpapers

                delegate: ClippingRectangle {
                    id: card

                    readonly property bool isCurrent: root.activeWallpaper === modelData.path
                    readonly property real cardWidth: Math.floor((scrollArea.availableWidth - 10) / 2)

                    width: cardWidth
                    height: Math.floor(cardWidth * 0.62)
                    radius: Theme.radiusSm
                    color: Theme.bodyMid
                    border.width: isCurrent ? 2 : (cardMouse.containsMouse ? 2 : 1)
                    border.color: isCurrent ? Theme.accent : (cardMouse.containsMouse ? Theme.inkFaint : Theme.bodyTop)

                    Image {
                        anchors.fill: parent
                        source: "file://" + (modelData.thumb ? modelData.thumb : modelData.path)
                        sourceSize.width: card.width
                        sourceSize.height: card.height
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                    }

                    // Bottom info gradient
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 24
                        color: "#cc181825"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font, sans-serif"
                                font.pixelSize: 10
                                color: card.isCurrent ? Theme.accent : Theme.ink
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                        }

                    }

                    // Active badge
                    Rectangle {
                        visible: card.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "󰄴"
                            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                            font.pixelSize: 12
                            color: Theme.bodyLow
                        }

                    }

                    MouseArea {
                        id: cardMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeWallpaper = modelData.path;
                            setProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh", "set", modelData.path]);
                            paletteProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/palette.sh", modelData.path]);
                        }
                    }

                }

            }

        }

    }

    // Empty state
    Text {
        visible: root.filteredWallpapers.length === 0
        Layout.alignment: Qt.AlignHCenter
        text: root.allWallpapers.length === 0 ? "No wallpapers in ~/Pictures/Wallpapers" : "No matches found"
        font.family: "JetBrainsMono Nerd Font, sans-serif"
        font.pixelSize: Theme.fontSm
        color: Theme.inkFaint
    }

}
