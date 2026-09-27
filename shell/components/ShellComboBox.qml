pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    hoverEnabled: true
    implicitHeight: Theme.inputHeight
    leftPadding: Theme.spacingCompact
    rightPadding: Theme.spacingXLarge
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    opacity: interaction.contentOpacity
    scale: interaction.feedbackScale
    InteractionMotion {
        id: interaction
        hovered: root.hovered
        pressed: root.down
        focused: root.visualFocus
        interactive: root.enabled
    }
    background: Rectangle {
        radius: Theme.radiusSmall
        color: root.enabled && (root.down || root.hovered) ? interaction.fill : Theme.surfaceInset
        border.color: root.enabled && root.visualFocus ? interaction.outline : Theme.border
        Behavior on color { MotionColorAnimation {} }
        Behavior on border.color { MotionColorAnimation {} }
    }
    contentItem: ShellText {
        text: root.displayText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: ShellText {
        x: root.width - width - Theme.spacingCompact
        y: (root.height - height) / 2
        text: "⌄"
        color: Theme.textSecondary
    }
    delegate: ItemDelegate {
        id: option
        required property int index
        required property var modelData
        width: root.popup.availableWidth
        highlighted: root.highlightedIndex === index
        contentItem: ShellText { text: String(option.modelData); elide: Text.ElideRight }
        background: Rectangle {
            radius: Theme.radiusSmall
            color: option.highlighted ? Theme.selected : option.hovered ? Theme.hover : "transparent"
            Behavior on color { MotionColorAnimation {} }
        }
    }
    popup: Popup {
        y: root.height + Theme.spacingTiny
        width: root.width
        padding: Theme.spacingSmall
        implicitHeight: Math.min(contentItem.implicitHeight + padding * 2, Theme.panelHeight / 2)
        background: CardSurface { elevated: true }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        enter: Transition { MotionAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.enter } }
        exit: Transition { MotionAnimation { property: "opacity"; to: 0; duration: Motion.exit } }
    }
}
