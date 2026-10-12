import QtQuick
pragma Singleton

QtObject {
    // Catppuccin Mocha Palette
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color mantle: "#181825"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color mauve: "#cba6f7" // Primary Accent
    readonly property color red: "#f38ba8" // Critical / Danger
    // Metrics & Styling
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
}
