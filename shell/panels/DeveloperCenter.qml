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
    property real preferredWidth: Theme.dimension(760)
    property bool pathsExpanded: false
    property string copyFeedback: ""
    readonly property real reveal: surface.progress

    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
    }
    function close() { opened = false; }
    function copyValue(label, value) {
        if (!value || value === "Unavailable") return false;
        Quickshell.clipboardText = value;
        copyFeedback = label + " copied";
        feedbackTimeout.restart();
        return true;
    }
    function folderUrl(path) {
        return path && path.startsWith("/") ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
    }
    function openFolder(path) {
        const url = folderUrl(path);
        if (url) Qt.openUrlExternally(url);
    }

    Binding { target: root.service; property: "developerActive"; value: root.opened }
    Timer { id: feedbackTimeout; interval: 1600; onTriggered: root.copyFeedback = "" }
    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor
        && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: surface.present
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region { width: root.opened ? root.width : 0; height: root.opened ? root.height : 0 }
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: {
        if (opened) Qt.callLater(() => { if (root.opened) focusRoot.forceActiveFocus(); });
        else { feedbackTimeout.stop(); copyFeedback = ""; }
    }
    GlobalShortcut {
        appid: root.shortcutAppId
        name: "developerCenter"
        description: "Toggle Void Shell Developer Center"
        onPressed: root.toggle(null)
    }
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    component Metric: CardSurface {
        id: metric
        property string label
        property string value
        property string detail
        property real level: -1
        implicitHeight: metricBody.implicitHeight + padding * 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        ColumnLayout {
            id: metricBody
            anchors.fill: parent
            anchors.margins: metric.padding
            spacing: Theme.spacingSmall
            ShellText { Layout.fillWidth: true; role: "caption"; text: metric.label; elide: Text.ElideRight }
            ShellText { Layout.fillWidth: true; role: "display"; text: metric.value; color: Theme.accent; elide: Text.ElideRight }
            ShellText { Layout.fillWidth: true; role: "caption"; text: metric.detail; elide: Text.ElideRight }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.sliderTrackHeight
                radius: height / 2
                color: Theme.surfaceInset
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, metric.level))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                    Behavior on width {
                        enabled: root.opened && Motion.spatial
                        MotionAnimation { duration: Motion.feedback }
                    }
                }
            }
        }
    }

    component Value: ShellButton {
        id: valueButton
        property string label
        property string value: "Unavailable"
        implicitHeight: contentItem.implicitHeight + padding * 2
        Layout.fillWidth: true
        Accessible.name: "Copy " + label + ": " + value
        onClicked: root.copyValue(label, value)
        contentItem: ColumnLayout {
            spacing: Theme.spacingTiny
            ShellText { Layout.fillWidth: true; role: "caption"; text: valueButton.label; elide: Text.ElideRight }
            ShellText { Layout.fillWidth: true; text: valueButton.value || "Unavailable"; wrapMode: Text.WrapAnywhere }
        }
    }

    FocusScope {
        id: focusRoot
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        PanelSurface {
            id: surface
            objectName: "developerSurface"
            shown: root.opened
            width: Math.min(root.preferredWidth, parent.width - Theme.spacingMedium * 2)
            height: Math.min(Theme.dimension(780), parent.height - Theme.panelTop - Theme.spacingMedium)
            x: parent.width - width - Theme.spacingMedium
            y: Theme.panelY(parent.height, height)
            direction: Theme.panelDirection
            transformOrigin: Theme.barAtBottom ? Item.BottomRight : Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.panelPadding
                spacing: Theme.spacingMedium
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingTiny
                        SectionHeader { Layout.fillWidth: true; text: "Developer Center" }
                        ShellText {
                            Layout.fillWidth: true
                            role: "caption"
                            text: root.service.hostname + " · Up " + root.service.formatUptime(root.service.uptimeSeconds)
                            elide: Text.ElideRight
                        }
                    }
                    ShellButton {
                        objectName: "developerRefresh"
                        text: surface.width > Theme.dimension(520) ? "Refresh" : "↻"
                        Accessible.name: "Refresh system information"
                        enabled: !root.service.developerRefreshing
                        onClicked: root.service.refreshDeveloper(true)
                    }
                    ShellButton { objectName: "developerClose"; text: "×"; Accessible.name: "Close Developer Center"; onClicked: root.close() }
                }
                Separator { Layout.fillWidth: true }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    PanelScrollArea {
                        id: scroll
                        objectName: "developerScroll"
                        anchors.margins: 0
                        naturalHeight: body.implicitHeight
                        ColumnLayout {
                            id: body
                            width: parent.width
                            spacing: Theme.spacingMedium
                            readonly property int columns: width >= Theme.dimension(560) ? 2 : 1
                            GridLayout {
                                Layout.fillWidth: true
                                columns: body.columns
                                columnSpacing: Theme.spacingSmall
                                rowSpacing: Theme.spacingSmall
                                Metric {
                                    label: "CPU"
                                    value: Math.round(root.service.cpuUsage * 100) + "%"
                                    detail: (root.service.temperatureAvailable ? root.service.temperature.toFixed(0) + " °C · " : "") + root.service.cpuModel
                                    level: root.service.cpuUsage
                                }
                                Metric {
                                    label: "Memory"
                                    value: root.service.memoryTotal > 0 ? Math.round(root.service.memoryUsage * 100) + "%" : "Unavailable"
                                    detail: root.service.memoryTotal > 0 ? root.service.formatBytes(root.service.memoryUsed) + " / " + root.service.formatBytes(root.service.memoryTotal) : "Memory information unavailable"
                                    level: root.service.memoryUsage
                                }
                                Metric {
                                    label: "Storage · /"
                                    readonly property var disk: root.service.disks.find(disk => disk.mount === "/") || root.service.disks[0]
                                    value: disk ? Math.round(disk.usage * 100) + "%" : "Unavailable"
                                    detail: disk ? root.service.formatBytes(disk.used) + " / " + root.service.formatBytes(disk.total) : "Disk information unavailable"
                                    level: disk ? disk.usage : -1
                                }
                                Metric {
                                    label: "Battery"
                                    value: root.service.batteryAvailable ? Math.round(root.service.batteryPercentage * 100) + "%" : "Unavailable"
                                    detail: root.service.batteryAvailable ? root.service.batteryStatus : "No battery detected"
                                    level: root.service.batteryAvailable ? root.service.batteryPercentage : -1
                                }
                            }
                            CardSurface {
                                Layout.fillWidth: true
                                implicitHeight: systemBody.implicitHeight + padding * 2
                                ColumnLayout {
                                    id: systemBody
                                    anchors.fill: parent; anchors.margins: Theme.cardPadding
                                    spacing: Theme.spacingSmall
                                    SectionHeader { Layout.fillWidth: true; text: "System & session" }
                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: body.columns
                                        columnSpacing: Theme.spacingSmall; rowSpacing: Theme.spacingTiny
                                        Value { label: "Distribution"; value: root.service.distro }
                                        Value { label: "Kernel"; value: root.service.kernel }
                                        Value { label: "Hostname"; value: root.service.hostname }
                                        Value { label: "Compositor / session"; value: root.service.sessionInfo }
                                        Value { label: "Workspace"; value: root.service.workspaceName }
                                        Value { label: "Active application"; value: root.service.windowApp }
                                        Value { Layout.columnSpan: body.columns; label: "Active window"; value: root.service.windowTitle }
                                    }
                                }
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: body.columns
                                columnSpacing: Theme.spacingSmall; rowSpacing: Theme.spacingSmall
                                CardSurface {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    implicitHeight: connectionBody.implicitHeight + padding * 2
                                    ColumnLayout {
                                        id: connectionBody
                                        anchors.fill: parent; anchors.margins: Theme.cardPadding
                                        spacing: Theme.spacingTiny
                                        SectionHeader { Layout.fillWidth: true; text: "Connections" }
                                        Value { label: "Network · " + root.service.networkStatus; value: root.service.networkDetail }
                                        Value { label: "Internet"; value: root.service.internetStatus }
                                        Value { label: "Audio · " + root.service.audioStatus; value: root.service.audioDevice }
                                        Value { label: "Microphone"; value: root.service.microphoneStatus }
                                    }
                                }
                                CardSurface {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    implicitHeight: processBody.implicitHeight + padding * 2
                                    ColumnLayout {
                                        id: processBody
                                        anchors.fill: parent; anchors.margins: Theme.cardPadding
                                        spacing: Theme.spacingTiny
                                        SectionHeader { Layout.fillWidth: true; text: "Processes" }
                                        Value {
                                            label: "Process summary"
                                            value: root.service.processSummary ? root.service.processSummary.total + " total · "
                                                + root.service.processSummary.running + " running" : "Unavailable"
                                        }
                                        Value {
                                            label: "State"
                                            value: root.service.processSummary ? root.service.processSummary.sleeping + " sleeping · "
                                                + root.service.processSummary.blocked + " blocked\n" + root.service.processSummary.stopped
                                                + " stopped · " + root.service.processSummary.zombies + " zombie" : "Unavailable"
                                        }
                                        Value { label: "Load average · 1 / 5 / 15 min"; value: root.service.loadAverage }
                                        Value { label: "Temperature"; value: root.service.temperatureAvailable ? root.service.temperature.toFixed(0) + " °C" : "Unavailable" }
                                    }
                                }
                            }
                            CardSurface {
                                Layout.fillWidth: true
                                implicitHeight: pathsBody.implicitHeight + padding * 2
                                ColumnLayout {
                                    id: pathsBody
                                    anchors.fill: parent; anchors.margins: Theme.cardPadding
                                    spacing: Theme.spacingSmall
                                    ShellButton {
                                        objectName: "developerPathsToggle"
                                        Layout.fillWidth: true
                                        text: "Paths & build  " + (root.pathsExpanded ? "−" : "+")
                                        onClicked: root.pathsExpanded = !root.pathsExpanded
                                    }
                                    ColumnLayout {
                                        visible: root.pathsExpanded
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingTiny
                                        Value { label: "Void Shell"; value: root.service.shellVersion + " · " + root.service.shellBuild }
                                        Value { label: "Runtime"; value: root.service.runtimeVersion }
                                        Repeater {
                                            model: root.service.developerPaths
                                            RowLayout {
                                                id: pathRow
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Value { label: pathRow.modelData.label; value: pathRow.modelData.value }
                                                ShellButton {
                                                    text: "Open"
                                                    enabled: !!root.folderUrl(pathRow.modelData.folder)
                                                    Accessible.name: "Open " + pathRow.modelData.label + " folder"
                                                    onClicked: root.openFolder(pathRow.modelData.folder)
                                                }
                                            }
                                        }
                                        Repeater {
                                            model: root.service.disks
                                            Value {
                                                required property var modelData
                                                label: "Disk · " + modelData.mount
                                                value: root.service.formatBytes(modelData.available) + " available / " + root.service.formatBytes(modelData.total)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                ShellText {
                    Layout.fillWidth: true
                    role: "caption"
                    text: root.copyFeedback || "Click a value to copy · Void Shell " + root.service.shellVersion
                    elide: Text.ElideRight
                    color: root.copyFeedback ? Theme.accent : Theme.textSecondary
                }
            }
        }
    }
}
