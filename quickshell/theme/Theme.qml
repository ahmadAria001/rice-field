import QtQuick
pragma Singleton

QtObject {
    id: themeRoot

    // Dynamic palette colors (set at runtime from palette.json)
    // Defaults: Catppuccin Mocha fallback
    property color mantle: "#181825"
    property color base: "#1e1e2e"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color subtext1: "#bac2de"
    property color mauve: "#cba6f7" // Primary Accent (dynamic)
    readonly property color red: "#f38ba8" // Critical / Danger (fixed)
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
    readonly property int animExit: Math.round(115 * motionScale)

    readonly property int easeEntrance: Easing.OutCubic
    readonly property int easeExit: Easing.InCubic
    readonly property int easeGeneral: Easing.OutQuad

    readonly property real scaleDown: 0.96
    readonly property real slideDistance: 8
}
