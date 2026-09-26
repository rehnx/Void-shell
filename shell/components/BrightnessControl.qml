import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property real value: 0
    property string status: "Unavailable"
    property string device: ""
    property int pending: -1
    property bool received: false

    function refresh() {
        if (!reader.running && !writer.running) {
            received = false;
            reader.running = true;
        }
    }
    function setValue(level) {
        if (!available) return;
        pending = Math.max(1, Math.min(100, Math.round(level * 100)));
        commit.restart();
    }
    function writePending() {
        if (writer.running || pending < 0) return;
        writer.command = ["brightnessctl", "-c", "backlight", "-d", device, "set", pending + "%"];
        pending = -1;
        writer.running = true;
    }
    Component.onCompleted: refresh()
    // Coalesce drag events; no periodic polling or persistent subprocess.
    Timer { id: commit; interval: 70; onTriggered: root.writePending() }
    Process {
        id: reader
        command: ["sh", "-c", "command -v brightnessctl >/dev/null 2>&1 && brightnessctl -m -c backlight info 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                const fields = data.trim().split(",");
                if (fields.length < 5 || fields[1] !== "backlight") return;
                const current = Number(fields[2]);
                const maximum = Number(fields[4]);
                if (!isFinite(current) || !isFinite(maximum) || maximum <= 0) return;
                root.device = fields[0];
                root.value = current / maximum;
                root.available = true;
                root.received = true;
                root.status = Math.round(root.value * 100) + "%";
            }
        }
        onExited: {
            if (!root.received) {
                root.available = false;
                root.status = "Unavailable";
            }
        }
    }
    Process {
        id: writer
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                root.pending = -1;
                root.status = "Permission denied or unavailable";
                root.available = false;
            } else if (root.pending >= 0) {
                root.writePending();
            } else {
                root.refresh();
            }
        }
    }
}
