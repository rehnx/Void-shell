pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: root
    required property var service
    property bool suppressed: false
    ControlStyle { id: theme }
    screen: Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: !suppressed && service.toasts.length > 0
    color: "transparent"
    implicitWidth: Math.min(theme.panelWidth, screen ? screen.width : theme.panelWidth)
    implicitHeight: stack.implicitHeight + theme.spacingMedium * 2
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: theme.panelTop; right: theme.spacingMedium }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Column {
        id: stack
        anchors.fill: parent
        anchors.margins: theme.spacingMedium
        spacing: theme.spacingSmall
        Repeater {
            model: root.service.toasts
            NotificationCard {
                required property var modelData
                width: stack.width
                entry: modelData
                compact: true
                opacity: 0
                Component.onCompleted: toastEnter.start()
                NumberAnimation on opacity {
                    id: toastEnter
                    running: false
                    from: 0
                    to: 1
                    duration: theme.duration
                    easing.type: Easing.OutCubic
                }
                onDismissed: root.service.dismiss(entry.id)
            }
        }
    }
}
