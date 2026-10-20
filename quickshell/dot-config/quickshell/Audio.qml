pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    property bool held: false
    readonly property bool active: playing || held || linger.running
    property var levels: []

    onPlayingChanged: {
        if (!playing)
            linger.restart();
    }

    Timer {
        id: linger
        interval: 2000
    }

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellDir + "/cava.conf"]
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";", 16).map(Number)
        }
    }
}
