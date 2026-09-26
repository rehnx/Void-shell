import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

GlassSurface {
    id: root
    required property var entry
    property bool compact: false
    signal dismissed()
    ControlStyle { id: theme }
    radius: theme.radiusSmall
    implicitHeight: content.implicitHeight + theme.spacingMedium * 2
    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: theme.spacingMedium
        spacing: theme.spacingSmall
        RowLayout {
            Layout.fillWidth: true
            IconImage {
                implicitSize: 24
                source: root.entry.icon ? (root.entry.icon.startsWith("/") ? "file://" + root.entry.icon : root.entry.icon.includes(":") ? root.entry.icon : Quickshell.iconPath(root.entry.icon, "application-x-executable")) : Quickshell.iconPath("application-x-executable")
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.app
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: theme.secondary
                font.pixelSize: theme.fontSmall
            }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.time), "dd MMM HH:mm")
                color: theme.secondary
                font.pixelSize: theme.fontSmall
            }
            ShellButton {
                text: "×"
                Accessible.name: "Dismiss " + root.entry.title
                onClicked: root.dismissed()
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.entry.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 4
            elide: Text.ElideRight
            color: theme.text
            font.pixelSize: theme.fontBody
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.entry.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 3 : 30
            elide: Text.ElideRight
            color: theme.secondary
            font.pixelSize: theme.fontBody
        }
    }
}
