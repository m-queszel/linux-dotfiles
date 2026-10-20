import QtQuick

Item {
    id: root

    property alias text: main.text
    property color color
    property alias font: main.font

    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight

    Repeater {
        model: Theme.textFringe

        Text {
            required property var modelData

            x: modelData.x * Glitch.spread
            y: modelData.y * Glitch.spread
            text: main.text
            font: main.font
            color: modelData.color
        }
    }

    Text {
        id: main
        color: root.color
    }
}
