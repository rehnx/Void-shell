import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: root
    required property string title
    required property string status
    property string symbol: ""
    property bool active: false
    implicitHeight: Theme.toggleHeight
    implicitWidth: Theme.toggleWidth
    Accessible.name: title + ": " + status
    ControlStyle { id: style }
    hoverEnabled: true
    scale: interaction.feedbackScale
    opacity: interaction.contentOpacity
    transform: Translate { y: interaction.lift }
    InteractionMotion {
        id: interaction
        hovered: root.hovered
        pressed: root.down
        focused: root.visualFocus
        selected: root.active
        interactive: root.enabled
    }
    background: CardSurface {
        radius: Theme.radiusMedium
        tint: root.down ? Theme.pressed : root.active ? Theme.selected : Theme.surfaceCard
        border.color: root.visualFocus ? style.accent : root.hovered || root.active ? Theme.borderStrong : style.border
        Behavior on tint { MotionColorAnimation {} }
        Behavior on border.color { MotionColorAnimation {} }
    }
    contentItem: ColumnLayout {
        spacing: Theme.spacingSmall
        anchors.margins: Theme.spacingMedium
        Rectangle {
            implicitWidth: Theme.toggleIconSize; implicitHeight: Theme.toggleIconSize; radius: width / 2
            color: root.active ? Theme.accent : Theme.surfaceInset
            Behavior on color { MotionColorAnimation {} }
            ControlIcon {
                anchors.centerIn: parent
                width: Theme.iconLarge; height: Theme.iconLarge
                name: root.symbol
                ink: root.active ? Theme.textOnAccent : style.text
            }
        }
        ShellText { Layout.fillWidth: true; text: root.title; color: style.text; elide: Text.ElideRight; font.pixelSize: Theme.fontBody; font.weight: Theme.weightTitle }
        ShellText { Layout.fillWidth: true; text: root.status; elide: Text.ElideRight; color: style.secondary; font.pixelSize: Theme.fontCaption }
    }
    padding: Theme.spacingMedium
}
