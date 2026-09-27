import QtQuick

QtObject {
    // Shared glass palette for the bar, launcher and Control Center.
    readonly property color text: "#f4faff"
    readonly property color secondary: "#c0d6e8"
    readonly property color accent: "#8edbff"
    readonly property color surface: "#dd203e58"
    readonly property color tile: "#354b90b4"
    readonly property color border: "#55d9f2ff"
    readonly property color highlight: "#609bcee8"
    readonly property color depth: "#cc152c48"
    readonly property int duration: Motion.settle
    readonly property int radius: 28
    readonly property int radiusSmall: 12
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 16
    readonly property int fontSmall: 12
    readonly property int fontBody: 14
    readonly property int fontHeading: 20
    readonly property int panelWidth: 420
    readonly property int panelHeight: 580
    readonly property int panelTop: 60
}
