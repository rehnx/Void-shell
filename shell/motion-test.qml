import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    Bar { id: bar; visible: false; modelData: Quickshell.screens[0]; mediaService: media; systemService: system }
    QtObject {
        id: fixtureMedia
        property var players: [{ identity: "A very long player identity for checking selector truncation" }, { identity: "Second player" }]
        property int activeIndex: 0
        property bool available: true
        property string title: "An unusually long track title — international text 日本語 — " + "extended title ".repeat(12)
        property string artist: "Artist name ".repeat(20)
        property string album: "Album name ".repeat(20)
        property string artwork: ""
        property bool playing: false
        property bool canToggle: true
        property bool canPrevious: false
        property bool canNext: true
        property bool canSeek: true
        property bool canSetVolume: true
        property bool progressVisible: false
        property real length: 245
        property real position: 72
        property real volume: 0.5
        function timeText(value) { return media.timeText(value); }
        function selectPlayer(index) { activeIndex = index; }
        function togglePlayback() { playing = !playing; }
        function previous() {}
        function next() {}
        function seekTo(value) { position = value; }
        function setVolume(value) { volume = value; }
    }
    PanelWindow {
        id: fixtures
        visible: false
        implicitWidth: Theme.panelWidth
        implicitHeight: 740
        color: Theme.surfaceBottom
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.panelPadding
            spacing: Theme.spacingMedium
            SectionHeader { text: "Text and missing data"; Layout.fillWidth: true }
            QuickToggle {
                id: longToggle
                Layout.fillWidth: true
                title: "Network name ".repeat(12)
                status: "Unavailable — " + "a very long device name ".repeat(12)
                enabled: false
            }
            NotificationCard {
                id: longCard
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                compact: true
                entry: ({ id: 301, app: "Application name ".repeat(20), title: "Long title 日本語 ".repeat(30),
                    body: "Long body without markup <b>plain text</b> ".repeat(60), icon: "", time: Date.now() })
            }
            ControlSlider {
                id: longSlider
                Layout.fillWidth: true
                title: "Device label ".repeat(12)
                status: "Unavailable ".repeat(20)
                enabled: false
            }
            Item { Layout.fillHeight: true }
        }
    }
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
        ShellSlider {
            id: designSlider
            x: 200; y: 30; width: 180
            value: 0.5
        }
        ShellComboBox {
            id: designPicker
            x: 30; y: 80; width: 180
            model: ["First player", "Second player"]
        }
        Workspaces { id: designWorkspaces; x: 240; y: 80 }
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
        calendar.opened = true;
        settled();
        input.grabImage(calendar.contentItem).save(directory + "/calendar.png");
        calendar.close();
        settled();
        center.opened = true;
        settled();
        input.grabImage(center.contentItem).save(directory + "/notifications-empty.png");
        notifications.entries = [{ id: 201, title: "Build completed", body: "All checks have finished. Your workspace is ready.",
            app: "Workspace", icon: "", time: Date.now(), toast: false, transient: false, deadline: 0 }];
        settled();
        input.grabImage(center.contentItem).save(directory + "/notifications.png");
        center.opened = false;
        notifications.clearAll();
        settled();
        mediaPanel.opened = true;
        settled();
        input.grabImage(mediaPanel.contentItem).save(directory + "/media-empty.png");
        mediaPanel.service = fixtureMedia;
        settled();
        input.grabImage(mediaPanel.contentItem).save(directory + "/media-long.png");
        mediaPanel.close();
        mediaPanel.service = media;
        settled();
        system.showOsd("volume", "Volume", 0.58, false);
        settled();
        input.grabImage(osd.contentItem).save(directory + "/osd.png");
        system.osdVisible = false;
        bar.visible = true;
        settled();
        input.grabImage(bar.contentItem).save(directory + "/bar.png");
        bar.visible = false;
        fixtures.visible = true;
        settled();
        input.grabImage(fixtures.contentItem).save(directory + "/text-stress.png");
        fixtures.visible = false;
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
    function findItem(item, predicate) {
        if (predicate(item)) return item;
        for (const child of item.children || []) {
            const match = findItem(child, predicate);
            if (match) return match;
        }
        return null;
    }
    function checkText(item) {
        if (!item.visible) return;
        if (item instanceof ShellText) {
            expect(item.font.family === Theme.fontFamily, "Inconsistent font family");
            expect([Theme.fontDisplay, Theme.fontTitle, Theme.fontBody, Theme.fontLabel, Theme.fontCaption].includes(item.font.pixelSize),
                "Unregistered typography size");
            if (item.elide === Text.ElideNone && item.wrapMode === Text.NoWrap)
                expect(item.contentWidth <= item.width + 2, "Unbounded text: " + item.text);
        }
        for (const child of item.children || []) checkText(child);
    }
    function designChecks() {
        input.parent = stage.contentItem;
        stage.visible = true;
        settled();
        input.mouseMove(designSlider, designSlider.width / 2, designSlider.height / 2);
        settled();
        expect(designSlider.hovered && (designSlider.handle as Rectangle).color.toString() === Theme.accent.toString(), "Slider hover missing");
        input.mousePress(designSlider, designSlider.width / 2, designSlider.height / 2);
        settled();
        expect(designSlider.pressed && designSlider.handle.scale === (Motion.spatial ? Motion.pressScale : 1), "Slider press missing");
        input.mouseRelease(designSlider, designSlider.width / 2, designSlider.height / 2);
        designSlider.focusReason = Qt.TabFocusReason;
        designSlider.forceActiveFocus(Qt.TabFocusReason);
        settled();
        expect(designSlider.visualFocus && (designSlider.handle as Rectangle).border.color.toString() === Theme.accent.toString(), "Slider focus missing");
        designSlider.enabled = false;
        settled();
        expect((designSlider.handle as Rectangle).color.toString() === Theme.textMuted.toString(), "Slider disabled state missing");
        designSlider.enabled = true;
        designPicker.forceActiveFocus(Qt.TabFocusReason);
        settled();
        expect(designPicker.visualFocus && (designPicker.background as Rectangle).border.color.toString() === Theme.accent.toString(), "Selector focus missing");
        designPicker.enabled = false;
        settled();
        expect(designPicker.opacity === Theme.disabledOpacity, "Selector disabled state missing");
        designPicker.enabled = true;
        const workspace = findItem(designWorkspaces, item => item instanceof ShellButton);
        workspace.forceActiveFocus(Qt.TabFocusReason);
        settled();
        expect(workspace.visualFocus && workspace.background.border.color.toString() === Theme.accent.toString(), "Workspace focus missing");
        stage.visible = false;
        fixtures.visible = true;
        settled();
        checkText(fixtures.contentItem);
        expect(longToggle.contentItem.width <= longToggle.width, "Toggle overflow");
        expect(longCard.implicitHeight < fixtures.height / 2, "Compact notification not bounded");
        expect(findItem(longCard, item => item instanceof ShellText && item.truncated) !== null, "Long card text did not truncate");
        fixtures.visible = false;
        for (const panel of [launcher, control, center, mediaPanel, power, calendar]) {
            panel.opened = true;
            settled();
            const visual = surface(panel.contentItem);
            expect(visual.radius === Theme.radiusLarge && visual.padding === Theme.panelPadding, "Panel tokens inconsistent");
            expect(visual.x >= 0 && visual.y >= 0 && visual.x + visual.width <= panel.width + 1
                && visual.y + visual.height <= panel.height + 1, "Panel exceeds screen");
            checkText(panel.contentItem);
            const viewport = findItem(visual, item => item instanceof PanelScrollArea);
            if (viewport) {
                expect(!viewport.ScrollBar.vertical.visible, "Scrollbar visible without overflow");
                const originalWidth = visual.width;
                const originalHeight = visual.height;
                visual.width = 320;
                visual.height = 180;
                settled();
                expect(viewport.clip && viewport.contentHeight >= viewport.height, "Constrained panel cannot scroll");
                expect(viewport.ScrollBar.vertical.visible, "Overflow scrollbar missing");
                const scrollbar = viewport.ScrollBar.vertical;
                expect(scrollbar.parent === visual && scrollbar.x >= viewport.x + viewport.width
                    && scrollbar.x + scrollbar.width <= visual.width, "Scrollbar clipped or overlapping content");
                if (panel === calendar && Quickshell.env("VOID_MOTION_CAPTURE_DIR"))
                    input.grabImage(panel.contentItem).save(Quickshell.env("VOID_MOTION_CAPTURE_DIR") + "/scroll-constrained.png");
                checkText(visual);
                viewport.contentY = Math.max(0, viewport.contentHeight - viewport.height);
                settled();
                expect(viewport.contentY > 0, "Bottom content inaccessible");
                visual.width = originalWidth;
                visual.height = originalHeight;
                viewport.contentY = 0;
            }
            panel.opened = false;
            settled();
        }
        mediaPanel.service = fixtureMedia;
        mediaPanel.opened = true;
        settled();
        checkText(mediaPanel.contentItem);
        const progress = findItem(mediaPanel.contentItem, item => item instanceof ShellSlider && item.to > 1);
        expect(progress && Math.abs(progress.value - fixtureMedia.position) < 0.01, "Media progress did not follow player data");
        input.parent = mediaPanel.contentItem;
        input.mouseClick(progress, progress.width * 0.75, progress.height / 2);
        settled();
        expect(fixtureMedia.position > fixtureMedia.length / 2 && Math.abs(progress.value - fixtureMedia.position) < 0.01,
            "Media slider did not commit pointer seek");
        fixtureMedia.position = 72;
        const picker = findItem(mediaPanel.contentItem, item => item instanceof ShellComboBox);
        expect(picker && picker.contentItem.truncated, "Player identity did not truncate");
        picker.popup.open();
        settled();
        checkText(picker.popup.contentItem);
        picker.popup.close();
        mediaPanel.close();
        mediaPanel.service = media;
        settled();
        bar.visible = true;
        settled();
        const row = findItem(bar.contentItem, item => item instanceof RowLayout);
        for (const child of row.children)
            if (child.visible) expect(child.x + child.width <= row.width + 1, "Bar overflow");
        checkText(bar.contentItem);
        bar.visible = false;
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
                if (name === "design") return root.designChecks();
                return "Unknown check";
            } catch (error) { return String(error); }
        }
    }
}
