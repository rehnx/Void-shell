import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    ControlStyle { id: theme }
    padding: theme.spacingSmall
    implicitHeight: 32
    implicitWidth: contentItem.implicitWidth + padding * 2
    Accessible.name: text
    hoverEnabled: true
    property bool selected: false
    scale: interaction.feedbackScale
    opacity: interaction.contentOpacity
    transform: Translate { y: interaction.lift }
    InteractionMotion {
        id: interaction
        hovered: root.hovered
        pressed: root.down
        focused: root.visualFocus
        selected: root.selected
        interactive: root.enabled
    }
    background: Rectangle {
        radius: theme.radiusSmall
        color: interaction.fill
        border.color: interaction.outline
    }
    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        color: root.enabled ? theme.text : theme.secondary
        font.pixelSize: theme.fontSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
