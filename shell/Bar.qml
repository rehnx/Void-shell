pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components"
import "widgets"

PanelWindow {
    id: root

    required property var modelData
    signal controlCenterRequested()
    signal notificationsRequested()
    signal mediaRequested()
    signal calendarRequested()
    signal powerRequested()
    required property var mediaService
    required property var systemService
    property int notificationCount: 0

    screen: modelData
    implicitHeight: 46
    exclusiveZone: implicitHeight
    color: "transparent"
    ControlStyle { id: style }
    BackgroundEffect.blurRegion: Region { item: barSurface; radius: 18 }
    GlassSurface {
        id: barSurface
        anchors.fill: parent
        anchors.margins: 5
        radius: 18
        elevated: true
    }

    anchors {
        top: true
        left: true
        right: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Workspaces {
        }

        ActiveWindow {
            Layout.maximumWidth: 360
        }

        Item {
            Layout.fillWidth: true
        }

        MediaWidget {
            Layout.preferredWidth: 242
            Layout.minimumWidth: 130
            service: root.mediaService
            onActivated: root.mediaRequested()
        }

        SystemStats {
            service: root.systemService
        }

        Tray {
        }

        WifiStatus {
        }

        VolumeStatus {
        }

        Clock { }

        ShellButton { text: "Calendar"; onClicked: root.calendarRequested() }

        ShellButton {
            text: "Notifications" + (root.notificationCount > 0 ? " · " + root.notificationCount : "")
            onClicked: root.notificationsRequested()
        }

        ShellButton { text: "Power"; onClicked: root.powerRequested() }

        ShellButton {
            implicitWidth: 34
            implicitHeight: 28
            Accessible.name: "Open Control Center"
            onClicked: root.controlCenterRequested()
            contentItem: ControlIcon {
                name: "controls"
                width: 18; height: 18
                ink: style.text
            }
        }
    }
}
