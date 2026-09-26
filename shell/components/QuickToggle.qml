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
    scale: down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }
    background: GlassSurface {
        radius: 26
        border.color: root.visualFocus ? style.accent : root.hovered ? "#7089b4fa" : style.border
        opacity: root.enabled ? 1 : 0.5
    }
    contentItem: ColumnLayout {
        spacing: 6
        anchors.margins: 14
        Rectangle {
            implicitWidth: 52; implicitHeight: 52; radius: 26
            color: root.active ? "#f4faff" : "#3096cee8"
            Behavior on color { ColorAnimation { duration: style.duration } }
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
