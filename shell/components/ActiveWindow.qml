import QtQuick
import Quickshell.Hyprland

Item {
    id: root
    ControlStyle { id: style }

    readonly property string windowTitle: Hyprland.activeToplevel && Hyprland.activeToplevel.title
        ? Hyprland.activeToplevel.title
        : "Desktop"

    implicitWidth: Math.min(title.implicitWidth, 360)
    implicitHeight: title.implicitHeight

    Text {
        id: title

        anchors.fill: parent
        text: root.windowTitle
        color: style.text
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 13
    }
}
