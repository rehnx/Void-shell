import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var application
    property bool selected: false

    signal activated()

    implicitHeight: 52
    radius: 7
    color: selected || pointer.containsMouse ? "#313244" : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        IconImage {
            implicitSize: 32
            source: Quickshell.iconPath(root.application.icon || "application-x-executable",
                "application-x-executable")
        }

        Text {
            Layout.fillWidth: true
            text: root.application.name
            color: "#cdd6f4"
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
