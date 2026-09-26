pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: root
    required property var service
    property var requestedScreen: null
    property bool opened: false
    property real reveal: opened ? 1 : 0
    ControlStyle { id: theme }
    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
    }
    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: opened || reveal > 0
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Behavior on reveal { NumberAnimation { duration: theme.duration; easing.type: Easing.OutCubic } }
    onOpenedChanged: {
        if (opened) {
            service.hideToasts();
            Qt.callLater(() => closeButton.forceActiveFocus());
        }
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "notifications"
        description: "Toggle Void Shell notification history"
        onPressed: root.toggle(null)
    }
    MouseArea { anchors.fill: parent; onClicked: root.opened = false }
    FocusScope {
        anchors.fill: parent
        Keys.onEscapePressed: root.opened = false
        GlassSurface {
            width: Math.min(theme.panelWidth, parent.width - theme.spacingMedium * 2)
            height: Math.min(theme.panelHeight, parent.height - theme.panelTop - theme.spacingMedium)
            x: parent.width - width - theme.spacingMedium
            y: theme.panelTop - 8 * (1 - root.reveal)
            opacity: root.reveal
            scale: 0.98 + 0.02 * root.reveal
            transformOrigin: Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.spacingMedium
                spacing: theme.spacingMedium
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "Notifications"; color: theme.text; font.pixelSize: theme.fontHeading }
                    ShellButton { text: "Clear all"; enabled: root.service.count > 0; onClicked: root.service.clearAll() }
                    ShellButton { id: closeButton; text: "×"; Accessible.name: "Close notifications"; onClicked: root.opened = false }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        id: historyList
                        anchors.fill: parent
                        clip: true
                        spacing: theme.spacingSmall
                        model: root.service.history
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        delegate: NotificationCard {
                            required property var modelData
                            width: historyList.width
                            entry: modelData
                            onDismissed: root.service.dismiss(entry.id)
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.service.count === 0
                        text: "No notifications yet"
                        color: theme.secondary
                        font.pixelSize: theme.fontBody
                    }
                }
            }
        }
    }
}
