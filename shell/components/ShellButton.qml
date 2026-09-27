import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    ControlStyle { id: theme }
    padding: theme.spacingSmall
    implicitHeight: Theme.buttonHeight
    implicitWidth: contentItem.implicitWidth + padding * 2
    Accessible.name: text
    hoverEnabled: true
    property bool selected: false
    property bool prominent: false
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
        color: root.prominent && !root.down && !root.hovered ? Theme.selected : interaction.fill
        border.color: root.visualFocus ? interaction.outline : root.prominent ? Theme.borderStrong : "transparent"
        border.width: Theme.borderWidth
    }
    contentItem: ShellText {
        text: root.text
        textFormat: Text.PlainText
        color: root.enabled ? theme.text : theme.secondary
        font.pixelSize: Theme.fontLabel
        font.weight: Theme.weightLabel
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
