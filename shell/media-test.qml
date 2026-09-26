import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "services"
import "panels"

ShellRoot {
    MediaService { id: service }
    MediaPanel { id: panel; service: service }
    TestCase { id: input; when: false; parent: panel.contentItem }
    IpcHandler {
        target: "mediaTest"
        function state(): string {
            return JSON.stringify({
                count: service.players.length,
                names: service.players.map(player => player.identity),
                selected: service.name,
                title: service.title,
                artist: service.artist,
                album: service.album,
                artwork: service.artwork,
                playing: service.playing,
                position: service.position,
                length: service.length,
                volume: service.volume,
                seek: service.canSeek,
                volumeSupported: service.canSetVolume,
                previous: service.canPrevious,
                next: service.canNext,
                visible: panel.visible,
                opened: panel.opened
            });
        }
        function choose(index: int): void { service.selectPlayer(index); }
        function toggle(): void { service.togglePlayback(); }
        function next(): void { service.next(); }
        function previous(): void { service.previous(); }
        function seek(seconds: real): void { service.seekTo(seconds); }
        function volume(value: real): void { service.setVolume(value); }
        function artworkReady(): bool {
            function find(item) {
                if (item.source && String(item.source).includes("spotify.png"))
                    return item.status === Image.Ready;
                for (const child of item.children || []) { if (find(child)) return true; }
                return false;
            }
            return find(panel.contentItem);
        }
        function interactions(): string {
            panel.opened = true;
            input.wait(300);
            input.keyClick(Qt.Key_Escape);
            if (panel.opened) return "Escape failed";
            input.wait(300);
            if (panel.visible) return "Close animation failed";
            panel.opened = true;
            input.wait(300);
            input.mouseClick(panel.contentItem, 10, 10);
            if (panel.opened) return "Outside click failed";
            input.wait(300);
            panel.opened = true;
            input.wait(300);
            input.mouseClick(panel.contentItem, panel.width - 200, 100);
            if (!panel.opened) return "Inside click failed";
            panel.opened = false;
            return "passed";
        }
    }
}
