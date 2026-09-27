import QtQuick
import Quickshell

Item {
    ControlStyle { id: style }
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ShellText {
        id: label

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        color: style.text
        font.pixelSize: Theme.fontLabel
    }
}
