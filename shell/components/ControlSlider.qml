import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GlassSurface {
    id: root
    required property string title
    required property string status
    property real value: 0
    property real minimum: 0
    signal adjusted(real value)
    implicitHeight: 100
    radius: 26
    opacity: enabled ? 1 : 0.5
    ControlStyle { id: style }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            ControlIcon { name: root.title === "Brightness" ? "sun" : "volume"; ink: style.text; implicitWidth: 18; implicitHeight: 18 }
            Text { text: root.title; color: style.text; font.pixelSize: 14; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Text { text: root.status; color: style.secondary; font.pixelSize: 12 }
        }
        Slider {
            id: slider
            Layout.fillWidth: true
            from: root.minimum
            to: 1
            value: root.value
            stepSize: 0.01
            Accessible.name: root.title
            onMoved: root.adjusted(value)
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: slider.availableWidth
                height: 12
                radius: 6
                color: "#50102038"
                Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 6; color: "#e5f6ff" }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: 20; height: 20; radius: 10
                color: style.text
                border.width: slider.visualFocus ? 2 : 0
                border.color: style.accent
            }
        }
    }
}
