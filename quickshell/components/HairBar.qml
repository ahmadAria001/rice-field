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
//   HairBar { width: 400; height: 3; radius: 1.5 }
//   HairBar { width: 400; height: 1; opacity: 0.5; fadeTo: "end" }
//
// `fadeTo` is for rules that should dissolve rather than stop: "end" fades the
// azure stop to transparent, "none" (the default) keeps the gradient solid.
// It fades by alpha, so the colour is still hers.
Rectangle {
    id: root

    // "none" | "end"
    property string fadeTo: "none"
    // 0..1: how much of the gradient to show, left to right. Drives the arrival
    // sequences, where a rule draws itself in instead of fading.
    property real progress: 1.0
    // The highlight drifts rather than sitting at a fixed stop. Every hairline in
    // the shell reads Theme.hairPhase, so they move as one system instead of
    // drifting out of step the way a per-instance timer would.
    property bool living: true

    // (radius is Rectangle's own; a caller sets it directly)
    antialiasing: true
    color: "transparent"

    readonly property real filledWidth: root.width * root.progress

    // The reveal window. The gradient is drawn at full width inside this and the
    // window clips it, so `progress` is a wipe rather than a resize: the colours
    // stay where they belong while the line draws in. It used to only move the
    // sheen and the middle stop, so a caller asking for 40% still painted the
    // whole line -- documented as a left-to-right reveal and never clipping.
    Item {
        id: window

        width: root.filledWidth
        height: root.height
        clip: true

        Rectangle {
            id: gradientRect

            width: root.width
            height: root.height
            radius: root.radius
            antialiasing: true

            // The drift is a sheen that slides along the bar, not an animated
            // gradient stop: Qt does not repaint a Rectangle's gradient when a
            // stop position changes (measured -- the stop moved, the pixels did
            // not), whereas moving an item is an ordinary transform update.
            // Cheaper, and it actually shows.
            Rectangle {
                id: sheen

                visible: root.living && root.progress > 0.02
                // A comet, not a wash. At 35% of the bar's width the highlight was
                // a 980px hump sliding across 2800px, which is a change in overall
                // brightness rather than something you can watch move. Narrower
                // and brighter reads as a light travelling the edge.
                width: Math.max(48, Math.min(320, root.width * 0.16))
                height: root.height
                y: 0
                x: (root.width - width) * ((Math.sin(Theme.hairPhase * Math.PI * 2) + 1) / 2)
                opacity: 0.9
                antialiasing: true

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }

                    GradientStop {
                        position: 0.5
                        color: Qt.rgba(1, 1, 1, 1.0)
                    }

                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.00
                    color: Theme.hairStops[0].c
                }

                GradientStop {
                    position: Theme.hairStops[1].p
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

    }

}