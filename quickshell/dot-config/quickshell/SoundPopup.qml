import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire

Dropdown {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var net: Networking.devices.values.find(d => d.connected) ?? null
    property bool picking: false

    left: screen.width - Theme.gapsOut - cardWidth
    onOpenChanged: picking = false

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    IpcHandler {
        target: "sound"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    component Label: Text {
        color: Theme.onSurfaceVariant
        font.family: Theme.font
        font.pixelSize: 11
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    component Rule: Row {
        spacing: 3

        Repeater {
            model: Math.floor(parent.width / 5)

            Rectangle {
                width: 2
                height: 2
                color: Theme.outlineVariant
            }
        }
    }

    component Channel: Row {
        id: channel

        required property var node
        required property bool input
        readonly property var audio: node?.audio ?? null
        readonly property bool muted: audio?.muted ?? true

        spacing: 10

        Key {
            anchors.verticalCenter: parent.verticalCenter
            icon: channel.input ? (channel.muted ? "\u{f036d}" : "\u{f036c}") : (channel.muted ? "\u{f075f}" : "\u{f057e}")
            label: channel.muted ? "Unmute" : "Mute"
            onClicked: if (channel.audio)
                channel.audio.muted = !channel.audio.muted
        }
        Slider {
            width: channel.width - 34 - 44 - 2 * channel.spacing
            anchors.verticalCenter: parent.verticalCenter
            label: channel.input ? "Microphone volume" : "Output volume"
            value: channel.audio?.volume ?? 0
            onMoved: v => channel.audio.volume = v
        }
        Text {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: channel.muted ? "muted" : Math.round((channel.audio?.volume ?? 0) * 100) + "%"
            color: channel.muted ? Theme.error : Theme.onSurface
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Label {
        text: "Output"
    }
    Channel {
        width: parent.width
        node: root.sink
        input: false
    }

    MouseArea {
        width: parent.width
        height: 30
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picking = !root.picking

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            width: parent.width - 16
            spacing: 10

            Text {
                text: "\u{f02cb}"
                color: Theme.onSurfaceVariant
                font.family: Theme.iconFont
                font.pixelSize: 15
            }
            Text {
                width: parent.width - 50
                text: root.sink?.description ?? "No output"
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                text: root.picking ? "\u{f0143}" : "\u{f0140}"
                color: Theme.onSurfaceVariant
                font.family: Theme.iconFont
                font.pixelSize: 15
            }
        }
    }

    Column {
        width: parent.width
        visible: root.picking

        Repeater {
            model: root.sinks

            MouseArea {
                id: option

                required property var modelData
                readonly property bool current: modelData === root.sink

                width: parent.width
                height: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Pipewire.preferredDefaultAudioSink = modelData;
                    root.picking = false;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: option.containsMouse ? Qt.alpha(Theme.primary, 0.14) : "transparent"
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    width: parent.width - 16
                    spacing: 10

                    Text {
                        text: option.current ? "\u{f043e}" : "\u{f043d}"
                        color: option.current ? Theme.primary : Theme.onSurfaceVariant
                        font.family: Theme.iconFont
                        font.pixelSize: 15
                    }
                    Text {
                        width: parent.width - 25
                        text: option.modelData.description || option.modelData.name
                        color: Theme.onSurface
                        font.family: Theme.font
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Rule {
        width: parent.width
    }
    Label {
        text: "Input"
    }
    Channel {
        width: parent.width
        node: root.source
        input: true
    }

    Rule {
        width: parent.width
    }
    Row {
        width: parent.width
        spacing: 10

        Text {
            text: !root.net ? "\u{f05aa}" : root.net.type === DeviceType.Wifi ? "\u{f05a9}" : "\u{f0200}"
            color: root.net ? Theme.primary : Theme.error
            font.family: Theme.iconFont
            font.pixelSize: 16
        }
        Text {
            width: parent.width - 120
            text: !root.net ? "Offline" : (root.net.type === DeviceType.Wifi ? "Wi-Fi · " : "Wired · ") + root.net.name
            color: Theme.onSurface
            font.family: Theme.font
            font.pixelSize: 13
            elide: Text.ElideRight
        }
        Text {
            width: 84
            horizontalAlignment: Text.AlignRight
            text: root.net ? "connected" : ""
            color: Theme.onSurfaceVariant
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
