import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "components"
import "services"
import "panels"
import "theme"

ShellRoot {
    id: root
    ThemeManager { id: manager }
    SystemService { id: system; actionsEnabled: false; shortcutAppId: "void-developer-test" }
    MediaService { id: media }
    DeveloperCenter { id: panel; service: system; shortcutAppId: "void-developer-test" }
    Bar {
        id: bar
        visible: false
        modelData: Quickshell.screens[0]
        mediaService: media
        systemService: system
        onDeveloperRequested: panel.toggle(modelData)
    }
    TestCase { id: input; when: false; parent: panel.contentItem }

    function expect(value, message) { if (!value) throw new Error(message); }
    function settled() { input.wait(Math.max(Motion.enter, Motion.exit, Motion.expand) + 120); }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    function checkText(item) {
        if (!item.visible) return;
        if (item instanceof ShellText) {
            expect(item.font.family === Theme.fontFamily, "Font mismatch: " + item.text);
            expect([Theme.fontCaption, Theme.fontLabel, Theme.fontBody, Theme.fontTitle, Theme.fontDisplay].includes(item.font.pixelSize), "Font scale mismatch");
            expect(item.elide !== Text.ElideNone || item.contentWidth <= item.width + 2, "Text overflow: " + item.text);
        }
        for (const child of item.children || []) checkText(child);
    }
    function checkPanel() {
        const surface = find(panel.contentItem, "developerSurface");
        const scroll = find(panel.contentItem, "developerScroll");
        expect(surface.progress === 1 && !surface.animating, "Panel did not settle");
        expect(surface.radius === Settings.cornerRadius, "Radius did not propagate");
        expect(Math.abs(surface.tint.a - Theme.surfaceElevated.a) < 0.01, "Transparency did not propagate");
        expect(surface.x >= 0 && surface.y >= 0 && surface.x + surface.width <= panel.width + 1
            && surface.y + surface.height <= panel.height + 1, "Panel exceeds display bounds");
        expect(surface.y === Theme.panelY(panel.height, surface.height), "Panel did not follow bar");
        expect(scroll.clip && scroll.contentHeight > 0 && scroll.contentWidth <= scroll.width, "Invalid viewport");
        checkText(panel.contentItem);
        scroll.contentY = Math.max(0, scroll.contentHeight - scroll.height);
        input.wait(50);
        checkText(panel.contentItem);
        scroll.contentY = 0;
    }
    function interactions() {
        bar.visible = true;
        settled();
        input.parent = bar.contentItem;
        input.mouseClick(find(bar.contentItem, "module-developerCenter"));
        input.parent = panel.contentItem;
        settled();
        expect(panel.opened && system.developerActive, "Bar activation failed");
        bar.visible = false;
        for (let i = 0; i < 4; i++) {
            panel.opened = true;
            settled();
            checkPanel();
            input.keyClick(Qt.Key_Escape);
            expect(!panel.opened && !system.developerActive, "Escape did not release monitoring");
            settled();
            expect(!panel.visible, "Panel stayed visible");
            panel.opened = true;
            settled();
            const surface = find(panel.contentItem, "developerSurface");
            input.mouseClick(panel.contentItem, surface.x + surface.width / 2, surface.y + 5);
            expect(panel.opened, "Inside click closed panel");
            input.mouseClick(panel.contentItem, 2, 2);
            expect(!panel.opened, "Outside click failed");
            settled();
        }
        panel.opened = true;
        settled();
        const before = Quickshell.clipboardText;
        expect(panel.copyValue("Hostname", system.hostname), "Copy rejected hostname");
        input.wait(100);
        expect(Quickshell.clipboardText === system.hostname && panel.copyFeedback === "Hostname copied", "Clipboard copy failed");
        Quickshell.clipboardText = before;
        expect(panel.folderUrl("/tmp/a #b") === "file:///tmp/a%20%23b", "Folder URL not escaped");
        expect(panel.folderUrl("relative") === "", "Relative path accepted");
        input.mouseClick(find(panel.contentItem, "developerClose"));
        settled();
        expect(!panel.visible && !system.developerActive, "Close button failed");
        return "passed";
    }
    function appearance() {
        panel.pathsExpanded = true;
        for (const theme of Settings.availableThemes) {
            Settings.setValue("theme", theme);
            for (const options of [
                { density: 0.8, fontScale: 0.8, layoutMode: "compact", cornerRadius: 0, barPosition: "top", transparency: 0 },
                { density: 1.25, fontScale: 1.5, layoutMode: "comfortable", cornerRadius: 40, barPosition: "bottom", transparency: 1 },
                { density: 0.8, fontScale: 1.5, layoutMode: "compact", cornerRadius: 18, barPosition: "top", transparency: 0.5 }
            ]) {
                Settings.update(Object.assign({ animationsEnabled: false, fontFamily: "DejaVu Sans" }, options));
                panel.preferredWidth = options.density === 0.8 ? 400 : Theme.dimension(760);
                panel.opened = true;
                settled();
                checkPanel();
                panel.opened = false;
                settled();
            }
        }
        panel.preferredWidth = Qt.binding(() => Theme.dimension(760));
        Settings.reset();
        return "passed";
    }
    function motion() {
        Settings.update({ animationSpeed: "slow", reducedMotion: false, animationsEnabled: true });
        for (const mode of ["reducedMotion", "animationsEnabled"]) {
            panel.opened = true;
            input.wait(30);
            Settings.setValue(mode, mode === "reducedMotion");
            input.wait(40);
            expect(panel.reveal === 1, "Interrupted open did not settle");
            panel.opened = false;
            input.wait(40);
            expect(!panel.visible, "Motion-disabled close did not settle");
            Settings.update({ reducedMotion: false, animationsEnabled: true });
        }
        Settings.reset();
        return "passed";
    }
    function fallbacks() {
        system.parseDistro('NAME="Test OS"\nVERSION="1"');
        expect(system.distro === "Test OS 1", "Distro fallback failed");
        system.parseProcesses("R\nSs\nD\nZ\nTl\nI\n");
        expect(system.processSummary.total === 6 && system.processSummary.running === 1 && system.processSummary.sleeping === 2, "Process states incorrect");
        system.parseDisks("Size Used Avail Use% Mounted\n1000 200 800 20% /\n1000 200 800 20% /\n");
        expect(system.disks.length === 1 && system.disks[0].usage === 0.2, "Disk parsing/deduplication failed");
        system.parseProcesses("invalid"); system.parseDisks("invalid"); system.parseDistro("invalid");
        system.temperatureAvailable = false;
        expect(!system.processSummary && system.disks.length === 0 && system.distro === "Unavailable", "Missing data fallback failed");
        panel.opened = true;
        settled();
        checkPanel();
        panel.opened = false;
        settled();
        return "passed";
    }
    IpcHandler {
        target: "developerTest"
        function ready(): string { return Settings.ready ? "ready" : "loading"; }
        function open(value: bool): void { panel.opened = value; }
        function monitoring(value: bool): void { system.developerActive = value; }
        function refresh(): void { system.refreshDeveloper(true); }
        function state(): string {
            return JSON.stringify({ opened: panel.opened, visible: panel.visible, active: system.developerActive,
                initialized: system.developerInitialized, interval: system.statsInterval,
                cpu: system.cpuUsage, memory: system.memoryTotal, uptime: system.uptimeSeconds,
                hostname: system.hostname, kernel: system.kernel, distro: system.distro,
                temperature: system.temperatureAvailable, battery: system.batteryAvailable,
                network: system.networkStatus, audio: system.audioStatus, workspace: system.workspaceName,
                window: system.windowTitle, disks: system.disks, processes: system.processSummary,
                requested: system.diagnosticsRequestedAt, updated: system.diagnosticsUpdatedAt,
                busy: system.developerRefreshing, paths: system.developerPaths,
                version: system.shellVersion, runtime: system.runtimeVersion });
        }
        function run(name: string): string {
            try {
                if (name === "interactions") return root.interactions();
                if (name === "appearance") return root.appearance();
                if (name === "motion") return root.motion();
                if (name === "fallbacks") return root.fallbacks();
                return "invalid";
            } catch (error) { return String(error); }
        }
        function capture(path: string): void {
            panel.opened = true;
            root.settled();
            const surface = root.find(panel.contentItem, "developerSurface");
            surface.grabToImage(result => result.saveToFile(path));
        }
    }
}
