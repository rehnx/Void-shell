pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "components"

PanelWindow {
    id: root
    required property var systemService
    property bool opened: false
    readonly property real reveal: surface.progress
    property var requestedScreen: null
    readonly property var wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi) || null
    readonly property var network: wifi ? wifi.networks.values.find(network => network.connected) : null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: !!sink && sink.ready && !!sink.audio

    function toggle(target) {
        if (!opened) requestedScreen = target || null;
        opened = !opened;
    }
    function close() { opened = false; }

    screen: requestedScreen || Quickshell.screens.find(screen => Hyprland.focusedMonitor && screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    visible: surface.present
    color: "transparent"
    exclusiveZone: 0
    // Release pointer input immediately while the exit remains on screen.
    mask: Region { width: root.opened ? root.width : 0; height: root.opened ? root.height : 0 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    BackgroundEffect.blurRegion: Region { x: surface.x; y: surface.y; width: surface.width; height: surface.height; radius: surface.radius }
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    onOpenedChanged: {
        if (opened) {
            systemService.refreshBrightness();
            Qt.callLater(() => content.forceActiveFocus());
        }
    }
    ControlStyle { id: style }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    GlobalShortcut {
        appid: "quickshell"
        name: "controlCenter"
        description: "Toggle Void Shell Control Center"
        onPressed: root.toggle(null)
    }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    FocusScope {
        id: content
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        FloatingSurface {
            id: surface
            shown: root.opened
            width: Math.min(380, parent.width - 32)
            height: Math.min(body.implicitHeight + 40, parent.height - 64)
            x: parent.width - width - 16
            y: 60
            transformOrigin: Item.TopRight
            radius: 28
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            Flickable {
                anchors.fill: parent
                anchors.margins: 20
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 3
                            Text { text: "Control Center"; color: style.text; font.pixelSize: 22; font.weight: Font.DemiBold }
                            Text { text: "VOID SHELL"; color: style.secondary; font.pixelSize: 10; font.letterSpacing: 2 }
                        }
                        Item { Layout.fillWidth: true }
                        ShellButton {
                            id: closeButton
                            text: "×"
                            Accessible.name: "Close Control Center"
                            onClicked: root.close()
                            contentItem: Text { text: "×"; color: style.secondary; font.pixelSize: 25; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        QuickToggle {
                            Layout.fillWidth: true
                            title: "Wi-Fi"; symbol: "wifi"
                            active: !!root.wifi && Networking.wifiEnabled
                            enabled: !!root.wifi && Networking.wifiHardwareEnabled
                            status: !root.wifi ? "Unavailable" : !Networking.wifiHardwareEnabled ? "Hardware blocked" : !Networking.wifiEnabled ? "Off" : root.network ? root.network.name : "Disconnected"
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            title: "Bluetooth"; symbol: "bluetooth"
                            active: !!root.adapter && root.adapter.enabled
                            enabled: !!root.adapter && root.adapter.state !== BluetoothAdapterState.Blocked && root.adapter.state !== BluetoothAdapterState.Enabling && root.adapter.state !== BluetoothAdapterState.Disabling
                            status: !root.adapter ? "Unavailable" : BluetoothAdapterState.toString(root.adapter.state)
                            onClicked: root.adapter.enabled = !root.adapter.enabled
                        }
                    }
                    ControlSlider {
                        Layout.fillWidth: true
                        title: "Volume"
                        enabled: root.audioAvailable
                        value: root.audioAvailable ? root.sink.audio.volume : 0
                        status: !root.audioAvailable ? "Unavailable" : root.sink.audio.muted ? "Muted" : Math.round(root.sink.audio.volume * 100) + "%"
                        onAdjusted: value => {
                            if (!root.audioAvailable) return;
                            root.sink.audio.volume = value;
                            root.sink.audio.muted = false;
                        }
                    }
                    ControlSlider {
                        Layout.fillWidth: true
                        title: "Brightness"
                        enabled: root.systemService.brightnessAvailable
                        minimum: 0.01
                        value: root.systemService.brightnessValue
                        status: root.systemService.brightnessStatus
                        onAdjusted: value => root.systemService.setBrightness(value)
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        text: root.systemService.batteryAvailable
                            ? "Battery  " + Math.round(root.systemService.batteryPercentage * 100)
                                + "%  ·  " + root.systemService.batteryStatus
                            : "Battery unavailable"
                        color: style.secondary
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
