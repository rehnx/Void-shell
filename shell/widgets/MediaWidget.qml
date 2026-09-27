import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root
    required property var service
    signal activated()
    implicitWidth: Theme.mediaWidgetWidth
    implicitHeight: Theme.buttonHeight
    ControlStyle { id: theme }
    RowLayout {
        anchors.fill: parent
        spacing: theme.spacingSmall
        MediaArtwork {
            Layout.preferredWidth: Theme.artworkCompactSize
            Layout.preferredHeight: Theme.artworkCompactSize
            artwork: root.service.artwork
        }
        ShellText {
            Layout.fillWidth: true
            text: root.service.title
            textFormat: Text.PlainText
            color: theme.text
            elide: Text.ElideRight
            font.pixelSize: theme.fontSmall
        }
        ShellButton {
            text: root.service.playing ? "⏸" : "▶"
            Accessible.name: root.service.playing ? "Pause" : "Play"
            enabled: root.service.canToggle
            onClicked: root.service.togglePlayback()
        }
        ShellButton {
            text: "⌃"
            Accessible.name: "Open media panel"
            onClicked: root.activated()
        }
    }
}
