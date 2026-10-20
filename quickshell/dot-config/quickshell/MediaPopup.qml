import QtQuick
import Quickshell
import Quickshell.Io

Dropdown {
    id: root

    readonly property var player: Audio.player
    readonly property real length: player?.length ?? 0

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        const pad = n => String(n).padStart(2, "0");
        return m >= 60 ? `${Math.floor(m / 60)}:${pad(m % 60)}:${pad(s % 60)}` : `${m}:${pad(s % 60)}`;
    }

    cardWidth: 360
    left: (screen.width - cardWidth) / 2
    spacing: 12
    onOpenChanged: Audio.held = open

    IpcHandler {
        target: "media"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.open && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    Row {
        width: parent.width
        spacing: 14

        Rectangle {
            width: 64
            height: 64
            radius: 4
            color: Theme.tertiary
            border.width: 2
            border.color: Theme.onSurface

            Rectangle {
                z: -1
                x: 3
                y: 3
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.tertiary
            }

            Text {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "\u{f075a}"
                color: Theme.onPrimary
                font.family: Theme.iconFont
                font.pixelSize: 28
            }

            Image {
                id: art
                anchors.fill: parent
                anchors.margins: 2
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
            }
        }

        Column {
            width: parent.width - 64 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.player?.identity ?? ""
                color: Theme.onSurfaceVariant
                font.family: Theme.font
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player?.trackTitle || "Nothing playing"
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                visible: text !== ""
                color: Theme.onSurfaceVariant
                font.family: Theme.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8
        visible: root.length > 0

        Text {
            width: 40
            anchors.verticalCenter: parent.verticalCenter
            text: root.clock(root.player?.position ?? 0)
            color: Theme.onSurfaceVariant
            font.family: Theme.font
            font.pixelSize: 11
        }
        Slider {
            width: parent.width - 2 * (40 + parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            thickness: 8
            knob: 14
            label: "Seek"
            enabled: root.player?.canSeek ?? false
            value: root.length > 0 ? (root.player?.position ?? 0) / root.length : 0
            onMoved: v => root.player.position = v * root.length
        }
        Text {
            width: 40
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.clock(root.length)
            color: Theme.onSurfaceVariant
            font.family: Theme.font
            font.pixelSize: 11
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Key {
            anchors.verticalCenter: parent.verticalCenter
            icon: "\u{f04ae}"
            label: "Previous"
            opacity: root.player?.canGoPrevious ? 1 : 0.4
            onClicked: root.player?.previous()
        }
        Key {
            size: 44
            accent: true
            icon: root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}"
            label: root.player?.isPlaying ? "Pause" : "Play"
            onClicked: root.player?.togglePlaying()
        }
        Key {
            anchors.verticalCenter: parent.verticalCenter
            icon: "\u{f04ad}"
            label: "Next"
            opacity: root.player?.canGoNext ? 1 : 0.4
            onClicked: root.player?.next()
        }
    }
}
