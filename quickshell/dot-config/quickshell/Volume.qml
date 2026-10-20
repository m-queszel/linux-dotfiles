import QtQuick
import Quickshell.Services.Pipewire

RevealItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property int percent: Math.round((audio?.volume ?? 0) * 100)
    readonly property bool muted: audio?.muted ?? true

    leader: muted ? "󰝟" : percent < 34 ? "󰕿" : percent < 67 ? "󰖀" : "󰕾"
    value: audio ? (muted ? "muted" : percent + "%") : "no output"

    onScrolled: steps => {
        if (audio)
            audio.volume = Math.max(0, Math.min(1, audio.volume + steps * 0.05));
    }

    // Pipewire only reports live volume for tracked nodes
    PwObjectTracker {
        objects: [root.sink]
    }
}
