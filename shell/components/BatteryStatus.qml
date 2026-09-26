import QtQuick
import Quickshell.Services.UPower

Item {
    id: root
    ControlStyle { id: style }

    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery && battery.ready && battery.isPresent && battery.isLaptopBattery

    visible: available
    implicitWidth: available ? label.implicitWidth : 0
    implicitHeight: label.implicitHeight

    Text {
        id: label

        anchors.centerIn: parent
        text: root.available ? "Bat " + Math.round(root.battery.percentage * 100) + "%" : ""
        color: style.text
        font.pixelSize: 13
    }
}
