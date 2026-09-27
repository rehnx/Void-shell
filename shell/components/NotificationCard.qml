import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

CardSurface {
    id: root
    required property var entry
    property bool compact: false
    signal dismissed()
    ControlStyle { id: theme }
    implicitHeight: content.implicitHeight + theme.spacingMedium * 2
    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: theme.spacingMedium
        spacing: theme.spacingSmall
        RowLayout {
            spacing: Theme.spacingSmall
            Layout.fillWidth: true
            IconImage {
                implicitSize: Theme.iconLarge
                source: root.entry.icon ? (root.entry.icon.startsWith("/") ? "file://" + root.entry.icon : root.entry.icon.includes(":") ? root.entry.icon : Quickshell.iconPath(root.entry.icon, "application-x-executable")) : Quickshell.iconPath("application-x-executable")
            }
            ShellText {
                Layout.fillWidth: true
                text: root.entry.app
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: theme.secondary
                font.pixelSize: theme.fontSmall
            }
            ShellText {
                text: Qt.formatDateTime(new Date(root.entry.time), "dd MMM HH:mm")
                Layout.maximumWidth: root.width / 3
                elide: Text.ElideRight
                color: theme.secondary
                font.pixelSize: theme.fontSmall
            }
            ShellButton {
                text: "×"
                Accessible.name: "Dismiss " + root.entry.title
                onClicked: root.dismissed()
            }
        }
        ShellText {
            Layout.fillWidth: true
            text: root.entry.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 4
            elide: Text.ElideRight
            color: theme.text
            font.pixelSize: theme.fontBody
            font.weight: Theme.weightTitle
        }
        ShellText {
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
