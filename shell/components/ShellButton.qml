import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    ControlStyle { id: theme }
    padding: theme.spacingSmall
    implicitHeight: 32
    implicitWidth: contentItem.implicitWidth + padding * 2
    Accessible.name: text
    background: Rectangle {
        radius: theme.radiusSmall
        color: root.down ? theme.highlight : root.hovered ? theme.tile : "transparent"
        border.color: root.visualFocus ? theme.accent : "transparent"
    }
    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        color: root.enabled ? theme.text : theme.secondary
        opacity: root.enabled ? 1 : 0.5
        font.pixelSize: theme.fontSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
