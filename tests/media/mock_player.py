"""Small MPRIS 2 fixture for the isolated Phase 6 integration test."""
import sys

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib


dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus(private=True)
name = sys.argv[1]
identity = sys.argv[2]
limited = len(sys.argv) > 3 and sys.argv[3] == "limited"
bus_name = dbus.service.BusName(name, bus=bus, do_not_queue=True)


class Player(dbus.service.Object):
    def __init__(self):
        super().__init__(bus, "/org/mpris/MediaPlayer2")
        self.status = "Playing" if identity == "Spotify" else "Paused"
        self.title = "First Song" if identity == "Spotify" else "Browser Track"
        self.artist = "Example Artist"
        self.album = "Example Album"
        self.artwork = ""
        self.position = 20_000_000
        self.volume = 0.6
        self.calls = []

    def metadata(self):
        return dbus.Dictionary({
            "mpris:trackid": dbus.ObjectPath("/org/mpris/MediaPlayer2/Track/1"),
            "mpris:length": dbus.Int64(120_000_000),
            "xesam:title": self.title,
            "xesam:artist": dbus.Array([self.artist], signature="s"),
            "xesam:album": self.album,
            "mpris:artUrl": self.artwork,
        }, signature="sv")

    def properties(self, interface):
        if interface == "org.mpris.MediaPlayer2":
            return {
                "Identity": identity,
                "DesktopEntry": "spotify" if identity == "Spotify" else "firefox",
                "CanQuit": False,
                "CanRaise": False,
                "HasTrackList": False,
                "SupportedUriSchemes": dbus.Array([], signature="s"),
                "SupportedMimeTypes": dbus.Array([], signature="s"),
            }
        if interface == "org.mpris.MediaPlayer2.Player":
            result = {
                "PlaybackStatus": self.status,
                "CanControl": True,
                "CanPlay": True,
                "CanPause": True,
                "CanGoNext": not limited,
                "CanGoPrevious": not limited,
                "CanSeek": not limited,
                "Metadata": self.metadata(),
                "Position": dbus.Int64(self.position),
                "MinimumRate": 1.0,
                "MaximumRate": 1.0,
                "Rate": 1.0,
            }
            if not limited:
                result["Volume"] = self.volume
            return result
        raise dbus.exceptions.DBusException("Unknown interface", name="org.freedesktop.DBus.Error.InvalidArgs")

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        return self.properties(interface)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface, key):
        return self.properties(interface)[key]

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ssv")
    def Set(self, interface, key, value):
        if interface != "org.mpris.MediaPlayer2.Player":
            return
        if key == "Volume" and not limited:
            self.volume = float(value)
            self.calls.append("volume")
            self.PropertiesChanged(interface, {"Volume": self.volume}, [])

    @dbus.service.signal("org.freedesktop.DBus.Properties", signature="sa{sv}as")
    def PropertiesChanged(self, interface, changed, invalidated):
        pass

    @dbus.service.method("org.mpris.MediaPlayer2.Player")
    def PlayPause(self):
        self.calls.append("toggle")
        self.status = "Paused" if self.status == "Playing" else "Playing"
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"PlaybackStatus": self.status}, [])

    @dbus.service.method("org.mpris.MediaPlayer2.Player")
    def Play(self):
        self.calls.append("play")
        self.status = "Playing"
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"PlaybackStatus": self.status}, [])

    @dbus.service.method("org.mpris.MediaPlayer2.Player")
    def Pause(self):
        self.calls.append("pause")
        self.status = "Paused"
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"PlaybackStatus": self.status}, [])

    @dbus.service.method("org.mpris.MediaPlayer2.Player")
    def Next(self):
        self.calls.append("next")
        self.title = "Next Song"
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"Metadata": self.metadata()}, [])

    @dbus.service.method("org.mpris.MediaPlayer2.Player")
    def Previous(self):
        self.calls.append("previous")
        self.title = "Previous Song"
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"Metadata": self.metadata()}, [])

    @dbus.service.method("org.mpris.MediaPlayer2.Player", in_signature="x")
    def Seek(self, offset):
        self.calls.append("seek")
        self.position += offset
        self.Seeked(self.position)

    @dbus.service.method("org.mpris.MediaPlayer2.Player", in_signature="ox")
    def SetPosition(self, track, position):
        self.calls.append("setPosition")
        self.position = int(position)
        self.Seeked(self.position)

    @dbus.service.signal("org.mpris.MediaPlayer2.Player", signature="x")
    def Seeked(self, position):
        pass

    @dbus.service.method("org.void.MediaTest", out_signature="as")
    def GetCalls(self):
        return self.calls

    @dbus.service.method("org.void.MediaTest", in_signature="ssss")
    def SetMetadata(self, title, artist, album, artwork):
        self.title, self.artist, self.album, self.artwork = title, artist, album, artwork
        self.PropertiesChanged("org.mpris.MediaPlayer2.Player", {"Metadata": self.metadata()}, [])


player = Player()
GLib.MainLoop().run()
