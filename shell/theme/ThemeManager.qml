import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../services"
import "palettes"

Item {
    id: root

    readonly property var availableThemes: Settings.availableThemes
    property string selectedTheme: "void-dark"
    property string wallpaperPath: ""
    property string dynamicStatus: "idle"
    readonly property bool ready: !persistenceEnabled || Settings.ready
    property bool persistenceEnabled: true
    property string pendingWallpaper: ""
    readonly property string explicitWallpaper: Quickshell.env("VOID_WALLPAPER")

    signal themeChanged(string theme)

    VoidDark { id: voidDark }
    VoidLight { id: voidLight }
    Amoled { id: amoled }
    WarmGlass { id: warmGlass }
    DynamicPalette { id: dynamicPalette }

    function normalizeTheme(name) {
        return Settings.normalizeTheme(name);
    }

    function paletteFor(name) {
        if (name === "void-light") return voidLight;
        if (name === "amoled") return amoled;
        if (name === "warm-glass") return warmGlass;
        if (name === "dynamic") return dynamicPalette;
        return voidDark;
    }

    function apply(name) {
        Theme.applyPalette(paletteFor(name));
        themeChanged(name);
    }

    function setTheme(name, persist) {
        const normalized = normalizeTheme(name);
        if (!normalized) return false;
        if (persistenceEnabled && (persist === undefined || persist))
            return Settings.setValue("theme", normalized);
        selectedTheme = normalized;
        apply(normalized);
        if (normalized === "dynamic" && dynamicStatus !== "ready") refreshWallpaper();
        return true;
    }

    Connections {
        target: Settings
        function onThemeChanged() {
            if (root.persistenceEnabled && Settings.ready) root.setTheme(Settings.theme, false);
        }
        function onReadyChanged() {
            if (root.persistenceEnabled && Settings.ready) root.setTheme(Settings.theme, false);
        }
    }

    function rgba(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function mix(first, second, amount) {
        const keep = 1 - amount;
        return Qt.rgba(first.r * keep + second.r * amount,
            first.g * keep + second.g * amount,
            first.b * keep + second.b * amount, 1);
    }

    function channel(value) {
        return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    }

    function luminance(color) {
        return channel(color.r) * 0.2126 + channel(color.g) * 0.7152 + channel(color.b) * 0.0722;
    }

    function contrast(first, second) {
        const high = Math.max(luminance(first), luminance(second));
        const low = Math.min(luminance(first), luminance(second));
        return (high + 0.05) / (low + 0.05);
    }

    function saturation(color) {
        return Math.max(color.r, color.g, color.b) - Math.min(color.r, color.g, color.b);
    }

    function readableAccent(candidate, background) {
        let result = candidate;
        const white = Qt.rgba(1, 1, 1, 1);
        for (let step = 0; step < 5 && contrast(result, background) < 3.2; step++)
            result = mix(result, white, 0.18);
        return result;
    }

    function buildDynamic(colors) {
        if (!colors || colors.length === 0) {
            dynamicStatus = "fallback";
            apply("dynamic");
            return false;
        }
        let dominant = colors[0];
        let accentCandidate = colors[0];
        let secondCandidate = colors.length > 1 ? colors[1] : colors[0];
        for (let index = 0; index < colors.length; index++) {
            if (saturation(colors[index]) > saturation(accentCandidate)) {
                secondCandidate = accentCandidate;
                accentCandidate = colors[index];
            }
        }
        const nearBlack = Qt.rgba(0.025, 0.035, 0.055, 1);
        const background = mix(dominant, nearBlack, 0.78);
        const accent = readableAccent(accentCandidate, background);
        const secondary = readableAccent(secondCandidate, background);
        const white = Qt.rgba(0.98, 0.99, 1, 1);
        const black = Qt.rgba(0.03, 0.045, 0.065, 1);

        dynamicPalette.background = background;
        dynamicPalette.surface = rgba(mix(background, accent, 0.08), 0.94);
        dynamicPalette.surfaceElevated = rgba(mix(background, accent, 0.14), 0.97);
        dynamicPalette.surfaceBottom = rgba(mix(background, black, 0.15), 0.97);
        dynamicPalette.surfaceCard = rgba(mix(background, accent, 0.19), 0.68);
        dynamicPalette.surfaceCardBottom = rgba(mix(background, black, 0.1), 0.58);
        dynamicPalette.surfaceInset = rgba(mix(background, black, 0.12), 0.74);
        dynamicPalette.textPrimary = white;
        dynamicPalette.textSecondary = mix(white, accent, 0.18);
        dynamicPalette.textMuted = mix(white, background, 0.42);
        dynamicPalette.accent = accent;
        dynamicPalette.secondary = secondary;
        dynamicPalette.textOnAccent = contrast(accent, black) >= contrast(accent, white) ? black : white;
        dynamicPalette.hover = rgba(accent, 0.14);
        dynamicPalette.pressed = rgba(accent, 0.30);
        dynamicPalette.selected = rgba(accent, 0.23);
        dynamicPalette.border = rgba(dynamicPalette.textSecondary, 0.22);
        dynamicPalette.borderStrong = rgba(dynamicPalette.textSecondary, 0.42);
        dynamicPalette.innerBorder = rgba(white, 0.055);
        dynamicPalette.separator = rgba(dynamicPalette.textSecondary, 0.14);
        dynamicPalette.shadowNear = rgba(black, 0.28);
        dynamicPalette.shadowFar = rgba(black, 0.14);
        dynamicPalette.scrim = background;
        dynamicStatus = "ready";
        if (selectedTheme === "dynamic") apply("dynamic");
        return true;
    }

    function validateWallpaper(path) {
        pendingWallpaper = String(path || "").trim();
        if (!pendingWallpaper) {
            dynamicStatus = "fallback";
            if (selectedTheme === "dynamic") apply("dynamic");
            return false;
        }
        wallpaperCheck.checkedPath = pendingWallpaper;
        wallpaperCheck.exec(["sh", "-c",
            "if test -r \"$1\" && file -b --mime-type -- \"$1\" 2>/dev/null | grep -q '^image/'; then printf 'valid\\n'; else printf 'invalid\\n'; fi",
            "sh", pendingWallpaper]);
        return true;
    }

    function refreshWallpaper() {
        if (dynamicStatus === "loading" && (wallpaperCheck.running || wallpaperImage.status === Image.Loading))
            return true;
        dynamicStatus = "loading";
        if (wallpaperPath) return validateWallpaper(wallpaperPath);
        if (explicitWallpaper) return validateWallpaper(explicitWallpaper);
        if (!wallpaperDiscovery.running) wallpaperDiscovery.running = true;
        return true;
    }

    function setWallpaper(path) {
        wallpaperPath = String(path || "").trim();
        dynamicStatus = "loading";
        return validateWallpaper(wallpaperPath);
    }

    function fileUrl(path) {
        return "file://" + String(path).split("/").map(part => encodeURIComponent(part)).join("/");
    }

    function finishWallpaperCheck(valid) {
        if (valid) {
            wallpaperPath = wallpaperCheck.checkedPath;
            const target = fileUrl(wallpaperPath);
            wallpaperImage.source = "";
            Qt.callLater(() => wallpaperImage.source = target);
        } else {
            dynamicStatus = "fallback";
            if (selectedTheme === "dynamic") apply("dynamic");
        }
    }

    Process {
        id: wallpaperDiscovery
        property bool produced: false
        command: ["sh", "-c", "candidate=; if command -v hyprctl >/dev/null 2>&1; then candidate=$(hyprctl hyprpaper listloaded 2>/dev/null | head -n 1); fi; if [ -z \"$candidate\" ] && command -v swww >/dev/null 2>&1; then candidate=$(swww query 2>/dev/null | sed -n 's/.*image: //p' | head -n 1); fi; if [ -z \"$candidate\" ]; then for proc in /proc/[0-9]*/cmdline; do args=$(tr '\\0' '\\n' <\"$proc\" 2>/dev/null); case \"$args\" in *swaybg*) candidate=$(printf '%s\\n' \"$args\" | awk 'previous == \"-i\" { print; exit } { previous=$0 }'); [ -n \"$candidate\" ] && break;; esac; done; fi; [ -r \"$candidate\" ] && printf '%s\\n' \"$candidate\""]
        stdout: SplitParser {
            onRead: data => {
                const candidate = data.trim();
                if (!candidate) return;
                wallpaperDiscovery.produced = true;
                root.wallpaperPath = candidate;
                root.validateWallpaper(candidate);
            }
        }
        onRunningChanged: if (!running) {
            if (!produced) {
                root.dynamicStatus = "fallback";
                if (root.selectedTheme === "dynamic") root.apply("dynamic");
            }
            produced = false;
        }
    }

    Process {
        id: wallpaperCheck
        property string checkedPath: ""
        stdout: SplitParser {
            onRead: data => root.finishWallpaperCheck(data.trim() === "valid")
        }
    }

    Image {
        id: wallpaperImage
        visible: false
        asynchronous: true
        cache: false
        sourceSize.width: 64
        sourceSize.height: 64
        onStatusChanged: {
            if (status === Image.Ready) quantizer.source = source;
            else if (status === Image.Error) {
                root.dynamicStatus = "fallback";
                if (root.selectedTheme === "dynamic") root.apply("dynamic");
            }
        }
    }

    ColorQuantizer {
        id: quantizer
        depth: 3
        rescaleSize: 64
        onColorsChanged: if (colors.length > 0) root.buildDynamic(colors)
    }

    IpcHandler {
        target: "theme"
        function ready(): string { return root.ready ? "ready" : "loading"; }
        function current(): string { return root.selectedTheme; }
        function list(): string { return root.availableThemes.join(","); }
        function status(): string { return root.dynamicStatus; }
        function snapshot(): string {
            return JSON.stringify({
                id: root.selectedTheme,
                name: Theme.name,
                dark: Theme.dark,
                background: String(Theme.background),
                surface: String(Theme.surface),
                elevated: String(Theme.surfaceElevated),
                accent: String(Theme.accent),
                secondary: String(Theme.secondary),
                textPrimary: String(Theme.textPrimary),
                textSecondary: String(Theme.textSecondary),
                textOnAccent: String(Theme.textOnAccent),
                border: String(Theme.border),
                highlight: String(Theme.selected),
                dynamicStatus: root.dynamicStatus
            });
        }
        function setTheme(name: string): string { return root.setTheme(name, true) ? root.selectedTheme : "invalid"; }
        function setWallpaper(path: string): string { return root.setWallpaper(path) ? "loading" : "fallback"; }
        function refresh(): string { root.refreshWallpaper(); return root.dynamicStatus; }
    }

    Component.onCompleted: {
        if (persistenceEnabled) Settings.initialize();
        setTheme(Settings.theme, false);
    }
}
