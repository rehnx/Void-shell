pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root
    required property var service
    ControlStyle { id: theme }
    screen: Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: surface.present
    color: "transparent"
    implicitWidth: Theme.osdWidth
    implicitHeight: Theme.osdHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins.bottom: Theme.osdBottom
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    PopupSurface {
        id: surface
        shown: Settings.osdEnabled && root.service.osdVisible
        direction: 1
        anchors.fill: parent
        anchors.margins: theme.spacingSmall
        Row {
            anchors.fill: parent
            anchors.margins: theme.spacingMedium
            spacing: theme.spacingMedium
            ShellText {
                width: Theme.iconLarge
                anchors.verticalCenter: parent.verticalCenter
                text: root.service.osdKind === "brightness" ? "☀" : root.service.osdKind === "microphone" ? "●" : "♪"
                color: theme.text
                font.pixelSize: Theme.fontTitle
            }
            Column {
                width: parent.width - Theme.iconLarge - Theme.spacingMedium
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.spacingSmall
                ShellText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.service.osdLabel + (root.service.osdMuted ? " muted" : "  " + Math.round(root.service.osdValue * 100) + "%")
                    color: theme.text
                    font.pixelSize: theme.fontSmall
                }
                Rectangle {
                    width: parent.width
                    height: Theme.sliderTrackHeight
                    radius: height / 2
                    color: theme.depth
                    Rectangle {
                        width: root.service.osdMuted ? 0 : parent.width * root.service.osdValue
                        height: parent.height
                        radius: parent.radius
                        color: theme.accent
                        Behavior on width { MotionAnimation {} }
                    }
                }
            }
        }
    }
}
