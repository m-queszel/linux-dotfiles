import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property var workspace: Hyprland.monitorFor(screen)?.activeWorkspace ?? null
    readonly property bool shown: workspace !== null && workspace.toplevels.values.length === 0
    readonly property int slide: 24
    readonly property int padding: 24
    property real reveal: shown ? 1 : 0
    property var quotes: []
    readonly property var quote: quotes.length ? quotes[Math.floor(clock.date.getTime() / 86400000) % quotes.length] : null
    readonly property var player: Audio.playing ? Audio.player : null
    readonly property var time: Qt.formatTime(clock.date, "h:mm AP").split(" ")

    Behavior on reveal {
        NumberAnimation {
            duration: root.shown ? Theme.enterMs : Theme.exitMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? Theme.enterCurve : Theme.exitCurve
        }
    }

    visible: reveal > 0
    anchors {
        bottom: true
        left: true
    }
    margins {
        bottom: 48
        left: 48
    }
    implicitWidth: card.width + Theme.shadowOffset
    implicitHeight: card.height + Theme.shadowOffset + slide
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop"
    mask: Region {}

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/zsh/quotes.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.quotes = text().split("\n").filter(l => l.includes("\t")).map(l => l.split("\t"))
    }

    Card {
        id: card

        y: root.slide * (1 - root.reveal)
        opacity: root.reveal
        width: 460
        height: content.implicitHeight + root.padding * 2

        Column {
            id: content

            x: root.padding
            y: root.padding
            width: card.width - root.padding * 2
            spacing: 6

            Row {
                spacing: 8

                FringeText {
                    text: root.time[0]
                    color: Theme.onSurface
                    font.family: Theme.font
                    font.pixelSize: 64
                    font.weight: Font.Bold
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    text: root.time[1] ?? ""
                    color: Theme.primary
                    font.family: Theme.font
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }

            Text {
                text: Qt.formatDate(clock.date, "dddd d MMMM")
                color: Theme.onSurfaceVariant
                font.family: Theme.font
                font.pixelSize: 13
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2
            }

            Rectangle {
                visible: root.quote !== null
                width: 40
                height: Theme.borderWidth
                color: Theme.primary
            }

            Text {
                visible: root.quote !== null
                width: parent.width
                text: root.quote ? `“${root.quote[0]}”` : ""
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                lineHeight: 1.2
            }
            Text {
                visible: root.quote !== null
                width: parent.width
                text: root.quote ? `— ${root.quote[1]}` : ""
                color: Theme.onSurfaceVariant
                font.family: Theme.font
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
            }

            Text {
                visible: root.player !== null
                width: parent.width
                topPadding: 6
                text: root.player ? `\u{f075a}  ${root.player.trackTitle}${root.player.trackArtist ? " · " + root.player.trackArtist : ""}` : ""
                color: Theme.tertiary
                font.family: Theme.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}
