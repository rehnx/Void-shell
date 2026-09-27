pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../widgets"

PanelWindow {
    id: root
    property var requestedScreen: null
    property bool opened: false
    property string shortcutAppId: "quickshell"
    readonly property real reveal: surface.progress
    ControlStyle { id: theme }
    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
    }
    function close() { opened = false; }
    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: surface.present
    color: "transparent"
    exclusiveZone: 0
    // Release pointer input immediately while the exit remains on screen.
    mask: Region { width: root.opened ? root.width : 0; height: root.opened ? root.height : 0 }
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: if (opened) Qt.callLater(() => focusRoot.forceActiveFocus())
    GlobalShortcut { appid: root.shortcutAppId; name: "calendar"; onPressed: root.toggle(null) }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    FocusScope {
        id: focusRoot
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        PanelSurface {
            id: surface
            shown: root.opened
            width: Math.min(Theme.panelCompactWidth, parent.width - Theme.spacingMedium * 2)
            height: Math.min(calendar.implicitHeight + Theme.panelPadding * 2, parent.height - Theme.panelTop - Theme.spacingMedium)
            x: parent.width - width - theme.spacingMedium
            y: theme.panelTop
            transformOrigin: Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            PanelScrollArea {
                naturalHeight: calendar.implicitHeight
                Calendar {
                    id: calendar
                    width: parent.width
                }
            }
        }
    }
}
