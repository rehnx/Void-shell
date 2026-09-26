pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "services"
import "panels"

ShellRoot {
    MediaService { id: media }
    MediaPanel {
        id: mediaPanel
        service: media
        onOpenedChanged: if (opened) {
            controlCenter.close();
            notificationCenter.opened = false;
            launcher.closeLauncher();
        }
    }
    NotificationService { id: notifications }
    NotificationCenter {
        id: notificationCenter
        service: notifications
        onOpenedChanged: if (opened) {
            controlCenter.close();
            launcher.closeLauncher();
            mediaPanel.close();
        }
    }
    NotificationToasts {
        service: notifications
        suppressed: notificationCenter.opened || controlCenter.visible || launcher.visible
    }
    ControlCenter {
        id: controlCenter
        onOpenedChanged: if (opened) {
            notificationCenter.opened = false;
            mediaPanel.close();
        }
    }

    Launcher {
        id: launcher
        onVisibleChanged: if (visible) {
            notificationCenter.opened = false;
            mediaPanel.close();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                mediaService: media
                onMediaRequested: mediaPanel.toggle(modelData)
                notificationCount: notifications.count
                onNotificationsRequested: notificationCenter.toggle(modelData)
                onControlCenterRequested: controlCenter.toggle(modelData)
            }
        }
    }
}
