import QtQuick
import QtQuick.Controls

Slider {
    id: root
    hoverEnabled: true
    implicitHeight: Theme.buttonHeight
    leftPadding: Theme.spacingTiny
    rightPadding: Theme.spacingTiny
    InteractionMotion {
        id: interaction
        hovered: root.hovered
        pressed: root.pressed
        focused: root.visualFocus
        interactive: root.enabled
    }
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: Theme.sliderTrackHeight
        radius: height / 2
        color: Theme.surfaceInset
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.enabled ? Theme.accent : Theme.textMuted
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        width: Theme.sliderHandleSize
        height: width
        radius: width / 2
        color: !root.enabled ? Theme.textMuted : root.pressed || root.hovered ? Theme.accent : Theme.textPrimary
        Behavior on color { MotionColorAnimation {} }
        scale: interaction.feedbackScale
        border.width: Theme.focusWidth
        border.color: interaction.outline
    }
}
