import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Dropdown {
    id: root

    property bool suppressed: false
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property bool muted: audio?.muted ?? true

    function show() {
        if (warmup.running || suppressed)
            return;
        open = true;
        hide.restart();
    }

    interactive: false
    cardWidth: 300
    left: screen.width - Theme.gapsOut - cardWidth

    Timer {
        id: warmup
        interval: 1500
        running: true
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.open = false
    }

    Connections {
        target: root.audio
        function onVolumeChanged() {
            root.show();
        }
        function onMutedChanged() {
            root.show();
        }
    }

    Row {
        width: parent.width
        spacing: 10

        Text {
            width: 22
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? "\u{f075f}" : "\u{f057e}"
            color: root.muted ? Theme.error : Theme.primary
            font.family: Theme.iconFont
            font.pixelSize: 18
        }
        Slider {
            width: parent.width - 22 - 44 - 2 * parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            label: "Output volume"
            value: root.audio?.volume ?? 0
            onMoved: v => root.audio.volume = v
        }
        Text {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "muted" : Math.round((root.audio?.volume ?? 0) * 100) + "%"
            color: root.muted ? Theme.error : Theme.onSurface
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
