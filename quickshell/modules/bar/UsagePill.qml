import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property bool isAvailable: false
    property string balanceStr: "$0.00"
    property string spendStr: "$0.00"
    property bool isRefreshing: false
    property bool hovered: false

    function refreshUsage(force) {
        if (isRefreshing)
            return ;

        isRefreshing = true;
        fetchProc.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/pakai_inferhub.sh", force ? "refresh" : "status"]);
    }

    implicitHeight: 28
    implicitWidth: pillLayout.implicitWidth + 16
    radius: Theme.radiusSm
    color: pillMouse.containsMouse ? Theme.surface0 : Theme.mantle
    border.color: pillMouse.containsMouse ? Theme.mauve : Theme.surface0
    border.width: Theme.borderWidth
    Component.onCompleted: {
        refreshUsage(false);
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshUsage(false)
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
        id: pillLayout

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󱂛"
            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
            font.pixelSize: Theme.fontMd
            color: root.isAvailable ? Theme.mauve : Theme.subtext0
        }

        Text {
            text: root.isAvailable ? root.balanceStr : "—"
            font.family: "JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: Theme.fontSm
            color: root.isAvailable ? Theme.text : Theme.subtext0
        }

    }

    MouseArea {
        id: pillMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.refreshUsage(true)
    }

    // Detail card pinned a fixed 10px under the pill, so it neither follows the
    // cursor nor overlaps the pill's click target.
    TooltipCard {
        id: usageCard

        anchorItem: root
        // The card grows leftwards from the pill's bottom-left so it stays on screen
        // at the right end of the bar.
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        shown: root.hovered

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "󱂛"
                font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                font.pixelSize: Theme.fontSm
                color: root.isAvailable ? Theme.mauve : Theme.subtext0
            }

            Text {
                Layout.fillWidth: true
                text: "InferHub"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                font.bold: true
                color: Theme.text
            }

            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: root.isAvailable ? "#a6e3a1" : Theme.subtext0
            }

        }

        RowLayout {
            spacing: 12

            RowLayout {
                spacing: 4

                Text {
                    text: "Bal:"
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                }

                Text {
                    text: root.isAvailable ? root.balanceStr : "—"
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                    color: Theme.mauve
                }

            }

            Text {
                text: "•"
                font.family: "sans-serif"
                font.pixelSize: Theme.fontSm
                color: Theme.surface1
            }

            RowLayout {
                spacing: 4

                Text {
                    text: "30d:"
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext0
                }

                Text {
                    text: root.isAvailable ? root.spendStr : "—"
                    font.family: "JetBrainsMono Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontSm
                    color: Theme.text
                }

            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animFast
        }

    }

}
