pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: root
    required property var service
    property var requestedScreen: null
    property bool opened: false
    readonly property real reveal: surface.progress
    ControlStyle { id: theme }

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
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: {
        service.progressVisible = opened;
        if (opened) Qt.callLater(() => closeButton.forceActiveFocus());
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "media"
        description: "Toggle Void Shell media panel"
        onPressed: root.toggle(null)
    }
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    FocusScope {
        anchors.fill: parent
        Keys.onEscapePressed: root.close()
        FloatingSurface {
            id: surface
            shown: root.opened
            width: Math.min(theme.panelWidth, parent.width - theme.spacingMedium * 2)
            height: body.implicitHeight + theme.spacingMedium * 2
            x: parent.width - width - theme.spacingMedium
            y: theme.panelTop
            transformOrigin: Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            ColumnLayout {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.spacingMedium
                spacing: theme.spacingMedium
                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "Media"; color: theme.text; font.pixelSize: theme.fontHeading }
                    ShellButton {
                        id: closeButton
                        text: "×"
                        Accessible.name: "Close media panel"
                        onClicked: root.close()
                    }
                }
                ComboBox {
                    id: playerPicker
                    Layout.fillWidth: true
                    visible: root.service.players.length > 1
                    model: root.service.players.map(player => player.identity || player.dbusName)
                    currentIndex: root.service.activeIndex
                    onActivated: index => root.service.selectPlayer(index)
                    Accessible.name: "Media player"
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: theme.spacingMedium
                    MediaArtwork {
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 88
                        artwork: root.service.artwork
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: root.service.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: theme.text
                            font.pixelSize: theme.fontBody
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.service.artist
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: theme.secondary
                            font.pixelSize: theme.fontBody
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.service.album
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: theme.secondary
                            font.pixelSize: theme.fontSmall
                            visible: text.length > 0
                        }
                    }
                }
                MediaControls {
                    Layout.alignment: Qt.AlignHCenter
                    service: root.service
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.service.canSeek
                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: Math.max(1, root.service.length)
                        enabled: root.service.canSeek
                        Accessible.name: "Playback progress"
                        Binding { target: progressSlider; property: "value"; value: root.service.position; when: !progressSlider.pressed }
                        onPressedChanged: if (!pressed) root.service.seekTo(value)
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.service.timeText(root.service.position); color: theme.secondary; font.pixelSize: theme.fontSmall }
                        Item { Layout.fillWidth: true }
                        Text { text: root.service.timeText(root.service.length); color: theme.secondary; font.pixelSize: theme.fontSmall }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: !root.service.canSeek
                    text: root.service.available ? "Progress unavailable" : "No media player active"
                    color: theme.secondary
                    font.pixelSize: theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.service.canSetVolume
                    Text { text: "Volume"; color: theme.secondary; font.pixelSize: theme.fontSmall }
                    Slider {
                        id: volumeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        Accessible.name: "Media volume"
                        Binding { target: volumeSlider; property: "value"; value: root.service.volume; when: !volumeSlider.pressed }
                        onPressedChanged: if (!pressed) root.service.setVolume(value)
                    }
                    Text { text: Math.round(root.service.volume * 100) + "%"; color: theme.secondary; font.pixelSize: theme.fontSmall }
                }
            }
        }
    }
}
