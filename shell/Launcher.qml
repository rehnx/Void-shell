import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "components"

PanelWindow {
    id: root

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
    color: "#99000000"
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

    Rectangle {
        width: Math.min(parent.width - 32, 600)
        height: Math.min(parent.height - 80, 520)
        anchors.centerIn: parent
        radius: 10
        color: "#1e1e2e"
        border.width: 1
        border.color: "#45475a"

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                mouse.accepted = true;
                searchInput.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 7
                color: "#313244"
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: "#89b4fa"

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    color: "#cdd6f4"
                    selectionColor: "#89b4fa"
                    selectedTextColor: "#1e1e2e"
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
                        color: "#6c7086"
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
                    spacing: 3
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
                    color: "#a6adc8"
                    font.pixelSize: 14
                    visible: root.filteredApplications.length === 0
                }
            }
        }
    }
}
