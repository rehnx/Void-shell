import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    spacing: 4

    Repeater {
        model: [1, 2, 3, 4, 5]

        delegate: Rectangle {
            id: workspaceButton

            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(function(candidate) {
                return candidate.id === modelData;
            })

            implicitWidth: 24
            implicitHeight: 22
            radius: 4
            color: workspace && workspace.focused ? "#89b4fa" : "transparent"

            Text {
                anchors.centerIn: parent
                text: workspaceButton.modelData
                color: workspaceButton.workspace && workspaceButton.workspace.focused ? "#1e1e2e" : "#cdd6f4"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + workspaceButton.modelData)
            }
        }
    }
}
