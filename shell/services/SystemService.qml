import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
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
        memoryUsage = total > 0 ? Math.max(0, Math.min(1, 1 - Number(availableMatch[1]) / total)) : 0;
    }

    function refreshStats() {
        cpuFile.reload();
        memoryFile.reload();
        if (temperatureFile.path) temperatureFile.reload();
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
    Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refreshStats() }
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
