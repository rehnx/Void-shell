import QtQuick
import QtQuick.Layouts

CardSurface {
    id: root
    required property string title
    required property string status
    property real value: 0
    property real minimum: 0
    signal adjusted(real value)
    implicitHeight: Theme.sliderCardHeight
    radius: Theme.radiusMedium
    opacity: interaction.contentOpacity
    InteractionMotion {
        id: interaction
        hovered: slider.hovered
        pressed: slider.pressed
        focused: slider.visualFocus
        interactive: root.enabled
    }
    ControlStyle { id: style }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingSmall
        RowLayout {
            spacing: Theme.spacingSmall
            Layout.fillWidth: true
            ControlIcon { name: root.title === "Brightness" ? "sun" : "volume"; ink: style.text; implicitWidth: Theme.iconSmall; implicitHeight: Theme.iconSmall }
            ShellText { Layout.fillWidth: true; text: root.title; elide: Text.ElideRight; color: style.text; font.pixelSize: Theme.fontBody; font.weight: Theme.weightTitle }
            ShellText { Layout.maximumWidth: Math.max(0, (root.width - Theme.cardPadding * 2) / 2); elide: Text.ElideRight; text: root.status; color: style.secondary; font.pixelSize: Theme.fontCaption }
        }
        ShellSlider {
            id: slider
            hoverEnabled: true
            Layout.fillWidth: true
            from: root.minimum
            to: 1
            value: root.value
            stepSize: 0.01
            Accessible.name: root.title
            onMoved: root.adjusted(value)
        }
    }
}
