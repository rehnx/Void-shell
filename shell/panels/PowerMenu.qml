pragma ComponentBehavior: Bound

import QtQuick
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
    property string shortcutAppId: "quickshell"
    property string pendingAction: ""
    // Preserve the closing frame after the logical action is cleared.
    property string displayedAction: ""
    onPendingActionChanged: if (opened) displayedAction = pendingAction
    readonly property real reveal: surface.progress
    readonly property var actions: [
        { name: "lock", label: "Lock", confirm: false },
        { name: "suspend", label: "Suspend", confirm: false },
        { name: "logout", label: "Log out", confirm: true },
        { name: "reboot", label: "Restart", confirm: true },
        { name: "shutdown", label: "Shut down", confirm: true }
    ]
    ControlStyle { id: theme }

    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
        if (!opened) pendingAction = "";
    }
    function close() { opened = false; pendingAction = ""; }
    function request(action) {
        const item = actions.find(candidate => candidate.name === action);
        if (!item) return;
        if (item.confirm) pendingAction = action;
        else {
            service.performPowerAction(action);
            close();
        }
    }
    function confirm() {
        if (!pendingAction) return;
        const action = pendingAction;
        close();
        service.performPowerAction(action);
    }

    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: surface.present
    color: Qt.rgba(0, 0, 0, 0.145 * surface.progress)
    exclusiveZone: 0
    // Release pointer input immediately while the exit remains on screen.
    mask: Region { width: root.opened ? root.width : 0; height: root.opened ? root.height : 0 }
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: if (opened) {
        displayedAction = pendingAction;
        Qt.callLater(() => { if (root.opened) focusRoot.forceActiveFocus(); });
    }
    GlobalShortcut { appid: root.shortcutAppId; name: "powerMenu"; onPressed: root.toggle(null) }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    FocusScope {
        id: focusRoot
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        FloatingSurface {
            id: surface
            shown: root.opened
            animateGeometry: true
            width: Math.min(390, parent.width - theme.spacingMedium * 2)
            height: content.implicitHeight + theme.spacingMedium * 2
            anchors.centerIn: parent
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.spacingMedium
                spacing: theme.spacingMedium
                Text {
                    Layout.fillWidth: true
                    text: root.displayedAction ? "Confirm " + root.displayedAction : "Power"
                    color: theme.text
                    font.pixelSize: theme.fontHeading
                    horizontalAlignment: Text.AlignHCenter
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.displayedAction
                    Repeater {
                        model: root.actions
                        ShellButton {
                            required property var modelData
                            Layout.fillWidth: true
                            text: modelData.label
                            onClicked: root.request(modelData.name)
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: !!root.displayedAction
                    text: "This will end the current session or interrupt running work."
                    wrapMode: Text.Wrap
                    color: theme.secondary
                    font.pixelSize: theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: !!root.displayedAction
                    ShellButton { Layout.fillWidth: true; text: "Cancel"; onClicked: root.pendingAction = "" }
                    ShellButton { Layout.fillWidth: true; text: "Confirm"; onClicked: root.confirm() }
                }
            }
        }
    }
}
