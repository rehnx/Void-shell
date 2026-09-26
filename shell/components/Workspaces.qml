pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    ControlStyle { id: palette }
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
            radius: 11
            color: workspace && workspace.focused ? palette.text : "#158edbff"
            Behavior on color { ColorAnimation { duration: palette.duration } }

            Text {
                anchors.centerIn: parent
                text: workspaceButton.modelData
                color: workspaceButton.workspace && workspaceButton.workspace.focused ? "#234967" : palette.text
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + workspaceButton.modelData)
            }
        }
    }
}
