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
    implicitHeight: 56
    radius: 18
    color: interaction.fill
    border.color: selected ? style.border : interaction.outline
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
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        IconImage {
            implicitSize: 32
            source: Quickshell.iconPath(root.application.icon || "application-x-executable",
                "application-x-executable")
        }

        Text {
            Layout.fillWidth: true
            text: root.application.name
            color: style.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
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
