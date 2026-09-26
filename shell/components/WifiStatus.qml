import QtQuick
import Quickshell.Networking

Item {
    id: root
    ControlStyle { id: style }

    readonly property var wifiDevice: Networking.devices.values.find(function(device) {
        return device.type === DeviceType.Wifi;
    })
    readonly property var activeNetwork: wifiDevice
        ? wifiDevice.networks.values.find(function(network) { return network.connected; })
        : null
    readonly property string statusText: !wifiDevice
        ? "Wi-Fi --"
        : !Networking.wifiEnabled
            ? "Wi-Fi off"
            : activeNetwork
                ? "Wi-Fi " + activeNetwork.name + " " + Math.round(activeNetwork.signalStrength) + "%"
                : "Wi-Fi disconnected"

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label

        anchors.centerIn: parent
        text: root.statusText
        color: style.text
        font.pixelSize: 13
    }
}
