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
    implicitHeight: Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"
    ControlStyle { id: style }
    BackgroundEffect.blurRegion: Region { x: barSurface.x; y: barSurface.y; width: Theme.blurEnabled ? barSurface.width : 0; height: barSurface.height; radius: barSurface.radius }
    GlassSurface {
        id: barSurface
        anchors.fill: parent
        anchors.margins: Theme.spacingTiny
        radius: Theme.radiusMedium
        elevated: true
    }

    anchors {
        top: true
        left: true
        right: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingCompact

        Workspaces {
        }

        ActiveWindow {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.maximumWidth: Theme.activeWindowMaximumWidth
        }

        Item {
            Layout.fillWidth: true
        }

        MediaWidget {
            Layout.fillWidth: true
            Layout.preferredWidth: Theme.mediaWidgetWidth
            Layout.minimumWidth: Theme.mediaWidgetMinimum
            Layout.maximumWidth: Theme.mediaWidgetWidth
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
            implicitWidth: Theme.buttonHeight
            implicitHeight: Theme.buttonHeight
            Accessible.name: "Open Control Center"
            onClicked: root.controlCenterRequested()
            contentItem: ControlIcon {
                name: "controls"
                width: Theme.iconSmall; height: Theme.iconSmall
                ink: style.text
            }
        }
    }
}
