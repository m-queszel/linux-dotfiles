import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    required property ShellScreen screen
    readonly property int radius: 16

    // 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right
    Variants {
        model: [0, 1, 2, 3]

        PanelWindow {
            id: corner

            required property int modelData
            readonly property bool atTop: modelData < 2
            readonly property bool atLeft: modelData % 2 === 0

            screen: root.screen
            anchors {
                top: corner.atTop
                bottom: !corner.atTop
                left: corner.atLeft
                right: !corner.atLeft
            }
            implicitWidth: root.radius
            implicitHeight: root.radius
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-corners"
            mask: Region {}

            Shape {
                anchors.fill: parent
                rotation: [0, 90, 270, 180][corner.modelData]
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "black"
                    strokeWidth: -1
                    startX: 0
                    startY: 0

                    PathLine {
                        x: root.radius
                        y: 0
                    }
                    PathArc {
                        x: 0
                        y: root.radius
                        radiusX: root.radius
                        radiusY: root.radius
                        direction: PathArc.Counterclockwise
                    }
                    PathLine {
                        x: 0
                        y: 0
                    }
                }
            }
        }
    }
}
