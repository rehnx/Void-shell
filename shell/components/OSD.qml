pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var service
    ControlStyle { id: theme }
    screen: Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: service.osdVisible || surface.opacity > 0
    color: "transparent"
    implicitWidth: 300
    implicitHeight: 76
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins.bottom: 56
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    GlassSurface {
        id: surface
        anchors.fill: parent
        anchors.margins: theme.spacingSmall
        opacity: root.service.osdVisible ? 1 : 0
        scale: root.service.osdVisible ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: theme.duration } }
        Behavior on scale { NumberAnimation { duration: theme.duration; easing.type: Easing.OutCubic } }
        Row {
            anchors.fill: parent
            anchors.margins: theme.spacingMedium
            spacing: theme.spacingMedium
            Text {
                width: 26
                anchors.verticalCenter: parent.verticalCenter
                text: root.service.osdKind === "brightness" ? "☀" : root.service.osdKind === "microphone" ? "●" : "♪"
                color: theme.text
                font.pixelSize: 20
            }
            Column {
                width: parent.width - 42
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.spacingSmall
                Text {
                    text: root.service.osdLabel + (root.service.osdMuted ? " muted" : "  " + Math.round(root.service.osdValue * 100) + "%")
                    color: theme.text
                    font.pixelSize: theme.fontSmall
                }
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: theme.depth
                    Rectangle {
                        width: root.service.osdMuted ? 0 : parent.width * root.service.osdValue
                        height: parent.height
                        radius: parent.radius
                        color: theme.accent
                        Behavior on width { NumberAnimation { duration: theme.duration } }
                    }
                }
            }
        }
    }
}
