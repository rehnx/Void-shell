pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components"
import "widgets"
import "services"

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
        top: !Theme.barAtBottom
        bottom: Theme.barAtBottom
        left: true
        right: true
    }

    RowLayout {
        objectName: "barModules"
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingCompact

        Workspaces {
            objectName: "module-workspaces"
            visible: Settings.moduleVisible("workspaces")
        }

        ActiveWindow {
            objectName: "module-activeWindow"
            visible: Settings.moduleVisible("activeWindow")
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.maximumWidth: Theme.activeWindowMaximumWidth
        }

        Item {
            Layout.fillWidth: true
        }

        MediaWidget {
            objectName: "module-media"
            visible: Settings.moduleVisible("media")
            Layout.fillWidth: true
            Layout.preferredWidth: Theme.mediaWidgetWidth
            Layout.minimumWidth: Theme.mediaWidgetMinimum
            Layout.maximumWidth: Theme.mediaWidgetWidth
            service: root.mediaService
            onActivated: root.mediaRequested()
        }

        SystemStats {
            objectName: "module-systemStats"
            visible: Settings.moduleVisible("systemStats")
            service: root.systemService
        }

        Tray {
            objectName: "module-tray"
            visible: Settings.moduleVisible("tray")
        }

        WifiStatus {
            objectName: "module-wifi"
            visible: Settings.moduleVisible("wifi")
        }

        VolumeStatus {
            objectName: "module-volume"
            visible: Settings.moduleVisible("volume")
        }

        Clock { objectName: "module-clock"; visible: Settings.moduleVisible("clock") }

        ShellButton {
            objectName: "module-calendar"
            visible: Settings.moduleVisible("calendar")
            text: "Calendar"; onClicked: root.calendarRequested()
        }

        ShellButton {
            objectName: "module-notifications"
            visible: Settings.moduleVisible("notifications")
            text: "Notifications" + (root.notificationCount > 0 ? " · " + root.notificationCount : "")
            onClicked: root.notificationsRequested()
        }

        ShellButton {
            objectName: "module-power"
            visible: Settings.moduleVisible("power")
            text: "Power"; onClicked: root.powerRequested()
        }

        ShellButton {
            objectName: "module-controlCenter"
            visible: Settings.moduleVisible("controlCenter")
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
