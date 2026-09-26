pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "services"
import "panels"

ShellRoot {
    NotificationService { id: notifications }
    NotificationCenter {
        id: notificationCenter
        service: notifications
        onOpenedChanged: if (opened) {
            controlCenter.close();
            launcher.closeLauncher();
        }
    }
    NotificationToasts {
        service: notifications
        suppressed: notificationCenter.opened || controlCenter.visible || launcher.visible
    }
    ControlCenter {
        id: controlCenter
        onOpenedChanged: if (opened) notificationCenter.opened = false
    }

    Launcher {
        id: launcher
        onVisibleChanged: if (visible) notificationCenter.opened = false
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                notificationCount: notifications.count
                onNotificationsRequested: notificationCenter.toggle(modelData)
                onControlCenterRequested: controlCenter.toggle(modelData)
            }
        }
    }
}
