import QtQuick

Rectangle {
    id: root
    property bool elevated: false
    property real elevation: 1
    ControlStyle { id: style }
    radius: style.radius
    color: style.surface
    gradient: Gradient {
        GradientStop { position: 0; color: root.elevated ? "#dc52758c" : "#704b809e" }
        GradientStop { position: 0.45; color: root.elevated ? "#e12b4c69" : "#55336186" }
        GradientStop { position: 1; color: root.elevated ? style.depth : "#70334a75" }
    }
    border.width: 1
    border.color: style.border
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.color: "#1676bfe9"
    }
    Rectangle {
        visible: root.elevated
        opacity: root.elevation
        anchors.fill: parent
        anchors.margins: -4
        z: -1
        radius: root.radius + 4
        color: "#14081321"
        border.width: 4
        border.color: "#09081321"
    }
}
