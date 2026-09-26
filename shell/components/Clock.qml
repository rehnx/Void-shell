import QtQuick
import Quickshell

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        color: "#cdd6f4"
        font.pixelSize: 13
    }
}
