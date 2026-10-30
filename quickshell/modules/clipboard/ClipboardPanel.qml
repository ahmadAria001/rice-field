import "../../components"
import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property var clips: []

    function addClip(text) {
        if (!text || typeof text !== "string")
            return ;

        const trimmed = text.trim();
        if (trimmed === "")
            return ;

        const list = root.clips.slice();
        const existingIdx = list.indexOf(text);
        if (existingIdx !== -1)
            list.splice(existingIdx, 1);

        list.unshift(text);
        if (list.length > 50)
            list.splice(50);

        root.clips = list;
        saveClips();
    }

    function deleteClip(targetText) {
        const list = root.clips.slice();
        const idx = list.indexOf(targetText);
        if (idx !== -1) {
            list.splice(idx, 1);
            root.clips = list;
            saveClips();
        }
    }

    function clearAll() {
        root.clips = [];
        saveClips();
    }

    function selectClip(text) {
        if (!text)
            return ;

        copyProc.exec(["wl-copy", text]);
        Quickshell.clipboardText = text;
        addClip(text);
        root.close();
    }

    function loadClips() {
        try {
            const content = historyFile.text();
            if (content && content.trim() !== "") {
                const parsed = JSON.parse(content);
                if (Array.isArray(parsed))
                    root.clips = parsed;

            }
        } catch (e) {
            console.warn("Failed to load clipboard history:", e);
        }
    }

    function saveClips() {
        try {
            historyFile.setText(JSON.stringify(root.clips, null, 2));
        } catch (e) {
            console.warn("Failed to save clipboard history:", e);
        }
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    // `shown` drives the fade; `visible` stays true until the fade has finished.
    // Toggling `visible` directly gave this panel no close animation at all, which
    // is why its exit scan was the one that never appeared.
    property bool shown: false
    readonly property bool onScreen: shown || card.opacity > 0.001

    visible: onScreen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open() {
        searchField.text = "";
        searchField.forceActiveFocus();
        clipList.currentIndex = 0;
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }
    Component.onCompleted: {
        loadClips();
    }

    // IPC handler for toggling / opening
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

        target: "clipboard"
    }

    // Dismiss with Escape
    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: root.close()
    }

    // File persistence
    FileView {
        id: historyFile

        path: Quickshell.shellDir + "/clipboard_history.json"
        blockLoading: true
    }

    // Process for copying
    Process {
        id: copyProc
    }

    // Background watcher using wl-paste --watch
    Process {
        id: clipWatcher

        command: [Quickshell.shellDir + "/scripts/clip_watch.sh"]
        running: true
        onRunningChanged: {
            if (!running)
                running = true;

        }

        stdout: SplitParser {
            onRead: (data) => {
                if (!data || data.trim() === "")
                    return ;

                try {
                    const str = JSON.parse(data.trim());
                    if (typeof str === "string" && str.trim() !== "")
                        root.addClip(str);

                } catch (e) {
                }
            }
        }

    }

    // Listener for Quickshell native clipboard property changes
    Connections {
        function onClipboardTextChanged() {
            if (Quickshell.clipboardText && Quickshell.clipboardText.trim() !== "")
                root.addClip(Quickshell.clipboardText);

        }

        target: Quickshell
    }

    // Backdrop dismissal
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()

        Rectangle {
            anchors.fill: parent
            // The palette's own black rather than a literal, and faded with the
            // card so the whole surface leaves together.
            color: Qt.rgba(Theme.edge.r, Theme.edge.g, Theme.edge.b, 0.5)
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.shown ? Theme.animNormal : Theme.animExit
                    easing.type: root.shown ? Theme.easeEntrance : Theme.easeExit
                }

            }

        }

    }

    // Center Modal Card
    Rectangle {
        id: card

        width: 560
        height: 500
        anchors.centerIn: parent
        // The shared card surface. This panel was missed when the rest of the
        // shell moved off base/surface0, so it read as an unthemed rectangle
        // sitting in the middle of a Lacia session.
        color: Theme.bodyMid
        radius: Theme.radiusLg
        border.color: Theme.rim
        border.width: Theme.borderWidth
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.scaleDown

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

        HairBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: card.radius
            anchors.rightMargin: card.radius
            anchors.topMargin: 1
            height: 2
            radius: 0
            opacity: 0.34
            fadeTo: "end"
        }

        // Absorb clicks so backdrop doesn't close when clicking inside card
        MouseArea {
            anchors.fill: parent
        }

        // Overlay only: nothing between opens, and no input taken.
        ScanReveal {
            anchors.fill: parent
            active: root.shown
            z: 100
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Icon
                Text {
                    text: "󰅌"
                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                    font.pixelSize: Theme.fontXl
                    color: Theme.accent
                }

                // Title
                Text {
                    text: "Clipboard History"
                    font.family: "sans-serif"
                    font.pixelSize: Theme.fontLg
                    font.bold: true
                    color: Theme.ink
                }

                // Item count pill
                Rectangle {
                    implicitWidth: countText.implicitWidth + 12
                    implicitHeight: 22
                    radius: Theme.radiusSm
                    color: Theme.bodyMid

                    Text {
                        id: countText

                        anchors.centerIn: parent
                        text: root.clips.length + " items"
                        font.pixelSize: Theme.fontSm
                        color: Theme.inkFaint
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                // Clear All Button
                Rectangle {
                    visible: root.clips.length > 0
                    implicitWidth: clearRow.implicitWidth + 14
                    implicitHeight: 26
                    radius: Theme.radiusSm
                    color: clearMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid
                    border.color: clearMouse.containsMouse ? Theme.danger : "transparent"
                    border.width: Theme.borderWidth

                    RowLayout {
                        id: clearRow

                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰆴"
                            font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                            font.pixelSize: Theme.fontSm
                            color: clearMouse.containsMouse ? Theme.danger : Theme.inkFaint
                        }

                        Text {
                            text: "Clear All"
                            font.family: "sans-serif"
                            font.pixelSize: Theme.fontSm
                            color: clearMouse.containsMouse ? Theme.danger : Theme.inkFaint
                        }

                    }

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAll()
                    }

                }

                // Close Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Theme.radiusSm
                    color: closeMouse.containsMouse ? Theme.bodyTop : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontMd
                        color: closeMouse.containsMouse ? Theme.ink : Theme.inkFaint
                    }

                    MouseArea {
                        id: closeMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }

                }

            }

            // Search Bar
            TextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: "Type to filter clips..."
                placeholderTextColor: Theme.inkFaint
                font.pixelSize: Theme.fontMd
                color: Theme.ink
                focus: true
                leftPadding: 34
                rightPadding: 32
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        clipList.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        clipList.decrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (clipList.currentItem && clipList.currentItem.clipText)
                            root.selectClip(clipList.currentItem.clipText);

                        event.accepted = true;
                    }
                }

                background: Rectangle {
                    color: Theme.bodyMid
                    radius: Theme.radiusSm
                    border.color: searchField.activeFocus ? Theme.accent : Theme.bodyTop
                    border.width: Theme.borderWidth

                    // Search icon inside textfield
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontMd
                        color: Theme.inkFaint
                    }

                    // Clear search input button
                    Text {
                        visible: searchField.text !== ""
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: clearSearchMouse.containsMouse ? Theme.ink : Theme.inkFaint

                        MouseArea {
                            id: clearSearchMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = "";
                                searchField.forceActiveFocus();
                            }
                        }

                    }

                }

            }

            // Empty State View
            Item {
                visible: clipList.count === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰅌"
                        font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                        font.pixelSize: 36
                        color: Theme.bodyTop
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: searchField.text === "" ? "Clipboard is empty" : "No matching clips found"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontMd
                        font.bold: true
                        color: Theme.inkFaint
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: searchField.text === "" ? "Copied items will appear here automatically" : "Try searching with different keywords"
                        font.family: "sans-serif"
                        font.pixelSize: Theme.fontSm
                        color: Theme.bodyTop
                    }

                }

            }

            // Clipboard History List
            ListView {
                id: clipList

                visible: count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    id: clipModel

                    values: {
                        const q = searchField.text.toLowerCase().trim();
                        if (q === "")
                            return root.clips;

                        return root.clips.filter((item) => {
                            return item.toLowerCase().includes(q);
                        });
                    }
                }

                delegate: Rectangle {
                    id: itemCard

                    required property var modelData
                    required property int index
                    property string clipText: modelData
                    property bool isSelected: index === clipList.currentIndex

                    width: ListView.view.width
                    implicitHeight: Math.max(52, previewColumn.implicitHeight + 16)
                    radius: Theme.radiusSm
                    color: itemMouse.containsMouse ? Theme.bodyMid : Theme.bodyLow
                    border.color: itemCard.isSelected ? Theme.accent : (itemMouse.containsMouse ? Theme.bodyTop : Theme.bodyMid)
                    border.width: Theme.borderWidth

                    // Main card click: selects clip and closes panel for immediate pasting
                    MouseArea {
                        id: itemMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: (mouse) => {
                            clipList.currentIndex = itemCard.index;
                            root.selectClip(itemCard.clipText);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12
                        z: 1

                        // Index badge
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: Theme.radiusSm
                            color: itemCard.isSelected ? Theme.accent : Theme.bodyMid

                            Text {
                                anchors.centerIn: parent
                                text: "#" + (itemCard.index + 1)
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontSm
                                font.bold: true
                                color: itemCard.isSelected ? Theme.bodyLow : Theme.inkFaint
                            }

                        }

                        // Text Preview Column
                        ColumnLayout {
                            id: previewColumn

                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: itemCard.clipText.replace(/\r\n/g, "\n").replace(/\n/g, " ↵ ")
                                font.family: "MesloLGS Nerd Font, monospace, sans-serif"
                                font.pixelSize: Theme.fontSm
                                color: Theme.ink
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                            }

                            // Meta info (character / line count)
                            Text {
                                text: {
                                    const len = itemCard.clipText.length;
                                    const lines = itemCard.clipText.split("\n").length;
                                    return len + " chars" + (lines > 1 ? " • " + lines + " lines" : "");
                                }
                                font.family: "sans-serif"
                                font.pixelSize: Theme.fontSm - 1
                                color: Theme.inkFaint
                            }

                        }

                        // Action Buttons: Copy / Select indicator and Delete button
                        RowLayout {
                            spacing: 6
                            z: 2

                            // Delete button
                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                color: delMouse.containsMouse ? Theme.bodyTop : "transparent"
                                border.color: delMouse.containsMouse ? Theme.danger : "transparent"
                                border.width: Theme.borderWidth

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                    font.pixelSize: Theme.fontMd
                                    color: delMouse.containsMouse ? Theme.danger : Theme.inkFaint
                                }

                                MouseArea {
                                    id: delMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true
                                    propagateComposedEvents: false
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        root.deleteClip(itemCard.clipText);
                                    }
                                }

                                TooltipCard {
                                    anchorItem: delMouse
                                    shown: delMouse.containsMouse
                                    text: "Delete clip"
                                }

                            }

                            // Select / Ready to Paste indicator
                            Rectangle {
                                id: selectHint

                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                color: itemMouse.containsMouse ? Theme.accent : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆏"
                                    font.family: "MesloLGS Nerd Font, FantasqueSansM Nerd Font, sans-serif"
                                    font.pixelSize: Theme.fontMd
                                    color: itemMouse.containsMouse ? Theme.bodyLow : Theme.inkFaint
                                }

                                TooltipCard {
                                    anchorItem: selectHint
                                    shown: itemMouse.containsMouse && !delMouse.containsMouse
                                    text: "Click to select & copy for paste"
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

            }

        }

    }

}
