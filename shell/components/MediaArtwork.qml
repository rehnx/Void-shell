import QtQuick

Rectangle {
    id: root
    property string artwork: ""
    ControlStyle { id: theme }
    radius: theme.radiusSmall
    color: theme.tile
    clip: true
    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: "♪"
        color: theme.secondary
        font.pixelSize: Math.min(root.width, root.height) * 0.45
    }
    Image {
        id: image
        anchors.fill: parent
        source: root.artwork
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }
}
