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
    property real reveal: opened ? 1 : 0
    ControlStyle { id: theme }
    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
    }
    function close() { opened = false; }
    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: opened || reveal > 0
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Behavior on reveal { NumberAnimation { duration: theme.duration; easing.type: Easing.OutCubic } }
    onOpenedChanged: if (opened) Qt.callLater(() => focusRoot.forceActiveFocus())
    GlobalShortcut { appid: root.shortcutAppId; name: "calendar"; onPressed: root.toggle(null) }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    FocusScope {
        id: focusRoot
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        GlassSurface {
            width: Math.min(390, parent.width - theme.spacingMedium * 2)
            height: calendar.implicitHeight + theme.spacingMedium * 2
            x: parent.width - width - theme.spacingMedium
            y: theme.panelTop - 8 * (1 - root.reveal)
            opacity: root.reveal
            scale: 0.98 + 0.02 * root.reveal
            transformOrigin: Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            Calendar {
                id: calendar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.spacingMedium
            }
        }
    }
}
