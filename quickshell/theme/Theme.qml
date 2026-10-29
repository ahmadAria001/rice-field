import QtQuick
pragma Singleton

// The shell's palette.
//
// ===== Lacia =====
// Sampled from redjuice's BEATLESS illustration of Lacia (Lacia-class hIE
// Type-005): a cool white armour over a blue-black leotard, and hair that runs
// white at the roots through cyan highlights to deep azure at the tips.
//
// The important property is in the ladder, not the swatches: every body step is
// blue-black, and the blue bias RISES with lightness --
//
//     glass  #0A0C12  b-r = +8
//     bodyLow #14171F  b-r = +11
//     bodyMid #1B1F29  b-r = +14
//     bodyTop #262B37  b-r = +17
//     rim    #3A4152  b-r = +24
//
// That rising bias is her hair gradient applied to the neutrals, and it is what
// keeps a dark surface reading cold instead of grey. A flat grey ladder is what
// made the old palette look like plastic; this one looks like her.
//
// ===== roles =====
//   glass     the deepest ground (panels, the screen)
//   bodyLow   a resting surface (a pill at rest)
//   bodyMid   a raised surface / a card
//   bodyTop   a further-raised surface, a keycap face
//   rim       the moulded edge highlight
//   edge      the outer silhouette line
//   recess    slots, wells, holes
//   ink       primary text (her armour white)
//   inkDim    secondary text
//   inkFaint  tertiary text / labels
//   accent    selection, focus (her hair, mid)
//   accentDeep  her hair, tips (used sparingly, low contrast)
//   accentCyan  her hair, highlights (a lit state, a hover)
//   ice       her hair, roots (the brightest ink)
//
// Everything below is written by PaletteLoader from palette.json, so
// scripts/palette.sh can re-derive the whole set from a wallpaper and the
// structure above survives.
QtObject {
    id: themeRoot

    // ===== the Lacia ladder =====
    property color glass: "#0A0C12"
    property color bodyLow: "#14171F"
    property color bodyMid: "#1B1F29"
    property color bodyTop: "#262B37"
    property color rim: "#3A4152"
    property color edge: "#06070B"
    property color recess: "#10131A"

    // ===== ink =====
    property color ink: "#EEF2F8"
    property color inkDim: "#C3CBDA"
    property color inkFaint: "#8C97AB"

    // ===== her hair =====
    property color ice: "#DCE8F6"
    property color accentCyan: "#78C8E0"
    property color accent: "#3A8FD4"
    property color accentDeep: "#246CB4"

    // ===== functional =====
    // Lacia has no red of her own; the one on her Final Stage shoulder plate is
    // the only warm note in her design, so danger borrows it, desaturated
    // enough to sit in the same cold room.
    property color danger: "#D9667F"
    property color warn: "#C9955E"

    // ===== the hair gradient =====
    // Her colour story is a gradient, not a hue. This is the ONE gradient the
    // shell allows, and it is defined once here: a component that wants it reads
    // `Theme.hairStops` and builds its own Gradient from it, so the stops never
    // drift apart the way three hand-copied gradients do.
    readonly property var hairStops: [
        { p: 0.00, c: themeRoot.ice },
        { p: 0.45, c: themeRoot.accentCyan },
        { p: 1.00, c: themeRoot.accent }
    ]

    // ===== legacy names =====
    // The shell grew up on Catppuccin names and 500-odd call sites still use
    // them. They are aliases now, not storage: nothing writes them, so they
    // cannot drift from the Lacia tokens above.
    readonly property color mantle: themeRoot.bodyLow
    readonly property color base: themeRoot.glass
    readonly property color surface0: themeRoot.bodyMid
    readonly property color surface1: themeRoot.bodyTop
    readonly property color text: themeRoot.ink
    readonly property color subtext0: themeRoot.inkFaint
    readonly property color subtext1: themeRoot.inkDim
    readonly property color mauve: themeRoot.accent
    readonly property color red: themeRoot.danger
    // Fixed accents for dark, low-chrome surfaces (lock screen, fullscreen
    // overlays). Kept as names because the lock screen asks for them by name.
    readonly property color accentMauve: themeRoot.accent
    readonly property color accentPink: themeRoot.accentCyan

    // Metrics & Styling (always static)
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 10
    readonly property int radiusXl: 14
    readonly property int borderWidth: 1
    // Typography
    readonly property int fontSm: 11
    readonly property int fontMd: 12
    readonly property int fontLg: 13
    readonly property int fontXl: 14
    // State
    property bool dndEnabled: false

    // Motion tokens
    property real motionScale: 1.0

    readonly property int animFast: Math.round(120 * motionScale)
    readonly property int animNormal: Math.round(180 * motionScale)
    readonly property int animSlow: Math.round(260 * motionScale)
    readonly property int animView: Math.round(280 * motionScale)
    readonly property int animExit: Math.round(115 * motionScale)

    readonly property int easeEntrance: Easing.OutCubic
    readonly property int easeExit: Easing.InCubic
    readonly property int easeGeneral: Easing.OutQuad
    readonly property int easeView: Easing.OutQuint

    readonly property real scaleDown: 0.96
    readonly property real slideDistance: 8
    readonly property real slideDistancePanel: 16
    // Slide direction token for panels: "fromTop", "fromRight", "fromLeft", "fromBottom"
    readonly property string panelSlideDirection: "fromTop"

    // ===== the hair, in motion =====
    // One shared clock for every HairBar, so the shell's hairline drifts as a single
    // system instead of each card running its own timer out of phase. 0..1 over about
    // 10 seconds. Held at 0 when motion is scaled to nothing, which leaves the
    // gradient static rather than dead.
    //
    // It was 18 seconds, and 18 seconds of drift along a 1px line is slow enough
    // that the eye files it as a static border. 10 is still a drift, not a chase.
    property real hairPhase: 0
    property Timer hairTimer: Timer {
        interval: 60
        running: themeRoot.motionScale > 0
        repeat: true
        onTriggered: themeRoot.hairPhase = (themeRoot.hairPhase + 0.0058) % 1.0
    }
}
