import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "services"
import "panels"
import "components"

ShellRoot {
    NotificationService { id: service }
    NotificationCenter { id: center; service: service }
    NotificationToasts { id: toasts; service: service; suppressed: center.visible }
    TestCase { id: input; when: false; parent: center.contentItem }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({history: service.history, toasts: service.toasts,
                live: Object.keys(service.live).length, visible: center.visible, opened: center.opened,
                toastVisible: toasts.visible});
        }
        function dismiss(id: int): void { service.dismiss(id); }
        function clear(): void { service.clearAll(); }
        function toastOpacity(): real {
            function find(item, inheritedOpacity) {
                const effectiveOpacity = inheritedOpacity * item.opacity;
                if (item.entry && typeof item.dismissed === "function") return effectiveOpacity;
                for (const child of item.children || []) { const result = find(child, effectiveOpacity); if (result >= 0) return result; }
                return -1;
            }
            return find(toasts.contentItem, 1);
        }
        function dismissCard(toast: bool): string {
            function find(item) {
                if (item.entry && typeof item.dismissed === "function") return item;
                for (const child of item.children || []) { const result = find(child); if (result) return result; }
                return null;
            }
            center.opened = !toast;
            input.wait(Math.max(Motion.enter, Motion.exit) + 100);
            const card = find(toast ? toasts.contentItem : center.contentItem);
            if (!card) return "Card missing";
            const previous = service.count;
            card.dismissed();
            center.opened = false;
            return service.count === previous - 1 ? "passed" : "Card dismiss failed";
        }
        function open(): void { center.toggle(null); }
        function interactions(): string {
            center.opened = true;
            input.wait(300);
            input.keyClick(Qt.Key_Escape);
            if (center.opened) return "Escape failed";
            input.wait(300);
            if (center.visible) return "Close animation failed";
            center.opened = true;
            input.wait(300);
            input.mouseClick(center.contentItem, 10, 10);
            if (center.opened) return "Outside click failed";
            input.wait(300);
            center.opened = true;
            input.wait(300);
            input.mouseClick(center.contentItem, center.width - 200, 100);
            if (!center.opened) return "Inside click failed";
            center.opened = false;
            input.wait(Motion.exit + 100);
            return "passed";
        }
        function buttons(): string {
            function find(item, text) {
                if (item.text === text && typeof item.clicked === "function") return item;
                for (const child of item.children || []) { const result = find(child, text); if (result) return result; }
                return null;
            }
            center.opened = true;
            input.wait(100);
            const dismiss = find(center.contentItem, "×");
            // The header close button is checked separately; cards are tested via service IPC.
            if (!dismiss) return "Close button missing";
            const clear = find(center.contentItem, "Clear all");
            if (!clear || !clear.enabled) return "Clear button unavailable";
            clear.clicked();
            if (service.count !== 0 || clear.enabled) return "Clear all failed";
            dismiss.clicked();
            return center.opened ? "Close button failed" : "passed";
        }
    }
}
