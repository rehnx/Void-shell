import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "components"

PanelWindow {
    id: root
    property bool opened: false
    readonly property real reveal: launcherSurface.progress
    ControlStyle { id: style }

    readonly property var targetScreen: {
        const monitor = Hyprland.focusedMonitor;
        const screens = Quickshell.screens;

        if (monitor) {
            for (let index = 0; index < screens.length; index++) {
                if (screens[index].name === monitor.name)
                    return screens[index];
            }
        }

        return screens.length > 0 ? screens[0] : null;
    }
    readonly property var filteredApplications: {
        const query = searchInput.text.trim().toLowerCase();
        const applications = DesktopEntries.applications.values.filter(function(application) {
            if (application.noDisplay)
                return false;

            if (query.length === 0)
                return true;

            const searchable = (application.name + " " + application.genericName + " "
                + application.comment).toLowerCase();
            return searchable.includes(query);
        });

        applications.sort(function(left, right) {
            return left.name.localeCompare(right.name);
        });
        return applications;
    }
    property int selectedIndex: filteredApplications.length > 0 ? 0 : -1

    function closeLauncher() {
        opened = false;
    }

    function launchSelected() {
        if (selectedIndex < 0 || selectedIndex >= filteredApplications.length)
            return;

        const application = filteredApplications[selectedIndex];
        closeLauncher();
        application.execute();
    }

    function moveSelection(offset) {
        if (filteredApplications.length === 0)
            return;

        selectedIndex = (selectedIndex + offset + filteredApplications.length)
            % filteredApplications.length;
        appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function toggle() {
        opened = !opened;
    }

    screen: targetScreen
    visible: launcherSurface.present
    color: Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, Theme.scrimOpacity * launcherSurface.progress)
    BackgroundEffect.blurRegion: Region { x: launcherSurface.x; y: launcherSurface.y; width: Theme.blurEnabled ? launcherSurface.width : 0; height: launcherSurface.height; radius: launcherSurface.radius }
    exclusiveZone: 0
    // Release pointer input immediately while the exit remains on screen.
    mask: Region { width: root.opened ? root.width : 0; height: root.opened ? root.height : 0 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the RehanShell application launcher"
        onPressed: root.toggle()
    }

    onOpenedChanged: {
        if (!opened)
            return;

        searchInput.text = "";
        selectedIndex = filteredApplications.length > 0 ? 0 : -1;
        Qt.callLater(function() {
            if (root.opened) searchInput.forceActiveFocus();
        });
    }

    onFilteredApplicationsChanged: {
        selectedIndex = filteredApplications.length > 0 ? 0 : -1;
        Qt.callLater(function() {
            appList.positionViewAtBeginning();
        });
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeLauncher()
    }

    PanelSurface {
        id: launcherSurface
        shown: root.opened
        direction: 1
        width: Math.min(parent.width - Theme.spacingXLarge, Theme.launcherWidth)
        height: Math.min(parent.height - Theme.panelTop * 2, Theme.launcherHeight)
        anchors.centerIn: parent
        elevated: true

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                mouse.accepted = true;
                searchInput.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            spacing: Theme.spacingMedium

            RowLayout {
                spacing: Theme.spacingSmall
                Layout.fillWidth: true
                SectionHeader { Layout.fillWidth: true; text: "Applications"; role: "display" }
                Item { Layout.fillWidth: true }
                ShellText { text: "VOID SHELL"; color: style.secondary; font.pixelSize: Theme.fontCaption; font.letterSpacing: Theme.trackingLabel }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.inputHeight
                radius: Theme.radiusMedium
                color: Theme.surfaceInset
                border.width: Theme.borderWidth
                border.color: searchInput.activeFocus ? Theme.accent : Theme.border
                Behavior on border.color { MotionColorAnimation {} }

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingCompact
                    anchors.rightMargin: Theme.spacingCompact
                    color: style.text
                    selectionColor: style.accent
                    selectedTextColor: Theme.textOnAccent
                    font.family: Theme.fontFamily
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: Theme.fontBody
                    clip: true

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.closeLauncher();
                            event.accepted = true;
                        }
                    }

                    ShellText {
                        anchors.fill: parent
                        text: "Search applications…"
                        color: style.secondary
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Theme.fontBody
                        visible: searchInput.text.length === 0
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: appList

                    anchors.fill: parent
                    model: root.filteredApplications
                    spacing: Theme.spacingSmall
                    clip: true
                    currentIndex: root.selectedIndex

                    delegate: AppItem {
                        required property int index
                        required property var modelData

                        width: appList.width
                        application: modelData
                        selected: index === root.selectedIndex
                        onActivated: {
                            root.selectedIndex = index;
                            root.launchSelected();
                        }
                    }
                }

                ShellText {
                    anchors.centerIn: parent
                    text: searchInput.text.trim().length > 0
                        ? "No applications found"
                        : "No applications installed"
                    color: style.secondary
                    font.pixelSize: Theme.fontBody
                    visible: root.filteredApplications.length === 0
                }
            }
        }
    }
}
