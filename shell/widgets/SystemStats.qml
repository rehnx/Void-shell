import QtQuick
import QtQuick.Layouts
import "../components"

RowLayout {
    id: root
    required property var service
    spacing: theme.spacingSmall
    ControlStyle { id: theme }
    Text { text: "CPU " + Math.round(root.service.cpuUsage * 100) + "%"; color: theme.text; font.pixelSize: theme.fontSmall }
    Text { text: "RAM " + Math.round(root.service.memoryUsage * 100) + "%"; color: theme.text; font.pixelSize: theme.fontSmall }
    Text {
        visible: root.service.temperatureAvailable
        text: Math.round(root.service.temperature) + "°C"
        color: theme.text
        font.pixelSize: theme.fontSmall
    }
    BatteryStatus {
        service: root.service
    }
}
