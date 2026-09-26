import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property string statusText: !sink || !sink.ready || !sink.audio
        ? "Vol --"
        : sink.audio.muted
            ? "Vol muted"
            : "Vol " + Math.round(sink.audio.volume * 100) + "%"

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.statusText
        color: "#cdd6f4"
        font.pixelSize: 13
    }
}
