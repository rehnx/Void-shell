import QtQuick

QtObject {
    // Compatibility facade: existing consumers resolve to the same singleton.
    readonly property color text: Theme.textPrimary
    readonly property color secondary: Theme.textSecondary
    readonly property color accent: Theme.accent
    readonly property color surface: Theme.surface
    readonly property color tile: Theme.hover
    readonly property color border: Theme.border
    readonly property color highlight: Theme.pressed
    readonly property color depth: Theme.surfaceInset
    readonly property int duration: Motion.settle
    readonly property int radius: Theme.radiusLarge
    readonly property int radiusSmall: Theme.radiusSmall
    readonly property int spacingSmall: Theme.spacingSmall
    readonly property int spacingMedium: Theme.spacingMedium
    readonly property int fontSmall: Theme.fontCaption
    readonly property int fontBody: Theme.fontBody
    readonly property int fontHeading: Theme.fontTitle
    readonly property int panelWidth: Theme.panelWidth
    readonly property int panelHeight: Theme.panelHeight
    readonly property int panelTop: Theme.panelTop
}
