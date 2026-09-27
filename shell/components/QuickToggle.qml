import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: root
    required property string title
    required property string status
    property string symbol: ""
    property bool active: false
    implicitHeight: 144
    implicitWidth: 160
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
    background: GlassSurface {
        radius: 26
        border.color: root.visualFocus ? style.accent : root.hovered ? "#7089b4fa" : style.border
        Behavior on border.color { MotionColorAnimation {} }
    }
    contentItem: ColumnLayout {
        spacing: 6
        anchors.margins: 14
        Rectangle {
            implicitWidth: 52; implicitHeight: 52; radius: 26
            color: root.active ? "#f4faff" : "#3096cee8"
            Behavior on color { MotionColorAnimation {} }
            ControlIcon {
                anchors.centerIn: parent
                width: 25; height: 25
                name: root.symbol
                ink: root.active ? "#159bd9" : style.text
            }
        }
        Text { text: root.title; color: style.text; font.pixelSize: 14; font.weight: Font.DemiBold }
        Text { Layout.fillWidth: true; text: root.status; elide: Text.ElideRight; color: style.secondary; font.pixelSize: 12 }
    }
    padding: 14
}
