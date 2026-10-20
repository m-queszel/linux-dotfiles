import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property url art: ""
    property bool playing: false
    property real spin: 0
    readonly property int size: 44
    readonly property int peek: 22
    readonly property color vinyl: Qt.darker(Theme.pillSolid, 2.6)

    implicitWidth: size + peek + Theme.shadowOffset
    implicitHeight: size + Theme.shadowOffset

    Item {
        id: disc

        x: root.playing ? root.peek : 4
        y: 2
        width: root.size - 4
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.vinyl
            border.width: 1
            border.color: Qt.alpha(Theme.onSurface, 0.14)
        }

        Repeater {
            model: [0.84, 0.72, 0.6]

            Rectangle {
                required property real modelData

                anchors.centerIn: parent
                width: disc.width * modelData
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Theme.onSurface, 0.07)
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"

                PathAngleArc {
                    centerX: disc.width / 2
                    centerY: disc.height / 2
                    radiusX: disc.width / 2 - 1
                    radiusY: disc.height / 2 - 1
                    startAngle: 0
                    sweepAngle: 360
                }

                fillGradient: ConicalGradient {
                    centerX: disc.width / 2
                    centerY: disc.height / 2
                    angle: 40

                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.onSurface, 0)
                    }

                    GradientStop {
                        position: 0.07
                        color: Qt.alpha(Theme.onSurface, 0.18)
                    }

                    GradientStop {
                        position: 0.15
                        color: Qt.alpha(Theme.onSurface, 0)
                    }

                    GradientStop {
                        position: 0.5
                        color: Qt.alpha(Theme.onSurface, 0)
                    }

                    GradientStop {
                        position: 0.57
                        color: Qt.alpha(Theme.onSurface, 0.18)
                    }

                    GradientStop {
                        position: 0.65
                        color: Qt.alpha(Theme.onSurface, 0)
                    }

                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.onSurface, 0)
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: 16
            height: 16
            rotation: root.spin

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.primary
            }

            Rectangle {
                x: 7
                y: 2
                width: 2
                height: 4
                radius: 1
                color: Theme.onPrimary
            }

            Rectangle {
                anchors.centerIn: parent
                width: 3
                height: 3
                radius: 1.5
                color: root.vinyl
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutBack
            }
        }
    }

    Rectangle {
        x: Theme.shadowOffset
        y: Theme.shadowOffset
        width: root.size
        height: root.size
        radius: 4
        color: Theme.tertiary
    }

    Rectangle {
        width: root.size
        height: root.size
        radius: 4
        color: Theme.raise
        border.width: Theme.borderWidth
        border.color: Theme.primary

        Image {
            id: cover

            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            source: root.art
            sourceSize: Qt.size(root.size * 2, root.size * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !cover.visible
            text: "\u{f075a}"
            color: Theme.primary
            font.family: Theme.iconFont
            font.pixelSize: 20
        }
    }

    // Timer, not an animation: animations redraw on every 240 Hz vsync
    Timer {
        interval: 16
        repeat: true
        running: root.playing && root.visible
        onTriggered: root.spin = (root.spin + 3.33) % 360
    }
}
