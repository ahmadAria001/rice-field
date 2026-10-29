import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../components"
import "."

// One workspace column in the overview: a numbered header plus a miniature of the
// workspace, with each window placed at its real position and size. Clicking the
// header switches to the workspace; clicking a window focuses it.
GlassCard {
    id: root

    // Not `required`: QML evaluates a required property's binding at object
    // creation, before the Repeater delegate context (modelData) is attached, which
    // left every card reading an undefined model value.
    property int wsId: 0
    property bool active: false
    property bool captureEnabled: false

    signal windowActivated(var toplevel)
    signal switchRequested()

    // valuesChanged is the only signal the toplevel model guarantees, so this
    // re-evaluates when windows appear or disappear. Individual property changes on
    // an existing toplevel (a retitle, a resize) will not, which is fine for a
    // snapshot view.
    readonly property var windows: {
        const out = [];
        const all = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (let i = 0; i < all.length; i++) {
            const t = all[i];
            if (t.workspace && t.workspace.id === root.wsId)
                out.push(t);

        }
        return out;
    }

    // Geometry from a client is monitor-local, so the miniature has to be scaled
    // against that monitor's logical size, not the card's. Monitor width/height are
    // physical pixels; client geometry is logical, so the scale factor has to come out.
    readonly property var monitor: {
        for (let i = 0; i < root.windows.length; i++) {
            if (root.windows[i].monitor)
                return root.windows[i].monitor;

        }
        return Hyprland.focusedMonitor;
    }
    readonly property real monitorW: (root.monitor && root.monitor.width > 0) ? root.monitor.width / Math.max(1, root.monitor.scale) : 1920
    readonly property real monitorH: (root.monitor && root.monitor.height > 0) ? root.monitor.height / Math.max(1, root.monitor.scale) : 1080
    readonly property real previewAspect: root.monitorW / root.monitorH

    radius: Theme.radiusLg
    // Uses GlassCard's own accent flag rather than overriding border.color, so the
    // inactive border stays whatever token the card surface currently uses.
    accented: root.active

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 22
            height: 22
            radius: 11
            color: root.active ? Theme.accentMauve : Theme.surface0

            Text {
                anchors.centerIn: parent
                text: root.wsId
                color: root.active ? Theme.base : Theme.subtext0
                font.family: "Inter"
                font.pixelSize: Theme.fontSm
                font.bold: true
            }

        }

        Text {
            text: root.windows.length === 1 ? "1 window" : root.windows.length + " windows"
            color: Theme.subtext0
            font.family: "Inter"
            font.pixelSize: Theme.fontSm
        }

        Item {
            Layout.fillWidth: true
        }

        // The header is the workspace hit target: a card-wide MouseArea would sit
        // over the window tiles and steal their clicks.
        MouseArea {
            implicitWidth: 16
            implicitHeight: 16
            cursorShape: Qt.PointingHandCursor

            Text {
                anchors.centerIn: parent
                text: "󰁔"
                color: Theme.surface1
                font.family: "MesloLGS Nerd Font"
                font.pixelSize: 12
            }

            onClicked: root.switchRequested()
        }

    }

    Item {
        id: preview

        Layout.fillWidth: true
        // Derived from the card width rather than the item's own width: the layout
        // sizes the column from this implicitHeight, so binding to `width` here would
        // make the card's height depend on a width the layout has not settled yet.
        implicitHeight: (root.width - 32) / root.previewAspect
        clip: true

        // The monitor surface: gives the miniature a screen to sit on, so a window
        // that does not span the workspace still reads as positioned, not floating.
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: Theme.base
            border.width: Theme.borderWidth
            border.color: Theme.surface0
        }

        Repeater {
            model: root.windows

            delegate: WindowThumb {
                toplevel: modelData
                captureEnabled: root.captureEnabled
                scaleFactor: preview.width / root.monitorW
                onActivated: root.windowActivated(modelData)
            }

        }

        Text {
            anchors.centerIn: parent
            visible: root.windows.length === 0
            text: "empty"
            color: Theme.surface1
            font.family: "Inter"
            font.pixelSize: Theme.fontSm
        }

    }

}