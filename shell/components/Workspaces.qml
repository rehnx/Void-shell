pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    ControlStyle { id: palette }
    spacing: Theme.spacingTiny

    Repeater {
        model: [1, 2, 3, 4, 5]

        delegate: ShellButton {
            id: workspaceButton

            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(function(candidate) {
                return candidate.id === modelData;
            })

            implicitWidth: Theme.workspaceWidth
            implicitHeight: Theme.workspaceHeight
            padding: 0
            selected: !!workspace && workspace.focused
            Accessible.name: "Workspace " + modelData
            onClicked: Hyprland.dispatch("workspace " + modelData)

            contentItem: ShellText {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: workspaceButton.modelData
                color: workspaceButton.selected ? Theme.accent : palette.secondary
                font.pixelSize: Theme.fontCaption
            }
        }
    }
}
