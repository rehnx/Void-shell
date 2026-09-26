import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root
    property string selectedDbusName: ""
    property bool progressVisible: false

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: {
        if (players.length === 0) return null;
        const selected = players.find(player => player.dbusName === selectedDbusName);
        return selected || players.find(player => player.playbackState === MprisPlaybackState.Playing)
            || players[0];
    }
    readonly property int activeIndex: activePlayer ? players.indexOf(activePlayer) : -1
    readonly property bool available: activePlayer !== null
    readonly property string name: available ? (activePlayer.identity || "Media player") : "No media player"
    readonly property string title: available ? (activePlayer.trackTitle || "Unknown title") : "Nothing playing"
    readonly property string artist: available ? (activePlayer.trackArtist || "Unknown artist") : ""
    readonly property string album: available ? (activePlayer.trackAlbum || "") : ""
    readonly property string artwork: available ? (activePlayer.trackArtUrl || "") : ""
    readonly property bool playing: available && activePlayer.isPlaying
    readonly property bool canToggle: available && activePlayer.canControl && activePlayer.canTogglePlaying
    readonly property bool canPrevious: available && activePlayer.canControl && activePlayer.canGoPrevious
    readonly property bool canNext: available && activePlayer.canControl && activePlayer.canGoNext
    readonly property bool canSeek: available && activePlayer.canControl && activePlayer.canSeek
        && activePlayer.positionSupported && activePlayer.lengthSupported && activePlayer.length > 0
    readonly property bool canSetVolume: available && activePlayer.canControl && activePlayer.volumeSupported
    readonly property real length: canSeek ? activePlayer.length : 0
    readonly property real position: canSeek ? Math.max(0, Math.min(activePlayer.position, length)) : 0
    readonly property real volume: canSetVolume ? Math.max(0, Math.min(activePlayer.volume, 1)) : 0

    onPlayersChanged: {
        if (selectedDbusName && !players.some(player => player.dbusName === selectedDbusName))
            selectedDbusName = "";
    }

    function selectPlayer(index) {
        if (index < 0 || index >= players.length) return;
        selectedDbusName = players[index].dbusName;
    }

    function togglePlayback() {
        if (canToggle) activePlayer.togglePlaying();
    }
    function previous() {
        if (canPrevious) activePlayer.previous();
    }
    function next() {
        if (canNext) activePlayer.next();
    }
    function seekTo(seconds) {
        if (canSeek && isFinite(seconds))
            activePlayer.position = Math.max(0, Math.min(seconds, length));
    }
    function setVolume(value) {
        if (canSetVolume && isFinite(value))
            activePlayer.volume = Math.max(0, Math.min(value, 1));
    }
    function timeText(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(total / 60);
        const remaining = total % 60;
        return minutes + ":" + (remaining < 10 ? "0" : "") + remaining;
    }

    // MPRIS position is read on demand. Refresh only while the panel displays it.
    Timer {
        interval: 1000
        repeat: true
        running: root.progressVisible && root.playing && root.canSeek
        onTriggered: if (root.activePlayer) root.activePlayer.positionChanged()
    }
}
