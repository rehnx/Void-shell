import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property var service
    property bool compact: false
    spacing: theme.spacingSmall
    ControlStyle { id: theme }

    ShellButton {
        text: "⏮"
        Accessible.name: "Previous track"
        enabled: root.service.canPrevious
        onClicked: root.service.previous()
    }
    ShellButton {
        text: root.service.playing ? "⏸" : "▶"
        Accessible.name: root.service.playing ? "Pause" : "Play"
        enabled: root.service.canToggle
        onClicked: root.service.togglePlayback()
    }
    ShellButton {
        text: "⏭"
        Accessible.name: "Next track"
        enabled: root.service.canNext
        onClicked: root.service.next()
    }
}
