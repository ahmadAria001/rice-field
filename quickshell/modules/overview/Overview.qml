import "../../theme"
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "."

// Full-screen workspace overview: every workspace as a column of live window
// thumbnails, over the blurred wallpaper. Overlay layer so it covers the bar, and
// exclusionMode Ignore so it never reserves space when hidden.
PanelWindow {
    id: root

    property bool shown: false
    property string wallpaperSource: ""

    function open() {
        if (root.shown)
            return ;

        // The toplevel model only refreshes on its own signals; force a re-read so
        // windows that moved while the overlay was closed land in the right column.
        Hyprland.refreshToplevels();
        root.shown = true;
        wallpaperProc.running = true;
    }

    function close() {
        if (!root.shown)
            return ;

        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
        root.close();
    }

    function focusWindow(toplevel) {
        if (!toplevel)
            return ;

        // HyprlandToplevel.address is bare hex; the address: selector needs the 0x
        // prefix or the dispatch fails with "window not found".
        const addr = toplevel.address || "";
        const target = addr.indexOf("0x") === 0 ? addr : "0x" + addr;
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + target + "\" })");
        root.close();
    }

    readonly property var targetScreen: {
        const monName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === monName)
                return Quickshell.screens[i];

        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    // Always show 1-5 (the bar's range) and any extra numeric workspace in use, so the
    // overview does not silently hide a workspace the user actually has windows on.
    readonly property var workspaceIds: {
        const ids = new Set([1, 2, 3, 4, 5]);
        const all = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < all.length; i++) {
            const id = all[i].id;
            if (id > 0 && id <= 9)
                ids.add(id);

        }
        return Array.from(ids).sort(function(a, b) {
            return a - b;
        });
    }

    readonly property real monitorAspect: {
        const m = Hyprland.focusedMonitor;
        return (m && m.height > 0) ? m.width / m.height : 16 / 9;
    }

    // Six workspaces in one row on a 1280-wide screen leaves each card ~187px. Wrapping
    // into a grid roughly halves the column count and doubles the preview size.
    readonly property int gridColumns: {
        const n = root.workspaceIds.length;
        if (n <= 3)
            return Math.max(1, n);

        if (n === 4)
            return 2;

        return Math.ceil(n / 2);
    }
    readonly property int gridRows: Math.max(1, Math.ceil(root.workspaceIds.length / root.gridColumns))

    // Fit the grid on screen: bounded by the width each column gets and by the height
    // each miniature needs at the monitor's aspect ratio.
    readonly property real cardWidth: {
        const cols = root.gridColumns;
        const rows = root.gridRows;
        const gap = 14;
        const availW = Math.max(0, root.width - 88 - (cols - 1) * gap);
        const availH = Math.max(0, root.height - 88 - 56 - (rows - 1) * gap);
        const byWidth = availW / cols;
        // 66 = card header row plus card padding.
        const byHeight = (availH / rows - 66) * root.monitorAspect;
        return Math.max(140, Math.min(byWidth, byHeight, 420));
    }

    screen: root.targetScreen
    visible: root.shown || surface.opacity > 0.001
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Process {
        id: wallpaperProc

        command: ["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/current_wallpaper.txt\" 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                root.wallpaperSource = path ? "file://" + path : "";
            }
        }

    }

    Item {
        id: surface

        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : Theme.scaleDown
        focus: root.shown

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

        Image {
            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            layer.enabled: true

            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 64
                saturation: -0.3
                brightness: -0.22
            }

        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.06, 0.06, 0.08, 0.5)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 44
            spacing: 18

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Workspaces"
                    color: Theme.ink
                    font.family: "Inter"
                    font.pixelSize: Theme.fontXl
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "1-5 to switch  ·  Esc to close"
                    color: Theme.inkFaint
                    font.family: "Inter"
                    font.pixelSize: Theme.fontSm
                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Grid {
                    anchors.centerIn: parent
                    columns: root.gridColumns
                    spacing: 14

                    Repeater {
                        model: root.workspaceIds

                        delegate: WorkspaceCard {
                            width: root.cardWidth
                            wsId: modelData
                            active: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === modelData : false
                            captureEnabled: root.shown
                            onWindowActivated: function(toplevel) {
                                root.focusWindow(toplevel);
                            }
                            onSwitchRequested: root.focusWorkspace(modelData)
                        }

                    }

                }

            }

        }

        // Digits switch workspace directly. Handled here rather than as five
        // Shortcuts so the mapping stays in one place.
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
                return ;
            }
            const digit = event.key - Qt.Key_0;
            if (digit >= 1 && digit <= 9 && root.workspaceIds.indexOf(digit) !== -1) {
                root.focusWorkspace(digit);
                event.accepted = true;
            }
        }

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

        target: "overview"
    }

}