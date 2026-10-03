import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root

    property bool actionsEnabled: true
    property string shortcutAppId: "quickshell"
    property real cpuUsage: 0
    property real memoryUsage: 0
    property real temperature: 0
    property bool temperatureAvailable: false
    property bool brightnessAvailable: false
    property real brightnessValue: 0
    property string brightnessStatus: "Unavailable"
    property string brightnessDevice: ""
    property int pendingBrightness: -1
    property bool brightnessReceived: false
    property bool osdVisible: false
    property string osdKind: "volume"
    property string osdLabel: "Volume"
    property real osdValue: 0
    property bool osdMuted: false
    property double previousCpuTotal: 0
    property double previousCpuIdle: 0
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool audioAvailable: !!sink && sink.ready && !!sink.audio
    readonly property bool microphoneAvailable: !!source && source.ready && !!source.audio
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: !!battery && battery.ready && battery.isPresent && battery.isLaptopBattery
    readonly property real batteryPercentage: batteryAvailable ? battery.percentage : 0
    readonly property string batteryStatus: batteryAvailable
        ? UPowerDeviceState.toString(battery.state)
        : "Unavailable"
    readonly property bool onBattery: UPower.onBattery

    // Developer Center shares the bar's sampler. Additional reads are lazy and
    // bounded; no disk/process helper starts while the panel is closed.
    property bool developerActive: false
    property bool developerInitialized: false
    property double memoryTotal: 0
    property double memoryUsed: 0
    property double uptimeSeconds: 0
    property string hostname: "Unavailable"
    property string kernel: "Unavailable"
    property string distro: "Unavailable"
    property string cpuModel: "Unavailable"
    property string loadAverage: "Unavailable"
    property var disks: []
    property var processSummary: null
    property double diagnosticsRequestedAt: 0
    property double diagnosticsUpdatedAt: 0
    readonly property bool developerRefreshing: diskReader.running || processReader.running
    readonly property int statsInterval: developerActive ? 2000 : 5000
    readonly property string homePath: Quickshell.env("HOME") || ""
    readonly property string configPath: xdgPath("XDG_CONFIG_HOME", ".config")
    readonly property string statePath: xdgPath("XDG_STATE_HOME", ".local/state")
    readonly property string shellVersion: "0.12.0 · Phase 12"
    readonly property string shellBuild: Quickshell.env("VOID_BUILD_REVISION") || "Source distribution"
    readonly property string runtimeVersion: (Qt.application.name || "Quickshell")
        + (Qt.application.version ? " " + Qt.application.version : "")
    readonly property string sessionInfo: (Quickshell.env("XDG_CURRENT_DESKTOP")
        || (Hyprland.requestSocketPath ? "Hyprland" : "Unknown compositor")) + " · "
        + (Quickshell.env("XDG_SESSION_TYPE") || (Quickshell.env("WAYLAND_DISPLAY") ? "wayland" : "Unknown session"))
    readonly property var activeWorkspace: Hyprland.focusedWorkspace
    readonly property string workspaceName: activeWorkspace ? (activeWorkspace.name || String(activeWorkspace.id)) : "Unavailable"
    readonly property var activeWindow: Hyprland.activeToplevel
    readonly property string windowTitle: activeWindow && activeWindow.title ? activeWindow.title : "Desktop"
    readonly property string windowApp: activeWindow && activeWindow.wayland
        ? activeWindow.wayland.appId || "Unknown app" : "Unavailable"
    readonly property var connectedDevice: Networking.devices.values.find(device => device.connected) || null
    readonly property string networkStatus: Networking.backend === NetworkBackendType.None
        || Networking.devices.values.length === 0 ? "Unavailable"
        : connectedDevice ? ConnectionState.toString(connectedDevice.state) : "Disconnected"
    readonly property string networkDetail: connectedDevice
        ? connectedDevice.name + " · " + (connectedDevice.networks.values.find(network => network.connected)?.name || "Wired")
        : "No active connection"
    readonly property string internetStatus: NetworkConnectivity.toString(Networking.connectivity)
    readonly property string audioStatus: audioAvailable
        ? (sink.audio.muted ? "Muted" : Math.round(sink.audio.volume * 100) + "%") : "Unavailable"
    readonly property string audioDevice: audioAvailable ? sink.description || sink.name : "No output device"
    readonly property string microphoneStatus: microphoneAvailable
        ? (source.audio.muted ? "Muted" : Math.round(source.audio.volume * 100) + "%") : "Unavailable"
    readonly property var developerPaths: [
        { label: "Shell source", value: Quickshell.shellDir, folder: Quickshell.shellDir },
        { label: "Settings", value: Settings.path, folder: Settings.path.slice(0, Settings.path.lastIndexOf("/")) },
        { label: "Hyprland config", value: configPath ? configPath + "/hypr" : "", folder: configPath ? configPath + "/hypr" : "" },
        { label: "Shell state", value: Quickshell.stateDir, folder: Quickshell.stateDir }
    ]

    function xdgPath(variable, suffix) {
        const value = Quickshell.env(variable) || "";
        return value.startsWith("/") ? value : homePath.startsWith("/") ? homePath + "/" + suffix : "";
    }
    function formatBytes(value) {
        if (!Number.isFinite(value) || value < 0) return "Unavailable";
        if (value < 1024 * 1024 * 1024) return (value / (1024 * 1024)).toFixed(0) + " MiB";
        return (value / (1024 * 1024 * 1024)).toFixed(1) + " GiB";
    }
    function formatUptime(seconds) {
        if (!(seconds > 0)) return "Unavailable";
        const minutes = Math.floor(seconds / 60);
        return (minutes >= 1440 ? Math.floor(minutes / 1440) + "d " : "")
            + Math.floor(minutes / 60) % 24 + "h " + minutes % 60 + "m";
    }
    function parseDistro(text) {
        // os-release is data, never sourced as shell code.
        const values = {};
        for (const line of text.split("\n")) {
            const match = line.match(/^(PRETTY_NAME|NAME|VERSION)=([\s\S]*)$/);
            if (!match) continue;
            let value = match[2].trim();
            if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))
                value = value.slice(1, -1).replace(/\\(["\\$`])/g, "$1");
            values[match[1]] = value;
        }
        distro = values.PRETTY_NAME || [values.NAME, values.VERSION].filter(Boolean).join(" ") || "Unavailable";
    }
    function parseDisks(text) {
        const result = [];
        for (const line of text.split("\n")) {
            const match = line.match(/^\s*(\d+)\s+(\d+)\s+(\d+)\s+\d+%\s+(.+)$/);
            if (!match || Number(match[1]) <= 0 || result.some(disk => disk.mount === match[4])) continue;
            result.push({ mount: match[4], total: Number(match[1]), used: Number(match[2]),
                available: Number(match[3]), usage: Math.max(0, Math.min(1, Number(match[2]) / Number(match[1]))) });
        }
        disks = result;
    }
    function parseProcesses(text) {
        const result = { total: 0, running: 0, sleeping: 0, blocked: 0, stopped: 0, zombies: 0, other: 0 };
        for (const line of text.trim().split("\n")) {
            const state = line.trim().charAt(0);
            if (!"RSDTtZXIWP".includes(state) || !state) continue;
            result.total++;
            const key = state === "R" ? "running" : state === "S" || state === "I" ? "sleeping"
                : state === "D" ? "blocked" : state === "T" || state === "t" ? "stopped"
                : state === "Z" ? "zombies" : "other";
            result[key]++;
        }
        processSummary = result.total ? result : null;
    }
    function refreshDeveloper(force) {
        if (!developerActive) return;
        if (!developerInitialized) developerInitialized = true;
        else if (force) {
            hostnameFile.reload(); kernelFile.reload(); distroFile.reload(); cpuInfoFile.reload();
        }
        refreshStats();
        const now = Date.now();
        // Reopening quickly uses the cached snapshot; explicit refresh is bounded.
        if (developerRefreshing || now - diagnosticsRequestedAt < (force ? 1000 : 30000)) return;
        diagnosticsRequestedAt = now;
        diskReader.startedSuccessfully = false;
        processReader.startedSuccessfully = false;
        diskReader.running = true;
        processReader.running = true;
        diagnosticsTimeout.restart();
    }
    onDeveloperActiveChanged: if (developerActive) refreshDeveloper(false)

    signal powerActionRequested(string action)

    function showOsd(kind, label, value, muted) {
        if (!Settings.osdEnabled) return;
        osdKind = kind;
        osdLabel = label;
        osdValue = Math.max(0, Math.min(value, 1));
        osdMuted = muted;
        osdVisible = true;
        osdTimeout.restart();
    }

    function changeVolume(delta) {
        if (!audioAvailable) return;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
        if (sink.audio.muted && delta > 0) sink.audio.muted = false;
        showOsd("volume", "Volume", sink.audio.volume, sink.audio.muted);
    }

    function toggleVolumeMute() {
        if (!audioAvailable) return;
        sink.audio.muted = !sink.audio.muted;
        showOsd("volume", "Volume", sink.audio.volume, sink.audio.muted);
    }

    function toggleMicrophoneMute() {
        if (!microphoneAvailable) return;
        source.audio.muted = !source.audio.muted;
        showOsd("microphone", "Microphone", source.audio.volume, source.audio.muted);
    }

    function changeBrightness(deltaPercent) {
        if (!brightnessAvailable) return;
        setBrightness(brightnessValue + deltaPercent / 100);
        showOsd("brightness", "Brightness", brightnessValue, false);
    }

    function refreshBrightness() {
        if (!brightnessReader.running && !brightnessWriter.running) {
            brightnessReceived = false;
            brightnessReader.running = true;
        }
    }

    function setBrightness(value) {
        if (!brightnessAvailable) return;
        brightnessValue = Math.max(0.01, Math.min(1, value));
        brightnessStatus = Math.round(brightnessValue * 100) + "%";
        pendingBrightness = Math.round(brightnessValue * 100);
        brightnessCommit.restart();
    }

    function writeBrightness() {
        if (brightnessWriter.running || pendingBrightness < 0) return;
        brightnessWriter.command = ["brightnessctl", "-c", "backlight", "-d", brightnessDevice,
            "set", pendingBrightness + "%"];
        pendingBrightness = -1;
        brightnessWriter.running = true;
    }

    function parseCpu(text) {
        const line = text.trim().split("\n")[0].trim().split(/\s+/);
        if (line.length < 5 || line[0] !== "cpu") return;
        // guest and guest_nice are already included in user and nice.
        let total = 0;
        for (let index = 1; index < Math.min(line.length, 9); index++)
            total += Number(line[index]) || 0;
        const idle = (Number(line[4]) || 0) + (Number(line[5]) || 0);
        if (previousCpuTotal > 0 && total > previousCpuTotal) {
            const busy = (total - previousCpuTotal) - (idle - previousCpuIdle);
            cpuUsage = Math.max(0, Math.min(1, busy / (total - previousCpuTotal)));
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
    }

    function parseMemory(text) {
        const totalMatch = text.match(/^MemTotal:\s+(\d+)/m);
        const availableMatch = text.match(/^MemAvailable:\s+(\d+)/m);
        if (!totalMatch || !availableMatch) return;
        const total = Number(totalMatch[1]);
        memoryTotal = total * 1024;
        memoryUsed = Math.max(0, total - Number(availableMatch[1])) * 1024;
        memoryUsage = total > 0 ? Math.max(0, Math.min(1, 1 - Number(availableMatch[1]) / total)) : 0;
    }

    function refreshStats() {
        cpuFile.reload();
        memoryFile.reload();
        if (temperatureFile.path) temperatureFile.reload();
        if (developerActive) { uptimeFile.reload(); loadFile.reload(); }
    }

    function performPowerAction(action) {
        const commands = {
            shutdown: ["systemctl", "poweroff"],
            reboot: ["systemctl", "reboot"],
            logout: ["hyprctl", "dispatch", "exit"],
            lock: ["loginctl", "lock-session"],
            suspend: ["systemctl", "suspend"]
        };
        if (!commands[action]) return;
        powerActionRequested(action);
        if (actionsEnabled && !powerProcess.running) powerProcess.exec(commands[action]);
    }

    Component.onCompleted: {
        refreshStats();
        refreshBrightness();
        temperatureDiscovery.running = true;
    }

    PwObjectTracker { objects: [root.sink, root.source].filter(object => !!object) }

    Connections {
        target: Settings
        function onOsdEnabledChanged() {
            if (!Settings.osdEnabled) {
                osdTimeout.stop();
                root.osdVisible = false;
            }
        }
    }
    Timer { id: osdTimeout; interval: 1500; onTriggered: root.osdVisible = false }
    Timer { interval: 1000; running: true; onTriggered: root.refreshStats() }
    Timer { interval: root.statsInterval; repeat: true; running: true; onTriggered: root.refreshStats() }
    Timer { interval: 30000; repeat: true; running: root.developerActive; onTriggered: root.refreshDeveloper(false) }
    Timer {
        id: diagnosticsTimeout
        interval: 5000
        onTriggered: {
            if (diskReader.running) { diskReader.signal(9); root.disks = []; }
            if (processReader.running) { processReader.signal(9); root.processSummary = null; }
        }
    }
    Timer { id: brightnessCommit; interval: 70; onTriggered: root.writeBrightness() }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        preload: true
        printErrors: false
        onTextChanged: root.parseCpu(text())
    }
    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        preload: true
        printErrors: false
        onTextChanged: root.parseMemory(text())
    }
    FileView {
        id: temperatureFile
        preload: true
        printErrors: false
        onTextChanged: {
            const raw = Number(text().trim());
            root.temperatureAvailable = isFinite(raw) && raw > 0;
            root.temperature = root.temperatureAvailable ? (raw > 1000 ? raw / 1000 : raw) : 0;
        }
        onLoadFailed: root.temperatureAvailable = false
    }
    FileView {
        id: hostnameFile
        path: root.developerInitialized ? "/proc/sys/kernel/hostname" : ""
        preload: true; printErrors: false
        onLoaded: root.hostname = text().trim() || "Unavailable"
        onLoadFailed: root.hostname = "Unavailable"
    }
    FileView {
        id: kernelFile
        path: root.developerInitialized ? "/proc/sys/kernel/osrelease" : ""
        preload: true; printErrors: false
        onLoaded: root.kernel = text().trim() || "Unavailable"
        onLoadFailed: root.kernel = "Unavailable"
    }
    FileView {
        id: distroFile
        path: root.developerInitialized ? "/etc/os-release" : ""
        preload: true; printErrors: false
        onLoaded: root.parseDistro(text())
        onLoadFailed: if (path === "/etc/os-release") path = "/usr/lib/os-release"; else root.distro = "Unavailable"
    }
    FileView {
        id: cpuInfoFile
        path: root.developerInitialized ? "/proc/cpuinfo" : ""
        preload: true; printErrors: false
        onLoaded: root.cpuModel = text().match(/^(?:model name|Hardware|Processor)\s*:\s*(.+)$/m)?.[1] || "Unavailable"
        onLoadFailed: root.cpuModel = "Unavailable"
    }
    FileView {
        id: uptimeFile
        path: root.developerInitialized ? "/proc/uptime" : ""
        preload: true; printErrors: false
        onLoaded: root.uptimeSeconds = Number(text().trim().split(/\s+/)[0]) || 0
        onLoadFailed: root.uptimeSeconds = 0
    }
    FileView {
        id: loadFile
        path: root.developerInitialized ? "/proc/loadavg" : ""
        preload: true; printErrors: false
        onLoaded: {
            const values = text().trim().split(/\s+/).slice(0, 3);
            root.loadAverage = values.length === 3 && values.every(value => Number.isFinite(Number(value)))
                ? values.join(" / ") : "Unavailable";
        }
        onLoadFailed: root.loadAverage = "Unavailable"
    }
    Process {
        id: diskReader
        property bool startedSuccessfully: false
        command: ["df", "-B1", "--output=size,used,avail,pcent,target", "--", "/"].concat(root.homePath ? [root.homePath] : [])
        // Quickshell accepts a JS object here; its metadata names QVariantHash.
        // qmllint disable incompatible-type
        environment: ({ LC_ALL: "C" })
        // qmllint enable incompatible-type
        stdout: StdioCollector { id: diskOutput }
        stderr: StdioCollector {}
        onStarted: startedSuccessfully = true
        // A missing executable does not emit exited; discard stale cached data.
        onRunningChanged: if (!running && !startedSuccessfully) root.disks = []
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            root.parseDisks(exitStatus === 0 ? diskOutput.text : "");
            root.diagnosticsUpdatedAt = Date.now();
        }
        // qmllint enable signal-handler-parameters
    }
    Process {
        id: processReader
        property bool startedSuccessfully: false
        command: ["ps", "-e", "-o", "stat="]
        // qmllint disable incompatible-type
        environment: ({ LC_ALL: "C" })
        // qmllint enable incompatible-type
        stdout: StdioCollector { id: processOutput }
        stderr: StdioCollector {}
        onStarted: startedSuccessfully = true
        onRunningChanged: if (!running && !startedSuccessfully) root.processSummary = null
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            root.parseProcesses(exitCode === 0 && exitStatus === 0 ? processOutput.text : "");
            root.diagnosticsUpdatedAt = Date.now();
        }
        // qmllint enable signal-handler-parameters
    }
    Process {
        id: temperatureDiscovery
        command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] && { printf '%s\\n' \"$f\"; break; }; done"]
        stdout: StdioCollector { id: temperatureOutput }
        onExited: {
            const candidate = temperatureOutput.text.trim().split("\n")[0];
            if (candidate) temperatureFile.path = candidate;
        }
    }
    Process {
        id: brightnessReader
        command: ["sh", "-c", "command -v brightnessctl >/dev/null 2>&1 && brightnessctl -m -c backlight info 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const fields = data.trim().split(",");
                if (fields.length < 5 || fields[1] !== "backlight") return;
                const current = Number(fields[2]);
                const maximum = Number(fields[4]);
                if (!isFinite(current) || !isFinite(maximum) || maximum <= 0) return;
                root.brightnessDevice = fields[0];
                root.brightnessValue = current / maximum;
                root.brightnessAvailable = true;
                root.brightnessReceived = true;
                root.brightnessStatus = Math.round(root.brightnessValue * 100) + "%";
            }
        }
        onExited: if (!root.brightnessReceived) {
            root.brightnessAvailable = false;
            root.brightnessStatus = "Unavailable";
        }
    }
    Process {
        id: brightnessWriter
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.pendingBrightness = -1;
                root.brightnessAvailable = false;
                root.brightnessStatus = "Unavailable";
            } else if (root.pendingBrightness >= 0) root.writeBrightness();
            else root.refreshBrightness();
        }
    }
    Process { id: powerProcess }

    GlobalShortcut { appid: root.shortcutAppId; name: "volumeUp"; onPressed: root.changeVolume(0.05) }
    GlobalShortcut { appid: root.shortcutAppId; name: "volumeDown"; onPressed: root.changeVolume(-0.05) }
    GlobalShortcut { appid: root.shortcutAppId; name: "volumeMute"; onPressed: root.toggleVolumeMute() }
    GlobalShortcut { appid: root.shortcutAppId; name: "microphoneMute"; onPressed: root.toggleMicrophoneMute() }
    GlobalShortcut { appid: root.shortcutAppId; name: "brightnessUp"; onPressed: root.changeBrightness(5) }
    GlobalShortcut { appid: root.shortcutAppId; name: "brightnessDown"; onPressed: root.changeBrightness(-5) }
}
