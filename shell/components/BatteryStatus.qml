import QtQuick

Item {
    id: root
    required property var service
    ControlStyle { id: style }

    readonly property bool available: service.batteryAvailable

    visible: available
    implicitWidth: available ? label.implicitWidth : 0
    implicitHeight: label.implicitHeight

    ShellText {
        id: label

        anchors.centerIn: parent
        text: root.available
            ? "Bat " + Math.round(root.service.batteryPercentage * 100) + "% · "
                + root.service.batteryStatus
            : ""
        color: style.text
        font.pixelSize: Theme.fontLabel
    }
}
