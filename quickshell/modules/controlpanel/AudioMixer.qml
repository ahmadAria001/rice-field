import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root

    readonly property var sinkNodes: {
        if (!Pipewire.nodes || !Pipewire.nodes.values)
            return [];

        return Pipewire.nodes.values.filter((n) => {
            return n && n.isSink && !n.isStream;
        });
    }
    readonly property var streamNodes: {
        if (!Pipewire.nodes || !Pipewire.nodes.values)
            return [];

        return Pipewire.nodes.values.filter((n) => {
            return n && n.isSink && n.isStream && n.audio !== null && n.audio !== undefined;
        });
    }

    spacing: 12
    Layout.fillWidth: true

    Process {
        id: execProc
    }

    ScrollView {
        id: mixerScroll

        Layout.fillWidth: true
        Layout.maximumHeight: 380
        Layout.preferredHeight: Math.min(380, contentCol.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentCol

            width: mixerScroll.availableWidth
            spacing: 14

            // Section 1: Output Devices
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "OUTPUT DEVICES"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                    color: Theme.subtext0
                }

                Repeater {
                    model: root.sinkNodes

                    Rectangle {
                        id: sinkDelegate

                        required property var modelData
                        property bool isDefault: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Theme.radiusSm
                        color: isDefault ? Theme.surface1 : (sinkMouse.containsMouse ? Theme.surface0 : "transparent")
                        border.color: isDefault ? Theme.mauve : Theme.surface0
                        border.width: Theme.borderWidth

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: sinkDelegate.isDefault ? "󰄵" : "󰄱"
                                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                font.pixelSize: Theme.fontLg
                                color: sinkDelegate.isDefault ? Theme.mauve : Theme.subtext0
                            }

                            Text {
                                text: sinkDelegate.modelData.description || sinkDelegate.modelData.nickname || sinkDelegate.modelData.name
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontMd
                                font.bold: sinkDelegate.isDefault
                                color: Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                        }

                        MouseArea {
                            id: sinkMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Pipewire.preferredDefaultAudioSink = sinkDelegate.modelData;
                                execProc.exec(["wpctl", "set-default", sinkDelegate.modelData.id.toString()]);
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animFast
                            }

                        }

                    }

                }

            }

            // Section 2: Application Volume Streams
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "APPLICATION VOLUME"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                    color: Theme.subtext0
                }

                Text {
                    visible: root.streamNodes.length === 0
                    text: "No active audio streams"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: root.streamNodes

                    Rectangle {
                        id: streamDelegate

                        required property var modelData
                        property string appName: (modelData.properties && (modelData.properties["application.name"] || modelData.properties["app.name"])) || modelData.name
                        property bool isMuted: (modelData && modelData.audio !== null) ? modelData.audio.muted : false
                        property real volume: (modelData && modelData.audio !== null) ? modelData.audio.volume : 0

                        Layout.fillWidth: true
                        implicitHeight: 64
                        radius: Theme.radiusSm
                        color: Theme.surface0
                        border.color: Theme.surface1
                        border.width: Theme.borderWidth

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "󰎆"
                                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                    font.pixelSize: Theme.fontMd
                                    color: Theme.mauve
                                }

                                Text {
                                    text: streamDelegate.appName
                                    font.family: "sans-serif"
                                    font.pixelSize: Theme.fontSm
                                    font.bold: true
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: Math.round(streamDelegate.volume * 100) + "%"
                                    font.family: "sans-serif"
                                    font.pixelSize: Theme.fontSm
                                    color: Theme.subtext0
                                }

                                // Stream Mute Button
                                Rectangle {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 4
                                    color: streamMuteMouse.containsMouse ? Theme.surface1 : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: streamDelegate.isMuted ? "󰝟" : "󰕾"
                                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                        font.pixelSize: Theme.fontSm
                                        color: streamDelegate.isMuted ? Theme.red : Theme.text
                                    }

                                    MouseArea {
                                        id: streamMuteMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (streamDelegate.modelData && streamDelegate.modelData.audio !== null)
                                                streamDelegate.modelData.audio.muted = !streamDelegate.modelData.audio.muted;

                                        }
                                    }

                                }

                            }

                            Slider {
                                id: streamSlider

                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                value: streamDelegate.volume
                                onMoved: {
                                    if (streamDelegate.modelData && streamDelegate.modelData.audio !== null)
                                        streamDelegate.modelData.audio.volume = value;

                                }

                                Binding {
                                    target: streamSlider
                                    property: "value"
                                    value: streamDelegate.volume
                                    when: !streamSlider.pressed
                                }

                                background: Rectangle {
                                    x: streamSlider.leftPadding
                                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 8
                                    width: streamSlider.availableWidth
                                    height: implicitHeight
                                    radius: 4
                                    color: Theme.surface1

                                    Rectangle {
                                        width: streamSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: streamDelegate.isMuted ? Theme.subtext0 : Theme.mauve
                                        radius: 4
                                    }

                                }

                                handle: Rectangle {
                                    x: streamSlider.leftPadding + streamSlider.visualPosition * (streamSlider.availableWidth - width)
                                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    radius: 7
                                    color: Theme.text
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
