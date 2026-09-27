import QtQuick
import Quickshell.Hyprland

Item {
    id: root
    ControlStyle { id: style }

    readonly property string windowTitle: Hyprland.activeToplevel && Hyprland.activeToplevel.title
        ? Hyprland.activeToplevel.title
        : "Desktop"

    implicitWidth: Math.min(title.implicitWidth, Theme.activeWindowMaximumWidth)
    implicitHeight: title.implicitHeight

    ShellText {
        id: title

        anchors.fill: parent
        text: root.windowTitle
        color: style.text
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Theme.fontLabel
    }
}
