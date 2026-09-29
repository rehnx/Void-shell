import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "components"
import "services"
import "panels"
import "theme"

// Internal validation only; no settings UI or real power/compositor actions.
ShellRoot {
    id: root
    ThemeManager { id: manager }
    SystemService { id: system; actionsEnabled: false; shortcutAppId: "void-settings-test" }
    MediaService { id: media }
    NotificationService { id: notifications }
    Launcher { id: launcher }
    ControlCenter { id: control; systemService: system }
    NotificationCenter { id: center; service: notifications }
    MediaPanel { id: mediaPanel; service: media }
    CalendarPanel { id: calendar; shortcutAppId: "void-settings-test" }
    PowerMenu { id: power; service: system; shortcutAppId: "void-settings-test" }
    OSD { id: osd; service: system }
    NotificationToasts { id: toasts; service: notifications }
    Bar { id: bar; visible: false; modelData: Quickshell.screens[0]; mediaService: media; systemService: system }
    TestCase { id: input; when: false; parent: launcher.contentItem }

    Component.onCompleted: {
        Settings.compositorSocketPath = Quickshell.env("VOID_TEST_BLUR_SOCKET") || "";
        Settings.compositorEnabled = true;
    }
    function expect(condition, message) { if (!condition) throw new Error(message); }
    function settled() { input.wait(Math.max(Motion.enter, Motion.exit, Motion.expand) + 100); }
    function surface(item) {
        if (item instanceof FloatingSurface) return item;
        for (const child of item.children || []) {
            const match = surface(child);
            if (match) return match;
        }
        return null;
    }
    function textChecks(item) {
        if (!item.visible) return;
        if (item instanceof ShellText || item instanceof TextInput) {
            expect(item.font.family === Settings.fontFamily,
                "Font family did not propagate: " + item + " text=" + item.text + " family=" + item.font.family);
            expect([Theme.fontCaption, Theme.fontLabel, Theme.fontBody, Theme.fontTitle, Theme.fontDisplay]
                .includes(item.font.pixelSize), "Font scale did not propagate");
            if (item instanceof ShellText && item.elide === Text.ElideNone && item.wrapMode === Text.NoWrap)
                expect(item.contentWidth <= item.width + 2, "Text overflow: " + item.text);
        }
        for (const child of item.children || []) textChecks(child);
    }
    function panelChecks() {
        for (const panel of [launcher, control, center, mediaPanel, power, calendar]) {
            panel.opened = true;
            settled();
            const visual = surface(panel.contentItem);
            expect(visual.progress === 1 && !visual.animating, "Motion did not settle");
            expect(visual.radius === Settings.cornerRadius && visual.padding === Theme.panelPadding, "Appearance did not propagate");
            expect(Math.abs(visual.tint.a - Theme.surfaceElevated.a) < 0.01, "Transparency did not propagate");
            expect(visual.x >= 0 && visual.y >= 0 && visual.x + visual.width <= panel.width + 1
                && visual.y + visual.height <= panel.height + 1, "Panel exceeds screen");
            if ([control, center, mediaPanel, calendar].includes(panel))
                expect(visual.y === Theme.panelY(panel.height, visual.height), "Panel did not follow bar");
            textChecks(panel.contentItem);
            panel.opened = false;
            settled();
            expect(!panel.visible, "Closed panel still visible");
        }
        return "passed";
    }
    function barChecks() {
        bar.visible = true;
        settled();
        expect(bar.anchors.bottom === Theme.barAtBottom && bar.anchors.top !== Theme.barAtBottom, "Bar anchors incorrect");
        expect(bar.exclusiveZone === bar.height && bar.height === Theme.barHeight, "Bar reservation incorrect");
        const row = bar.contentItem.children.find(item => item.objectName === "barModules");
        let end = 0;
        for (const child of row.children) {
            if (child.objectName.startsWith("module-")) {
                const name = child.objectName.slice(7);
                expect(child.visible === Settings.moduleVisible(name), "Module visibility: " + name);
            }
            if (!child.visible) continue;
            expect(child.x >= end - 1 && child.x + child.width <= row.width + 1, "Bar overlap/overflow: " + child.objectName);
            end = child.x + child.width;
        }
        textChecks(bar.contentItem);
        bar.visible = false;
        return "passed";
    }
    function interruptMotion() {
        Settings.update({ animationsEnabled: true, reducedMotion: false, animationSpeed: "slow" });
        launcher.opened = true;
        input.wait(40);
        Settings.setValue("reducedMotion", true);
        input.wait(20);
        expect(surface(launcher.contentItem).progress === 1 && !surface(launcher.contentItem).animating, "Reduced motion did not settle in-flight open");
        Settings.setValue("reducedMotion", false);
        launcher.opened = false;
        input.wait(40);
        Settings.setValue("animationsEnabled", false);
        input.wait(20);
        expect(!launcher.visible && surface(launcher.contentItem).progress === 0, "Disabled motion did not settle in-flight close");
        return "passed";
    }
    IpcHandler {
        target: "settingsTest"
        function state(): string {
            return JSON.stringify({ theme: manager.selectedTheme, themeName: Theme.name,
                surfaceAlpha: Theme.surface.a, paletteAlpha: Theme.paletteSurface.a,
                blurEnabled: Theme.blurEnabled, radius: Theme.radiusLarge, spacing: Theme.spacingMedium,
                font: Theme.fontFamily, fontBody: Theme.fontBody, barHeight: Theme.barHeight,
                motion: Motion.enabled, reduced: Motion.reducedMotion, duration: Motion.enter,
                speed: Motion.level, history: notifications.count, toasts: notifications.toasts.length,
                toastVisible: toasts.visible, osdVisible: system.osdVisible, osdWindow: osd.visible });
        }
        function run(name: string): string {
            try {
                if (name === "panels") return root.panelChecks();
                if (name === "bar") return root.barChecks();
                if (name === "motion") return root.interruptMotion();
                return "invalid";
            } catch (error) { return String(error); }
        }
        function showOsd(): string { system.showOsd("volume", "Volume", 0.5, false); return "ok"; }
    }
}
