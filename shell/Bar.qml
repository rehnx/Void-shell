import QtQuick
import QtQuick.Layouts
import Quickshell
import "components"

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    implicitHeight: 32
    exclusiveZone: implicitHeight
    color: "#1e1e2e"

    anchors {
        top: true
        left: true
        right: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Workspaces {
        }

        ActiveWindow {
            Layout.maximumWidth: 360
        }

        Item {
            Layout.fillWidth: true
        }

        Tray {
        }

        WifiStatus {
        }

        VolumeStatus {
        }

        BatteryStatus {
        }

        Clock {
        }
    }
}
