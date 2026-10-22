import QtQuick

Item {
    id: root

    readonly property int barCount: 16
    readonly property int segments: 6
    property real reveal: 0
    property real slide: 0
    property real spread: 1
    property real shake: 0
    property int frame: 0
    property var popup

    implicitWidth: content.implicitWidth + 20
    height: Theme.pillHeight
    clip: true

    Rectangle {
        y: 3
        width: parent.width
        height: parent.height - 6
        radius: 6
        color: Qt.alpha(Theme.primary, 0.14)
        visible: hover.containsMouse || (root.popup?.open ?? false)
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popup.open = !root.popup.open
    }

    Row {
        id: content

        x: 10 + Glitch.jitter
        y: Audio.active ? (root.height - height) / 2 : -height - 2
        spacing: 12

        Behavior on y {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutBack
            }
        }

        Vinyl {
            anchors.verticalCenter: parent.verticalCenter
            frame: root.frame
            slide: root.slide
            spread: root.spread
            transform: Translate {
                x: root.shake
            }
        }

        Item {
            id: bars

            anchors.verticalCenter: parent.verticalCenter
            width: root.barCount * 5 + (root.barCount - 1) * 3
            height: root.segments * 4 - 1
            transform: Translate {
                x: -root.shake
            }

            Row {
                spacing: 3

                Repeater {
                    model: root.barCount

                    Item {
                        id: bar

                        required property int index
                        readonly property int fill: Math.max(0, Math.min(Audio.levels[index] ?? 0, Math.floor(root.reveal)) * 4 - 1)

                        width: 5
                        height: bars.height

                        Repeater {
                            model: Theme.textFringe

                            Rectangle {
                                required property var modelData

                                x: modelData.x * root.spread
                                y: bar.height - height
                                width: 5
                                height: bar.fill
                                color: modelData.color
                            }
                        }

                        Item {
                            y: bar.height - height
                            width: 5
                            height: bar.fill
                            clip: true

                            Rectangle {
                                y: parent.height - height
                                width: 5
                                height: bars.height
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Theme.primary
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Theme.tertiary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Repeater {
                model: root.segments - 1

                Rectangle {
                    required property int index

                    x: -3
                    y: bars.height - 4 * (index + 1)
                    width: bars.width + 6
                    height: 1
                    color: Theme.pill
                }
            }
        }
    }

    Timer {
        interval: 125
        repeat: true
        running: Audio.playing && root.slide > 13
        onTriggered: root.frame = (root.frame + 1) % 8
    }

    Connections {
        target: Audio
        function onPlayingChanged() {
            enter.stop();
            leave.stop();
            (Audio.playing ? enter : leave).start();
        }
    }

    SequentialAnimation {
        id: enter

        PauseAnimation {
            duration: 400
        }
        ScriptAction {
            script: landGlitch.restart()
        }
        NumberAnimation {
            target: root
            property: "slide"
            to: 14
            duration: 380
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: root
            property: "reveal"
            to: root.segments
            duration: 320
        }
    }

    SequentialAnimation {
        id: leave

        NumberAnimation {
            target: root
            property: "reveal"
            to: 0
            duration: 300
        }
        NumberAnimation {
            target: root
            property: "slide"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }
    }

    SequentialAnimation {
        id: landGlitch

        PropertyAction {
            target: root
            property: "spread"
            value: 4
        }
        PropertyAction {
            target: root
            property: "shake"
            value: -2
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: root
            property: "spread"
            value: -3
        }
        PropertyAction {
            target: root
            property: "shake"
            value: 2
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 2
        }
        PropertyAction {
            target: root
            property: "shake"
            value: -1
        }
        PauseAnimation {
            duration: 40
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 1
        }
        PropertyAction {
            target: root
            property: "shake"
            value: 0
        }
    }
}
