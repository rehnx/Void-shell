pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    // The only settings owner. Consumers bind to these read-only values and
    // submit changes through setValue/update, so validation cannot be bypassed.
    readonly property bool ready: state.ready
    readonly property string path: Quickshell.env("VOID_SETTINGS_PATH")
        || Quickshell.env("VOID_THEME_STATE") || Quickshell.statePath("settings.json")
    readonly property string legacyPath: Quickshell.env("VOID_THEME_STATE") || Quickshell.statePath("theme.json")
    readonly property var availableThemes: ["void-dark", "void-light", "amoled", "warm-glass", "dynamic"]
    readonly property var moduleNames: ["workspaces", "activeWindow", "media", "systemStats", "tray",
        "wifi", "volume", "clock", "calendar", "notifications", "power", "developerCenter", "controlCenter"]
    readonly property string theme: state.overrides.theme ?? state.values.theme
    readonly property real transparency: state.values.transparency
    readonly property int blurStrength: state.values.blurStrength
    readonly property int cornerRadius: state.values.cornerRadius
    readonly property real density: state.values.density
    readonly property string animationSpeed: state.overrides.animationSpeed ?? state.values.animationSpeed
    readonly property bool reducedMotion: state.overrides.reducedMotion ?? state.values.reducedMotion
    readonly property string barPosition: state.values.barPosition
    readonly property var modules: state.values.modules
    readonly property string layoutMode: state.values.layoutMode
    readonly property string fontFamily: state.values.fontFamily
    readonly property real fontScale: state.values.fontScale
    readonly property bool animationsEnabled: state.overrides.animationsEnabled ?? state.values.animationsEnabled
    readonly property bool notificationsEnabled: state.values.notificationsEnabled
    readonly property bool osdEnabled: state.values.osdEnabled
    readonly property string persistenceError: state.error

    // Only the real shell enables compositor integration. Test harnesses can
    // supply a local socket without altering the desktop's compositor settings.
    property bool compositorEnabled: false
    property string compositorSocketPath: Hyprland.requestSocketPath
    readonly property string blurStatus: blur.status

    QtObject {
        id: state
        property bool started: false
        property bool ready: false
        property var values: root.defaults()
        property var overrides: root.environmentOverrides()
        property string error: ""
    }

    function defaults() {
        const modules = {};
        for (const name of moduleNames) modules[name] = true;
        return Object.freeze({ theme: "void-dark", transparency: 1, blurStrength: 8,
            cornerRadius: 28, density: 1, animationSpeed: "normal", reducedMotion: false,
            barPosition: "top", modules: Object.freeze(modules), layoutMode: "comfortable",
            fontFamily: "Sans Serif", fontScale: 1, animationsEnabled: true,
            notificationsEnabled: true, osdEnabled: true });
    }

    function normalizeTheme(name) {
        if (typeof name !== "string") return "";
        const value = name.trim().toLowerCase().replace(/[_ ]/g, "-");
        const aliases = { voiddark: "void-dark", dark: "void-dark", voidlight: "void-light",
            light: "void-light", warmglass: "warm-glass", warm: "warm-glass",
            wallpaper: "dynamic", "wallpaper-dynamic": "dynamic" };
        return Object.prototype.hasOwnProperty.call(aliases, value) ? aliases[value]
            : availableThemes.includes(value) ? value : "";
    }

    function environmentOverrides() {
        const result = {};
        const theme = normalizeTheme(Quickshell.env("VOID_THEME"));
        const speed = Quickshell.env("VOID_MOTION_LEVEL");
        if (theme) result.theme = theme;
        if (["fast", "normal", "slow"].includes(speed)) result.animationSpeed = speed;
        if (Quickshell.env("VOID_MOTION") === "off") result.animationsEnabled = false;
        if (Quickshell.env("VOID_REDUCED_MOTION") === "1") result.reducedMotion = true;
        return result;
    }

    function isObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function validated(key, value) {
        const ranges = { transparency: [0, 1], blurStrength: [0, 16], cornerRadius: [0, 40],
            density: [0.8, 1.25], fontScale: [0.8, 1.5] };
        if (Object.prototype.hasOwnProperty.call(ranges, key)) {
            if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
            const result = Math.max(ranges[key][0], Math.min(ranges[key][1], value));
            return key === "cornerRadius" || key === "blurStrength" ? Math.round(result) : result;
        }
        if (key === "theme") return normalizeTheme(value) || undefined;
        if (key === "animationSpeed") return ["fast", "normal", "slow"].includes(value) ? value : undefined;
        if (key === "barPosition") return ["top", "bottom"].includes(value) ? value : undefined;
        if (key === "layoutMode") return ["compact", "comfortable"].includes(value) ? value : undefined;
        if (["animationsEnabled", "reducedMotion", "notificationsEnabled", "osdEnabled"].includes(key))
            return typeof value === "boolean" ? value : undefined;
        if (key === "fontFamily") return typeof value === "string" && value.trim().length > 0
            && value.trim().length <= 128 && !/[\x00-\x1f\x7f]/.test(value) ? value.trim() : undefined;
        if (key === "modules" && isObject(value)) {
            for (const name of Object.keys(value))
                if (!moduleNames.includes(name) || typeof value[name] !== "boolean") return undefined;
            return Object.freeze(Object.assign({}, state.values.modules, value));
        }
        return undefined;
    }

    function moduleVisible(name) { return modules[name] === true; }

    function initialize() {
        if (state.started) return;
        state.started = true;
        settingsFile.path = path;
    }

    function restore(raw) {
        if (ready) return; // FileView also signals after its own writes.
        let data = {};
        try {
            const parsed = JSON.parse(raw);
            if (isObject(parsed) && (parsed.version === undefined || parsed.version === 1)) data = parsed;
        } catch (error) { /* Missing/malformed documents recover to defaults. */ }
        const values = Object.assign({}, defaults());
        for (const key of Object.keys(values)) {
            if (key === "modules" && isObject(data.modules)) {
                const modules = Object.assign({}, values.modules);
                for (const name of moduleNames)
                    if (typeof data.modules[name] === "boolean") modules[name] = data.modules[name];
                values.modules = Object.freeze(modules);
            } else {
                const value = validated(key, data[key]);
                if (value !== undefined) values[key] = value;
            }
        }
        state.values = Object.freeze(values);
        state.ready = true;
        // A canonical rewrite both migrates Phase 10 and repairs invalid values.
        // Session environment overrides never leak into the saved document.
        if (raw !== document()) save();
    }

    function document() { return JSON.stringify(Object.assign({ version: 1 }, state.values), null, 2) + "\n"; }

    function snapshot() {
        return Object.assign({}, state.values, { theme: theme, animationSpeed: animationSpeed,
            reducedMotion: reducedMotion, animationsEnabled: animationsEnabled });
    }

    function update(patch) {
        if (!ready || !isObject(patch)) return false;
        const values = Object.assign({}, state.values);
        const overrides = Object.assign({}, state.overrides);
        for (const key of Object.keys(patch)) {
            const value = validated(key, patch[key]);
            if (value === undefined) return false; // Reject the whole invalid update.
            values[key] = value;
            delete overrides[key];
        }
        state.overrides = overrides;
        state.values = Object.freeze(values);
        save();
        return true;
    }

    function setValue(key, value) {
        const patch = Object.create(null);
        patch[key] = value;
        return update(patch);
    }

    function reset() { return update(defaults()); }
    function save() { if (ready) commit.restart(); }
    function flush() {
        if (!ready) return false;
        commit.stop();
        settingsFile.setText(document());
        settingsFile.waitForJob();
        return !state.error;
    }

    FileView {
        id: settingsFile
        preload: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.restore(text())
        onLoadFailed: error => {
            if (root.ready) return;
            if (error === FileViewError.FileNotFound && root.path !== root.legacyPath)
                legacyFile.path = root.legacyPath;
            else root.restore("");
        }
        onSaved: state.error = ""
        onSaveFailed: error => state.error = "Cannot save settings (" + error + ")"
    }
    FileView {
        id: legacyFile
        preload: true
        printErrors: false
        onLoaded: root.restore(text())
        onLoadFailed: root.restore("")
    }
    Timer { id: commit; interval: 80; onTriggered: settingsFile.setText(root.document()) }
    Component.onDestruction: if (ready) flush()

    // Hyprland exposes strength only as a compositor-wide option. Send one
    // coalesced IPC request per change, never a shell command or polling loop.
    QtObject {
        id: blur
        property string status: "inactive"
        property int sent: -1
        property bool busy: false
    }
    onBlurStrengthChanged: if (ready && compositorEnabled) blurCommit.restart()
    onReadyChanged: if (ready && compositorEnabled) blurCommit.restart()
    onCompositorEnabledChanged: if (ready && compositorEnabled) blurCommit.restart()
    function applyBlur() {
        if (blur.busy) return;
        if (blurStrength === 0) { blur.status = "off"; return; }
        if (!compositorSocketPath) { blur.status = "unavailable"; return; }
        blur.sent = blurStrength;
        blur.status = "applying";
        blurTimeout.restart();
        blur.busy = true;
    }
    function finishBlur(status) {
        if (!blur.busy) return;
        blurTimeout.stop();
        blur.busy = false;
        blur.status = status;
        if (blur.sent !== blurStrength && compositorEnabled) blurCommit.restart();
    }
    Timer { id: blurCommit; interval: 80; onTriggered: root.applyBlur() }
    Timer { id: blurTimeout; interval: 1500; onTriggered: root.finishBlur("unavailable") }
    Loader {
        // A fresh socket also allows retries after connection failures and
        // prevents an earlier acknowledgement from being reused as a reply.
        active: blur.busy
        sourceComponent: Socket {
            path: root.compositorSocketPath
            connected: true
            onConnectedChanged: if (connected) {
                write("keyword decoration:blur:size " + blur.sent);
                flush();
            } else root.finishBlur("unavailable")
            // qmllint disable signal-handler-parameters
            // Connection failures can fire during Loader construction.
            onError: Qt.callLater(() => root.finishBlur("unavailable"))
            // qmllint enable signal-handler-parameters
            parser: StdioCollector {
                // Socket does not end parser streams when the peer disconnects.
                // Consume the acknowledgement as it arrives, including split reads.
                waitForEnd: false
                onTextChanged: if (text.trim() === "ok") root.finishBlur("applied")
            }
        }
    }

    IpcHandler {
        target: "settings"
        function ready(): string { return root.ready ? "ready" : "loading"; }
        function path(): string { return root.path; }
        function get(): string { return JSON.stringify(root.snapshot()); }
        function set(key: string, json: string): string {
            try { return root.setValue(key, JSON.parse(json)) ? "ok" : "invalid"; }
            catch (error) { return "invalid"; }
        }
        function update(json: string): string {
            try { return root.update(JSON.parse(json)) ? "ok" : "invalid"; }
            catch (error) { return "invalid"; }
        }
        function reset(): string { return root.reset() ? "ok" : "loading"; }
        function flush(): string { return root.flush() ? "saved" : root.persistenceError || "loading"; }
        function status(): string { return JSON.stringify({ persistenceError: root.persistenceError, blur: root.blurStatus }); }
    }
}
