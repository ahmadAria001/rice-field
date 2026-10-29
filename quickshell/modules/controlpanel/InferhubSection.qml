import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property bool isAvailable: false
    property string balanceStr: "$0.00"
    property string spendStr: "$0.00"
    property real balanceVal: 0.0
    property real spendVal: 0.0
    property bool isRefreshing: false

    function refreshUsage() {
        if (isRefreshing) return;
        isRefreshing = true;
        fetchProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/pakai_inferhub.sh", "status"]);
    }

    function forceRefresh() {
        if (isRefreshing) return;
        isRefreshing = true;
        fetchProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/pakai_inferhub.sh", "refresh"]);
    }

    Layout.fillWidth: true
    implicitHeight: 68
    radius: Theme.radiusSm
    color: Theme.bodyMid
    border.color: Theme.bodyTop
    border.width: Theme.borderWidth

    Component.onCompleted: {
        refreshUsage();
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshUsage()
    }

    Process {
        id: fetchProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.isRefreshing = false;
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data && data.available) {
                        root.isAvailable = true;
                        root.balanceStr = data.balance_str || ("$" + Number(data.balance).toFixed(3));
                        root.spendStr = data.spend30d_str || ("$" + Number(data.spend30d).toFixed(3));
                        root.balanceVal = Number(data.balance) || 0.0;
                        root.spendVal = Number(data.spend30d) || 0.0;
                    } else {
                        root.isAvailable = false;
                    }
                } catch (e) {
                    root.isAvailable = false;
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Icon badge with subtle surface background
        Rectangle {
            implicitWidth: 46
            implicitHeight: 46
            radius: Theme.radiusSm
            color: Theme.bodyTop
            clip: true

            Image {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: "../../assets/inferhub.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }

        // Details Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6
                Text {
                    text: "InferHub AI"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                    color: Theme.ink
                }

                // Active status dot
                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: root.isAvailable ? "#a6e3a1" : Theme.inkFaint
                }
            }

            // Metrics row: Balance & 30d Spend
            RowLayout {
                spacing: 12

                RowLayout {
                    spacing: 4
                    Text {
                        text: "Bal:"
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: 11
                        color: Theme.inkFaint
                    }
                    Text {
                        text: root.balanceStr
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                    }
                }

                Text {
                    text: "•"
                    font.family: "sans-serif"
                    font.pixelSize: 10
                    color: Theme.bodyTop
                }

                RowLayout {
                    spacing: 4
                    Text {
                        text: "30d:"
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: 11
                        color: Theme.inkFaint
                    }
                    Text {
                        text: root.spendStr
                        font.family: "JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: 11
                        color: Theme.ink
                    }
                }
            }
        }

        // Refresh Button
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSm
            color: refreshMouse.containsMouse ? Theme.bodyTop : "transparent"
            border.color: refreshMouse.containsMouse ? Theme.bodyTop : "transparent"
            border.width: Theme.borderWidth
            ToolTip.visible: refreshMouse.containsMouse
            ToolTip.text: "Refresh InferHub balance"
            ToolTip.delay: 300

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontMd
                color: root.isRefreshing ? Theme.accent : Theme.inkFaint
                rotation: root.isRefreshing ? 360 : 0
                Behavior on rotation {
                    NumberAnimation { duration: 600; loops: Animation.Infinite }
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forceRefresh()
            }
        }
    }
}
