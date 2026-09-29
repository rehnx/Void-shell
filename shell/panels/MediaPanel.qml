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
        PanelSurface {
            id: surface
            shown: root.opened
            width: Math.min(theme.panelWidth, parent.width - theme.spacingMedium * 2)
            height: Math.min(body.implicitHeight + Theme.panelPadding * 2, parent.height - Theme.panelTop - Theme.spacingMedium)
            x: parent.width - width - theme.spacingMedium
            y: Theme.panelY(parent.height, height)
            direction: Theme.panelDirection
            transformOrigin: Theme.barAtBottom ? Item.BottomRight : Item.TopRight
            elevated: true
            MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }
            PanelScrollArea {
                naturalHeight: body.implicitHeight
                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: theme.spacingMedium
                    RowLayout {
                        spacing: Theme.spacingSmall
                        Layout.fillWidth: true
                        SectionHeader { Layout.fillWidth: true; text: "Media" }
                        ShellButton {
                            id: closeButton
                            text: "×"
                            Accessible.name: "Close media panel"
                            onClicked: root.close()
                        }
                    }
                    ShellComboBox {
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
                            Layout.preferredWidth: Theme.artworkSize
                            Layout.preferredHeight: Theme.artworkSize
                            artwork: root.service.artwork
                        }
                        ColumnLayout {
                            spacing: Theme.spacingSmall
                            Layout.fillWidth: true
                            ShellText {
                                Layout.fillWidth: true
                                text: root.service.title
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: theme.text
                                font.pixelSize: theme.fontBody
                                font.weight: Theme.weightTitle
                            }
                            ShellText {
                                Layout.fillWidth: true
                                text: root.service.artist
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: theme.secondary
                                font.pixelSize: theme.fontBody
                            }
                            ShellText {
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
                    Separator { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: Theme.spacingSmall
                        Layout.fillWidth: true
                        visible: root.service.canSeek
                        ShellSlider {
                            id: progressSlider
                            Layout.fillWidth: true
                            from: 0
                            to: Math.max(1, root.service.length)
                            enabled: root.service.canSeek
                            Accessible.name: "Playback progress"
                            // Apply after the range changes when a player appears or switches.
                            Binding { target: progressSlider; property: "value"; value: root.service.position; when: !progressSlider.pressed; delayed: true }
                            onPressedChanged: if (!pressed) root.service.seekTo(value)
                        }
                        RowLayout {
                            spacing: Theme.spacingSmall
                            Layout.fillWidth: true
                            ShellText { text: root.service.timeText(root.service.position); color: theme.secondary; font.pixelSize: theme.fontSmall }
                            Item { Layout.fillWidth: true }
                            ShellText { text: root.service.timeText(root.service.length); color: theme.secondary; font.pixelSize: theme.fontSmall }
                        }
                    }
                    ShellText {
                        Layout.fillWidth: true
                        visible: !root.service.canSeek
                        text: root.service.available ? "Progress unavailable" : "No media player active"
                        color: theme.secondary
                        font.pixelSize: theme.fontSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    RowLayout {
                        spacing: Theme.spacingSmall
                        Layout.fillWidth: true
                        visible: root.service.canSetVolume
                        ShellText { text: "Volume"; color: theme.secondary; font.pixelSize: theme.fontSmall }
                        ShellSlider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 1
                            Accessible.name: "Media volume"
                            Binding { target: volumeSlider; property: "value"; value: root.service.volume; when: !volumeSlider.pressed }
                            onPressedChanged: if (!pressed) root.service.setVolume(value)
                        }
                        ShellText { text: Math.round(root.service.volume * 100) + "%"; color: theme.secondary; font.pixelSize: theme.fontSmall }
                    }
                }
            }
        }
    }
}
