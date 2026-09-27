import QtQuick

Rectangle {
    id: root
    property string artwork: ""
    ControlStyle { id: theme }
    radius: theme.radiusSmall
    color: theme.tile
    clip: true
    ShellText {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: "♪"
        color: theme.secondary
        font.pixelSize: root.width >= Theme.artworkSize ? Theme.fontDisplay : Theme.fontLabel
    }
    Image {
        id: image
        anchors.fill: parent
        anchors.margins: Theme.spacingTiny
        source: root.artwork
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }
}
