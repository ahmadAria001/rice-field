import "../theme"
import QtQuick

// A hairline filled with Lacia's hair gradient: ice at the left, cyan through
// the middle, azure at the right.
//
// This exists so the gradient has ONE definition. `Theme.hairStops` holds the
// three stops and their positions; this component turns them into a Gradient.
// Anything that wants her colour story -- a slider's filled track, the rule
// under a section header, the bar's active workspace -- uses this instead of
// hand-writing three GradientStops, which is how the three copies drift apart.
//
//   HairBar { width: 400; height: 3; radius: 1.5 }   (radius = Rectangle's)
//   HairBar { width: 400; height: 1; opacity: 0.5; fadeTo: "end" }
//
// `fadeTo` is for rules that should dissolve rather than stop: "end" fades the
// azure stop to transparent, "none" (the default) keeps the gradient solid.
// It fades by alpha, so the colour is still hers.
Rectangle {
    id: root

    // "none" | "end"
    property string fadeTo: "none"
    // 0..1: how much of the gradient to show, left to right. A slider's fill.
    property real progress: 1.0

    // (radius is Rectangle's own; a caller sets it directly)
    antialiasing: true
    color: "transparent"

    // The visible slice is `progress` of the full width. Clipping would cut the
    // gradient's own geometry, so the rectangle is narrowed and the gradient is
    // re-anchored to the full width instead: the colour at any x stays the same
    // as it would be at full width.
    readonly property real fullWidth: root.width

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.00
            color: Theme.hairStops[0].c
        }
        GradientStop {
            position: Theme.hairStops[1].p * root.progress
            color: Theme.hairStops[1].c
        }
        GradientStop {
            position: 1.00
            color: root.fadeTo === "end"
                ? Qt.rgba(Theme.hairStops[2].c.r, Theme.hairStops[2].c.g, Theme.hairStops[2].c.b, 0.0)
                : Theme.hairStops[2].c
        }
    }
}
