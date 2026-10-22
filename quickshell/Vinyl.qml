import QtQuick

Item {
    id: root

    property int frame: 0
    property real slide: 0
    property real spread: 1

    readonly property var disc: [[4, 0, 4, 1], [2, 1, 8, 1], [1, 2, 10, 2], [0, 4, 12, 4], [1, 8, 10, 2], [2, 10, 8, 1], [4, 11, 4, 1]]
    readonly property var grooves: [[4, 2, 4, 1], [4, 9, 4, 1], [2, 4, 1, 4], [9, 4, 1, 4], [3, 3, 1, 1], [8, 3, 1, 1], [3, 8, 1, 1], [8, 8, 1, 1]]
    readonly property var label: [[5, 4, 2, 1], [4, 5, 1, 2], [7, 5, 1, 2], [5, 7, 2, 1]]
    readonly property var glints: [[[5, 1, 2, 1]], [[8, 2, 1, 1], [9, 3, 1, 1]], [[10, 5, 1, 2]], [[9, 8, 1, 1], [8, 9, 1, 1]], [[5, 10, 2, 1]], [[2, 8, 1, 1], [3, 9, 1, 1]], [[1, 5, 1, 2]], [[2, 3, 1, 1], [3, 2, 1, 1]]]

    component Pixel: Rectangle {
        required property var modelData

        x: modelData[0] * 2
        y: modelData[1] * 2
        width: modelData[2] * 2
        height: modelData[3] * 2
    }

    implicitWidth: 40
    implicitHeight: 24

    Item {
        x: root.slide
        width: 24
        height: 24

        Repeater {
            model: Theme.textFringe

            Item {
                id: copy

                required property var modelData

                x: modelData.x * root.spread

                Repeater {
                    model: root.disc
                    delegate: Pixel {
                        color: copy.modelData.color
                    }
                }
            }
        }

        Repeater {
            model: root.disc
            delegate: Pixel {
                color: Theme.outlineVariant
            }
        }

        Repeater {
            model: root.grooves
            delegate: Pixel {
                color: Theme.pill
            }
        }

        Repeater {
            model: root.label
            delegate: Pixel {
                color: Theme.primary
            }
        }

        Repeater {
            model: root.glints[root.frame]
            delegate: Pixel {
                color: Theme.onSurface
            }
        }
    }

    Rectangle {
        width: 24
        height: 24
        color: Theme.onSurface

        Rectangle {
            x: 2
            y: 2
            width: 20
            height: 20
            color: Theme.tertiary
        }

        Rectangle {
            x: 2
            y: 6
            width: 20
            height: 4
            color: Theme.primary
        }

        Rectangle {
            x: 14
            y: 14
            width: 6
            height: 6
            color: Theme.pill
        }
    }
}
