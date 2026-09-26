import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "components"

PanelWindow {
    id: root
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
        visible = false;
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
        visible = !visible;
    }

    screen: targetScreen
    visible: false
    color: "#25081222"
    BackgroundEffect.blurRegion: Region { item: launcherSurface; radius: 28 }
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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

    onVisibleChanged: {
        if (!visible)
            return;

        searchInput.text = "";
        selectedIndex = filteredApplications.length > 0 ? 0 : -1;
        Qt.callLater(function() {
            searchInput.forceActiveFocus();
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

    GlassSurface {
        id: launcherSurface
        width: Math.min(parent.width - 32, 600)
        height: Math.min(parent.height - 80, 520)
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
            anchors.margins: 22
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Applications"; color: style.text; font.pixelSize: 23; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                Text { text: "VOID SHELL"; color: style.secondary; font.pixelSize: 10; font.letterSpacing: 2 }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 24
                color: "#4011233c"
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: style.accent

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    color: style.text
                    selectionColor: style.accent
                    selectedTextColor: "#152c48"
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 15
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

                    Text {
                        anchors.fill: parent
                        text: "Search applications…"
                        color: style.secondary
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 15
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
                    spacing: 6
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

                Text {
                    anchors.centerIn: parent
                    text: searchInput.text.trim().length > 0
                        ? "No applications found"
                        : "No applications installed"
                    color: style.secondary
                    font.pixelSize: 14
                    visible: root.filteredApplications.length === 0
                }
            }
        }
    }
}
