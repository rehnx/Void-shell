import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var application
    property bool selected: false

    signal activated()

    ControlStyle { id: style }
    implicitHeight: Theme.appRowHeight
    radius: Theme.radiusMedium
    color: interaction.fill
    border.color: activeFocus ? interaction.outline : selected ? style.border : "transparent"
    scale: interaction.feedbackScale
    opacity: interaction.contentOpacity
    transform: Translate { y: interaction.lift }
    InteractionMotion {
        id: interaction
        hovered: pointer.containsMouse
        pressed: pointer.pressed
        focused: root.activeFocus
        selected: root.selected
        interactive: root.enabled
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingCompact
        anchors.rightMargin: Theme.spacingCompact
        spacing: Theme.spacingCompact

        IconImage {
            implicitSize: Theme.iconApplication
            source: Quickshell.iconPath(root.application.icon || "application-x-executable",
                "application-x-executable")
        }

        ShellText {
            Layout.fillWidth: true
            text: root.application.name
            color: style.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontBody
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
