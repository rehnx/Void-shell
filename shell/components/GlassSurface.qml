import QtQuick

Rectangle {
    id: root
    property bool elevated: false
    property real elevation: 1
    property string surfaceRole: elevated ? "panel" : "base"
    property int padding: Theme.cardPadding
    property bool shadowEnabled: elevated && Theme.shadowsEnabled
    readonly property int elevationLevel: !shadowEnabled ? Theme.elevationNone
        : surfaceRole === "card" ? Theme.elevationCard : Theme.elevationPanel
    property color tint: surfaceRole === "card" ? Theme.surfaceCard
        : elevated ? Theme.surfaceElevated : Theme.surface
    property color bottomTint: surfaceRole === "card" ? Theme.surfaceCardBottom : Theme.surfaceBottom
    radius: Theme.radiusLarge
    color: tint
    gradient: Gradient {
        GradientStop { position: 0; color: root.tint }
        GradientStop { position: 1; color: root.bottomTint }
    }
    border.width: Theme.borderWidth
    border.color: Theme.border
    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        radius: Math.max(0, root.radius - Theme.borderWidth)
        color: "transparent"
        border.color: Theme.innerBorder
    }
    // Static rings, not per-frame blur or offscreen effects.
    Rectangle {
        visible: root.shadowEnabled
        opacity: root.elevation
        x: -Theme.shadowNearSpread
        y: -Theme.shadowNearSpread + Theme.shadowOffset
        width: root.width + Theme.shadowNearSpread * 2
        height: root.height + Theme.shadowNearSpread * 2
        z: -1
        radius: root.radius + Theme.shadowNearSpread
        color: Theme.shadowNear
    }
    Rectangle {
        visible: root.shadowEnabled && root.elevationLevel === Theme.elevationPanel
        opacity: root.elevation
        anchors.fill: parent
        anchors.margins: -Theme.shadowFarSpread
        z: -2
        radius: root.radius + Theme.shadowFarSpread
        color: Theme.shadowFar
    }
}
