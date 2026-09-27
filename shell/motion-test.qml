import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "panels"
import "services"

ShellRoot {
    id: root
    SystemService { id: system; actionsEnabled: false; shortcutAppId: "void-motion-test" }
    MediaService { id: media }
    NotificationService { id: notifications }
    Launcher { id: launcher }
    ControlCenter { id: control; systemService: system }
    NotificationCenter { id: center; service: notifications }
    MediaPanel { id: mediaPanel; service: media }
    CalendarPanel { id: calendar; shortcutAppId: "void-motion-test" }
    PowerMenu { id: power; service: system; shortcutAppId: "void-motion-test" }
    OSD { id: osd; service: system }
    NotificationToasts { id: toasts; service: notifications }
    PanelWindow {
        id: stage
        visible: false
        implicitWidth: 600
        implicitHeight: 440
        color: "#152c48"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        ShellButton {
            id: button
            x: 30; y: 30; width: 140; height: 40
            text: "Motion feedback"
        }
        ContextualSurface {
            id: context
            compactRect: Qt.rect(30, 110, 140, 80)
            expandedRect: Qt.rect(200, 160, 340, 240)
        }
    }
    TestCase { id: input; when: false; parent: stage.contentItem }

    function expect(condition, message) {
        if (!condition) throw new Error(message);
    }
    function settled() { input.wait(Math.max(Motion.enter, Motion.exit, Motion.expand) + 100); }
    function surface(item) {
        if (item instanceof FloatingSurface) return item;
        for (const child of item.children || []) {
            const found = surface(child);
            if (found) return found;
        }
        return null;
    }
    function panelChecks() {
        for (const panel of [launcher, control, center, mediaPanel, power, calendar]) {
            const visual = surface(panel.contentItem);
            expect(!!visual, "Missing floating surface");
            input.parent = panel.contentItem;
            for (let cycle = 0; cycle < 3; cycle++) {
                panel.opened = true;
                settled();
                expect(panel.visible && visual.progress === 1 && !visual.animating, "Panel failed to settle open");
                panel.opened = false;
                expect(!visual.enabled, "Closing surface still interactive");
                if (Motion.spatial) expect(panel.visible, "Window disappeared before exit");
                settled();
                expect(!panel.visible && visual.progress === 0 && !visual.animating, "Panel failed to settle closed");
            }
            for (let cycle = 0; cycle < 8; cycle++) {
                panel.opened = true;
                input.wait(30);
                const beforeClose = visual.progress;
                panel.opened = false;
                if (Motion.spatial) expect(Math.abs(visual.progress - beforeClose) < 0.01, "Close snapped");
                input.wait(25);
                const beforeOpen = visual.progress;
                panel.opened = true;
                if (Motion.spatial) expect(Math.abs(visual.progress - beforeOpen) < 0.01, "Reopen snapped");
                input.wait(20);
            }
            settled();
            expect(visual.progress === 1 && !visual.animating, "Interrupted panel did not settle");
            input.keyClick(Qt.Key_Escape);
            expect(!panel.opened, "Escape failed");
            settled();
            panel.opened = true;
            settled();
            input.mouseClick(panel.contentItem, 5, 5);
            expect(!panel.opened, "Outside click failed");
            settled();
        }
        system.showOsd("volume", "Volume", 0.4, false);
        settled();
        expect(osd.visible, "OSD missing");
        for (let cycle = 0; cycle < 8; cycle++) {
            system.osdVisible = false;
            input.wait(25);
            system.showOsd("brightness", "Brightness", 0.7, false);
            input.wait(25);
        }
        settled();
        expect(surface(osd.contentItem).progress === 1, "OSD reopen failed");
        system.osdVisible = false;
        settled();
        expect(!osd.visible, "OSD exit failed");
        return "passed";
    }
    function interactionChecks() {
        input.parent = stage.contentItem;
        stage.visible = true;
        settled();
        input.mouseMove(button, button.width / 2, button.height / 2);
        settled();
        expect(button.hovered, "Hover missing");
        expect(button.transform[0].y === (Motion.spatial ? Motion.hoverLift : 0), "Hover lift incorrect");
        input.mousePress(button, button.width / 2, button.height / 2);
        settled();
        expect(button.down && button.scale === (Motion.spatial ? Motion.pressScale : 1), "Press feedback missing");
        input.mouseRelease(button, button.width / 2, button.height / 2);
        settled();
        expect(!button.down && button.scale === 1, "Release did not settle");
        button.focusReason = Qt.TabFocusReason;
        button.forceActiveFocus(Qt.TabFocusReason);
        settled();
        expect(button.visualFocus, "Keyboard focus missing");
        expect((button.background as Rectangle).border.color.toString() !== "#00000000", "Focus outline missing");
        button.selected = true;
        input.mouseMove(stage.contentItem, 580, 420);
        settled();
        expect((button.background as Rectangle).color.a > 0, "Selection feedback missing");
        button.enabled = false;
        settled();
        expect(button.opacity === Motion.disabledOpacity && button.scale === 1, "Disabled feedback incorrect");
        button.enabled = true;
        button.selected = false;
        stage.visible = false;
        return "passed";
    }
    function contextualChecks() {
        input.parent = stage.contentItem;
        stage.visible = true;
        settled();
        context.expanded = true;
        input.wait(Motion.spatial ? 40 : 1);
        if (Motion.spatial) expect(context.width > 140 && context.width < 340, "Expansion did not interpolate");
        const currentWidth = context.width;
        context.expanded = false;
        if (Motion.spatial) expect(Math.abs(context.width - currentWidth) < 0.01, "Expansion reversal snapped");
        settled();
        expect(context.width === 140 && context.x === 30, "Compact geometry failed");
        context.expanded = true;
        settled();
        expect(context.width === 340 && context.height === 240 && context.x === 200 && context.y === 160, "Expanded geometry failed");
        context.expanded = false;
        stage.visible = false;
        return "passed";
    }
    function toastChecks() {
        function entry(id, title) {
            return { id: id, title: title, body: "Motion regression", app: "Void", icon: "", time: Date.now(), toast: true, transient: false, deadline: 0 };
        }
        notifications.entries = [entry(101, "First"), entry(102, "Second")];
        settled();
        expect(toasts.visible && toasts.retainedCount === 2, "Toasts missing");
        notifications.entries = [entry(101, "Replacement"), entry(102, "Second")];
        settled();
        expect(toasts.retainedCount === 2, "Replacement duplicated toast");
        notifications.dismiss(101);
        expect(notifications.count === 1, "Dismissal delayed service state");
        if (Motion.spatial) expect(toasts.retainedCount === 2, "Exit snapshot removed early");
        if (Motion.spatial) {
            input.wait(Motion.exit + 30);
            const stack = toasts.contentItem.children.find(item => item instanceof Column);
            for (const item of stack.children) {
                if (item instanceof AnimatedVisibility && item.present)
                    expect(item.y + item.height + stack.y <= toasts.height, "Toast clipped during reflow");
            }
        }
        settled();
        expect(toasts.retainedCount === 1, "Exit snapshot leaked");
        toasts.suppressed = true;
        input.wait(25);
        toasts.suppressed = false;
        settled();
        expect(toasts.visible && toasts.retainedCount === 1, "Suppression reversal failed");
        notifications.clearAll();
        settled();
        expect(!toasts.visible && toasts.retainedCount === 0, "Last toast exit failed");
        notifications.entries = [entry(103, "Immediate dismissal")];
        notifications.clearAll();
        settled();
        expect(toasts.retainedCount === 0, "Unmapped toast leaked");
        return "passed";
    }
    function configurationChecks() {
        Motion.level = "fast";
        const fast = Motion.enter;
        Motion.level = "normal";
        const normal = Motion.enter;
        Motion.level = "slow";
        expect(fast < normal && normal < Motion.enter, "Motion levels incorrect");
        Motion.level = "normal";
        launcher.opened = true;
        input.wait(35);
        Motion.reducedMotion = true;
        expect(Motion.enter === 0 && !Motion.spatial, "Reduced motion configuration failed");
        input.wait(1);
        expect(launcher.reveal === 1 && !surface(launcher.contentItem).animating, "In-flight reduced motion did not finish: " + launcher.reveal);
        launcher.opened = false;
        panelChecks();
        interactionChecks();
        contextualChecks();
        toastChecks();
        Motion.reducedMotion = false;
        Motion.enabled = false;
        launcher.opened = true;
        input.wait(1);
        expect(launcher.reveal === 1, "Disabled motion did not open immediately");
        launcher.opened = false;
        input.wait(1);
        expect(!launcher.visible, "Disabled motion did not close immediately");
        Motion.enabled = true;
        return "passed";
    }
    function visualChecks() {
        const directory = Quickshell.env("VOID_MOTION_CAPTURE_DIR");
        if (!directory) return "Capture directory missing";
        input.parent = power.contentItem;
        power.opened = true;
        settled();
        input.grabImage(power.contentItem).save(directory + "/power-open.png");
        power.request("shutdown");
        settled();
        input.grabImage(power.contentItem).save(directory + "/power-confirm.png");
        power.close();
        input.wait(60);
        expect(power.displayedAction === "shutdown", "Confirmation snapped during close");
        input.grabImage(power.contentItem).save(directory + "/power-closing.png");
        settled();
        launcher.opened = true;
        settled();
        input.grabImage(launcher.contentItem).save(directory + "/launcher-open.png");
        launcher.closeLauncher();
        settled();
        control.opened = true;
        settled();
        input.grabImage(control.contentItem).save(directory + "/control-open.png");
        control.close();
        settled();
        notifications.entries = [
            { id: 104, title: "First toast", body: "Dismissed while another toast remains", app: "Void", icon: "", time: Date.now(), toast: true, transient: false, deadline: 0 },
            { id: 105, title: "Second toast", body: "Moves upward without window clipping", app: "Void", icon: "", time: Date.now(), toast: true, transient: false, deadline: 0 }
        ];
        settled();
        notifications.dismiss(104);
        input.wait(Motion.exit + 30);
        input.grabImage(toasts.contentItem).save(directory + "/toast-reflow.png");
        settled();
        notifications.clearAll();
        settled();
        return "passed";
    }
    IpcHandler {
        target: "motionTest"
        function ready(): string { return "ready"; }
        function run(name: string): string {
            try {
                if (name === "panels") return root.panelChecks();
                if (name === "interactions") return root.interactionChecks();
                if (name === "contextual") return root.contextualChecks();
                if (name === "toasts") return root.toastChecks();
                if (name === "configuration") return root.configurationChecks();
                if (name === "visual") return root.visualChecks();
                return "Unknown check";
            } catch (error) { return String(error); }
        }
    }
}
