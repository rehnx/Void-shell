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
    // Keep snapshots until their exit completes. Replacements preserve delegates.
    readonly property int retainedCount: toastModel.count
    property real retainedHeight: 0
    function trimHeight() {
        if (!reflow.running)
            retainedHeight = stack.implicitHeight + theme.spacingMedium * 2;
    }
    ListModel { id: toastModel; dynamicRoles: true }
    function syncToasts() {
        const desired = suppressed ? [] : service.toasts;
        for (let index = 0; index < toastModel.count; index++) {
            const row = toastModel.get(index);
            toastModel.setProperty(index, "active", desired.some(entry => entry.id === row.key));
        }
        for (let index = 0; index < desired.length; index++) {
            const entry = desired[index];
            let found = -1;
            for (let row = 0; row < toastModel.count; row++) {
                if (toastModel.get(row).key === entry.id) { found = row; break; }
            }
            if (found < 0) toastModel.insert(index, { key: entry.id, snapshot: entry, active: true });
            else {
                toastModel.set(found, { key: entry.id, snapshot: entry, active: true });
                if (found !== index) toastModel.move(found, index, 1);
            }
        }
        Qt.callLater(pruneHidden);
    }
    function pruneHidden() {
        for (let index = toastModel.count - 1; index >= 0; index--) {
            const item = toastRepeater.itemAt(index) as AnimatedVisibility;
            if (!toastModel.get(index).active && item && !item.present)
                toastModel.remove(index);
        }
    }
    onSuppressedChanged: syncToasts()
    Component.onCompleted: syncToasts()
    Connections { target: root.service; function onToastsChanged() { root.syncToasts(); } }
    ControlStyle { id: theme }
    screen: Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: toastModel.count > 0
    color: "transparent"
    implicitWidth: Math.min(theme.panelWidth, screen ? screen.width : theme.panelWidth)
    // Keep the native window large enough while remaining cards slide upward.
    implicitHeight: Math.max(retainedHeight, stack.implicitHeight + theme.spacingMedium * 2)
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    anchors { top: !Theme.barAtBottom; bottom: Theme.barAtBottom; right: true }
    margins {
        top: Theme.barAtBottom ? 0 : Theme.panelTop
        bottom: Theme.barAtBottom ? Theme.panelTop : 0
        right: Theme.spacingMedium
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Column {
        id: stack
        anchors.fill: parent
        anchors.margins: theme.spacingMedium
        spacing: theme.spacingSmall
        onImplicitHeightChanged: {
            root.retainedHeight = Math.max(root.retainedHeight, implicitHeight + theme.spacingMedium * 2);
            Qt.callLater(root.trimHeight);
        }
        move: Transition {
            id: reflow
            onRunningChanged: if (!running) Qt.callLater(root.trimHeight)
            MotionAnimation { properties: "x,y"; duration: Motion.expand }
        }
        Repeater {
            id: toastRepeater
            model: toastModel
            AnimatedVisibility {
                required property var snapshot
                required property bool active
                width: stack.width
                height: card.implicitHeight
                shown: active
                onHidden: Qt.callLater(root.pruneHidden)
                NotificationCard {
                    id: card
                    anchors.fill: parent
                    entry: parent.snapshot
                    compact: true
                    elevated: true
                    elevation: parent.progress
                    onDismissed: root.service.dismiss(entry.id)
                }
            }
        }
    }
}
