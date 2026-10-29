import "../theme"
import QtQuick

// The panel-open signature: a scan that resolves the surface instead of a plain
// fade. A band of her colour runs down the card once, and two chromatic fringes
// -- ice on the left edge, azure on the right -- collapse as it passes.
//
// It is a transition, so it runs once per open and then draws nothing. It also
// takes no input: every item here is a Rectangle with no MouseArea, so a panel
// with this laid over it keeps exactly the hit area it had before.
//
//   ScanReveal { anchors.fill: parent; active: root.shown }
Item {
    id: root

    // Drive this from the panel's shown state. Rising edge fires the scan.
    property bool active: false
    // Scaled with the rest of the motion tokens, so a reduced-motion setting
    // collapses this to nothing rather than leaving a hard cut.
    readonly property int scanDuration: Math.round(150 * Theme.motionScale)
    readonly property int fringeDuration: Math.round(120 * Theme.motionScale)

    // Nothing to draw between scans, and nothing to composite either.
    visible: band.opacity > 0.001
    clip: true

    function fire() {
        if (scanDuration <= 0)
            return;

        sweep.restart();
    }

    onActiveChanged: {
        if (active)
            root.fire();

    }

    ParallelAnimation {
        id: sweep

        // The band travels the full height of the card. OutCubic so it is already
        // most of the way down by the time the eye catches it -- a linear sweep
        // reads as a progress bar, which is the wrong idea.
        NumberAnimation {
            target: band
            property: "y"
            from: -band.height
            to: root.height
            duration: root.scanDuration
            easing.type: Easing.OutCubic
        }

        // Up fast, down slow: the leading edge is the part that reads as a scan.
        SequentialAnimation {
            NumberAnimation {
                target: band
                property: "opacity"
                from: 0
                to: 1.0
                duration: Math.round(root.scanDuration * 0.3)
            }

            NumberAnimation {
                target: band
                property: "opacity"
                to: 0
                duration: Math.round(root.scanDuration * 0.7)
            }

        }

        NumberAnimation {
            target: fringes
            property: "opacity"
            from: 0.5
            to: 0
            duration: root.fringeDuration
            easing.type: Easing.OutQuad
        }

    }

    // The band is a *trail*, not a glow: it is brightest at its lower edge and
    // fades upward, so the bright line below reads as the leading edge of a scan
    // moving down. A symmetric band reads as a soft highlight passing over the
    // card, which is a different (and much weaker) idea.
    Rectangle {
        id: band

        width: root.width
        height: 46
        y: -height
        opacity: 0
        color: "transparent"

        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0.0
                color: Qt.rgba(Theme.hairStops[1].c.r, Theme.hairStops[1].c.g, Theme.hairStops[1].c.b, 0.0)
            }

            GradientStop {
                position: 0.7
                color: Qt.rgba(Theme.hairStops[1].c.r, Theme.hairStops[1].c.g, Theme.hairStops[1].c.b, 0.18)
            }

            GradientStop {
                position: 1.0
                color: Qt.rgba(Theme.hairStops[1].c.r, Theme.hairStops[1].c.g, Theme.hairStops[1].c.b, 0.5)
            }
        }

    }

    // The leading edge itself. One pixel of her cyan at high alpha is what the eye
    // actually tracks; the 46px trail above it only says which way it is going.
    Rectangle {
        id: edge

        width: root.width
        height: 1
        y: band.y + band.height - 1
        opacity: band.opacity
        color: Qt.rgba(Theme.hairStops[1].c.r, Theme.hairStops[1].c.g, Theme.hairStops[1].c.b, 0.9)
    }

    // The chromatic split: ice leading, azure trailing, both collapsing onto the
    // edge as the surface resolves. Two 2px rects, not a channel-separated copy of
    // the card, which would mean rendering the panel twice.
    Item {
        id: fringes

        anchors.fill: parent
        opacity: 0

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: Theme.hairStops[0].c
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: Theme.hairStops[2].c
        }

    }

}