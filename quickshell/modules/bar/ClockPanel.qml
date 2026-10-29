import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

// Click-through panel for the bar clock: month calendar plus whatever is playing.
// The clock was the only bar module with no click target, so this completes the bar's
// interaction grammar without adding a second place to look for time.
PopupWindow {
    id: root

    property Item anchorItem
    property bool shown: false
    // A plain `date` re-evaluates the "today" highlight when the day rolls over.
    property date today: new Date()
    property int viewYear: root.today.getFullYear()
    property int viewMonth: root.today.getMonth()

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property bool hasTrack: root.player !== null && (root.player.trackTitle || "") !== ""

    function open() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
        root.shown = true;
    }

    function close() {
        if (root.shown)
            root.shown = false;

    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    function shiftMonth(delta) {
        let m = root.viewMonth + delta;
        let y = root.viewYear;
        if (m < 0) {
            m = 11;
            y -= 1;
        } else if (m > 11) {
            m = 0;
            y += 1;
        }
        root.viewMonth = m;
        root.viewYear = y;
    }

    // Monday-first offset: JS getDay() is Sunday-based.
    function firstWeekdayMon(y, m) {
        return (new Date(y, m, 1).getDay() + 6) % 7;
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    // Leading zeros stand in for the blank cells before day 1; trailing zeros pad the
    // last week so the grid stays rectangular.
    readonly property var cells: {
        const y = root.viewYear;
        const m = root.viewMonth;
        const lead = root.firstWeekdayMon(y, m);
        const total = root.daysInMonth(y, m);
        const out = [];
        for (let i = 0; i < lead; i++)
            out.push(0);

        for (let d = 1; d <= total; d++)
            out.push(d);

        while (out.length % 7 !== 0)
            out.push(0);

        return out;
    }

    readonly property int cellWidth: 34
    readonly property int cellHeight: 30

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // Negative bottom margin pushes the card below the item rather than moving the
    // anchor rect's top edge, matching TooltipCard.
    anchor.margins.bottom: -10
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    visible: root.shown || card.opacity > 0.001

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.today = new Date()
    }

    HyprlandFocusGrab {
        active: root.backingWindowVisible && root.shown
        windows: [root]
        onCleared: root.close()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.close()
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        function open() {
            root.open();
        }

        function close() {
            root.close();
        }

        target: "clock"
    }

    Rectangle {
        id: card

        color: Theme.mantle
        border.color: Theme.surface0
        border.width: Theme.borderWidth
        radius: Theme.radiusMd
        implicitWidth: 292
        implicitHeight: content.implicitHeight + 28
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.scaleDown
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? Theme.animNormal : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: root.shown ? Theme.animNormal : Theme.animExit
                easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
            }

        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 11
                    color: prevMouse.containsMouse ? Theme.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: "MesloLGS Nerd Font"
                        font.pixelSize: 12
                        color: Theme.subtext0
                    }

                    MouseArea {
                        id: prevMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(-1)
                    }

                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                    color: Theme.text
                    font.family: "Inter"
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 11
                    color: nextMouse.containsMouse ? Theme.surface0 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: "MesloLGS Nerd Font"
                        font.pixelSize: 12
                        color: Theme.subtext0
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(1)
                    }

                }

            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                spacing: 2

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]

                    delegate: Text {
                        width: root.cellWidth
                        height: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: Theme.surface1
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                    }

                }

            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                spacing: 2

                Repeater {
                    model: root.cells

                    delegate: Item {
                        width: root.cellWidth
                        height: root.cellHeight

                        readonly property bool isToday: modelData > 0 && root.viewYear === root.today.getFullYear() && root.viewMonth === root.today.getMonth() && modelData === root.today.getDate()

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 13
                            color: parent.isToday ? Theme.accentMauve : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData > 0 ? modelData : ""
                            color: parent.isToday ? Theme.base : Theme.subtext0
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.bold: parent.isToday
                        }

                    }

                }

            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.surface0
                visible: root.hasTrack
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.hasTrack

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: Theme.base
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: source != ""
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.trackTitle || "") : ""
                        color: Theme.text
                        font.family: "Inter"
                        font.pixelSize: Theme.fontSm
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.trackArtist || root.player.identity || "") : ""
                        color: Theme.subtext0
                        font.family: "Inter"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                }

                RowLayout {
                    spacing: 2

                    Text {
                        text: "󰒮"
                        font.family: "MesloLGS Nerd Font"
                        font.pixelSize: 13
                        color: prevTrackMouse.containsMouse ? Theme.accentMauve : Theme.subtext0

                        MouseArea {
                            id: prevTrackMouse

                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player)
                                    root.player.previous();

                            }
                        }

                    }

                    Text {
                        text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                        font.family: "MesloLGS Nerd Font"
                        font.pixelSize: 14
                        color: playMouse.containsMouse ? Theme.accentMauve : Theme.text

                        MouseArea {
                            id: playMouse

                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player)
                                    root.player.togglePlaying();

                            }
                        }

                    }

                    Text {
                        text: "󰒭"
                        font.family: "MesloLGS Nerd Font"
                        font.pixelSize: 13
                        color: nextTrackMouse.containsMouse ? Theme.accentMauve : Theme.subtext0

                        MouseArea {
                            id: nextTrackMouse

                            anchors.fill: parent
                            anchors.margins: -4
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

            Text {
                Layout.fillWidth: true
                visible: !root.hasTrack
                text: "Nothing playing"
                color: Theme.surface1
                font.family: "Inter"
                font.pixelSize: 10
            }

        }

    }

}