pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "components"
import "services"
import "panels"
import "theme"

ShellRoot {
    id: root
    ThemeManager { id: themeManager }
    SystemService { id: system }
    OSD { service: system }
    CalendarPanel {
        id: calendarPanel
        onOpenedChanged: if (opened) root.closeOtherPanels("calendar")
    }
    PowerMenu {
        id: powerMenu
        service: system
        onOpenedChanged: if (opened) root.closeOtherPanels("power")
    }
    function closeOtherPanels(except) {
        if (except !== "control") controlCenter.close();
        if (except !== "notifications") notificationCenter.opened = false;
        if (except !== "media") mediaPanel.close();
        if (except !== "calendar") calendarPanel.close();
        if (except !== "power") powerMenu.close();
        if (except !== "launcher") launcher.closeLauncher();
    }
    MediaService { id: media }
    MediaPanel {
        id: mediaPanel
        service: media
        onOpenedChanged: if (opened) {
            root.closeOtherPanels("media");
        }
    }
    NotificationService { id: notifications }
    NotificationCenter {
        id: notificationCenter
        service: notifications
        onOpenedChanged: if (opened) {
            root.closeOtherPanels("notifications");
        }
    }
    NotificationToasts {
        service: notifications
        suppressed: notificationCenter.opened || controlCenter.visible || launcher.visible
            || mediaPanel.opened || calendarPanel.opened || powerMenu.opened
    }
    ControlCenter {
        id: controlCenter
        systemService: system
        onOpenedChanged: if (opened) {
            root.closeOtherPanels("control");
        }
    }

    Launcher {
        id: launcher
        onOpenedChanged: if (opened) {
            root.closeOtherPanels("launcher");
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                mediaService: media
                systemService: system
                onCalendarRequested: calendarPanel.toggle(modelData)
                onPowerRequested: powerMenu.toggle(modelData)
                onMediaRequested: mediaPanel.toggle(modelData)
                notificationCount: notifications.count
                onNotificationsRequested: notificationCenter.toggle(modelData)
                onControlCenterRequested: controlCenter.toggle(modelData)
            }
        }
    }
}
