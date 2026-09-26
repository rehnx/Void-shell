import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root
    // Snapshots survive native notification expiry; native objects never reach the UI.
    property var entries: []
    property var live: ({})
    readonly property var history: entries.filter(entry => !entry.transient)
    readonly property var toasts: entries.filter(entry => entry.toast).slice(0, 3)
    readonly property int count: history.length
    readonly property int historyLimit: 100
    readonly property int defaultTimeout: 6000

    function snapshot(notification, previous) {
        // The installed 0.3 API exposes the D-Bus timeout in milliseconds.
        const timeout = notification.expireTimeout;
        const persistent = timeout === 0 || notification.urgency === NotificationUrgency.Critical;
        return {
            id: notification.id,
            app: (notification.appName || "Application").slice(0, 256),
            title: (notification.summary || "Notification").slice(0, 512),
            body: notification.body.slice(0, 16000),
            icon: notification.appIcon,
            time: previous ? previous.time : Date.now(),
            transient: notification.transient,
            toast: previous ? previous.toast : !notification.lastGeneration,
            deadline: persistent ? 0 : Date.now() + (timeout > 0 ? timeout : defaultTimeout)
        };
    }

    function receive(notification) {
        const id = notification.id;
        notification.tracked = true;
        if (!live[id]) {
            live[id] = notification;
            notification.closed.connect(reason => root.closed(id, reason));
            // Replacement requests update the same native object.
            const update = () => Qt.callLater(() => root.refresh(id));
            notification.summaryChanged.connect(update);
            notification.bodyChanged.connect(update);
            notification.appNameChanged.connect(update);
            notification.appIconChanged.connect(update);
            notification.expireTimeoutChanged.connect(update);
            notification.urgencyChanged.connect(update);
            notification.transientChanged.connect(update);
        }
        entries = [snapshot(notification, null)].concat(entries.filter(entry => entry.id !== id));
        while (entries.length > historyLimit) dismiss(entries[entries.length - 1].id);
        schedule();
    }

    function refresh(id) {
        const notification = live[id];
        if (!notification) return;
        const previous = entries.find(entry => entry.id === id);
        if (!previous) return;
        const updated = snapshot(notification, previous);
        updated.time = Date.now();
        entries = [updated].concat(entries.filter(entry => entry.id !== id));
        schedule();
    }

    function closed(id, reason) {
        delete live[id];
        entries = entries.filter(entry => entry.id !== id || (!entry.transient && reason === NotificationCloseReason.Expired))
            .map(entry => entry.id === id ? Object.assign({}, entry, { toast: false, deadline: 0 }) : entry);
        schedule();
    }

    function dismiss(id) {
        const notification = live[id];
        if (notification) notification.dismiss();
        entries = entries.filter(entry => entry.id !== id);
        schedule();
    }

    function clearAll() {
        const ids = entries.map(entry => entry.id);
        for (const id of ids) dismiss(id);
    }

    function hideToasts() {
        entries = entries.map(entry => Object.assign({}, entry, { toast: false }));
    }

    function schedule() {
        expiry.stop();
        const deadlines = entries.filter(entry => entry.deadline > 0).map(entry => entry.deadline);
        if (deadlines.length === 0) return;
        expiry.interval = Math.min(2147483647, Math.max(1, Math.min(...deadlines) - Date.now()));
        expiry.start();
    }

    Timer {
        id: expiry
        onTriggered: {
            const now = Date.now();
            const expired = root.entries.filter(entry => entry.deadline > 0 && entry.deadline <= now);
            for (const entry of expired) {
                const notification = root.live[entry.id];
                if (notification) notification.expire();
            }
            root.schedule();
        }
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: false
        actionsSupported: false
        persistenceSupported: false
        onNotification: notification => root.receive(notification)
    }
}
