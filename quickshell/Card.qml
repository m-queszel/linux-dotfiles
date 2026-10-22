import QtQuick

Rectangle {
    id: root

    property color edge: Theme.primary
    property color shadowColor: Theme.tertiary
    property bool attached: false
    readonly property int offset: Theme.shadowOffset

    radius: Theme.radius
    color: attached ? "transparent" : Theme.pill
    border.width: attached ? 0 : Theme.borderWidth
    border.color: edge

    component Cut: Item {
        id: cut

        required property Card card

        z: -1
        clip: true

        Rectangle {
            x: cut.card.offset - cut.x
            y: cut.card.offset - cut.y
            width: cut.card.width
            height: cut.card.height
            radius: cut.card.radius
            color: cut.card.shadowColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.attached
        clip: true

        Rectangle {
            y: -(root.radius + Theme.borderWidth)
            width: parent.width
            height: parent.height - y
            radius: root.radius
            color: Theme.pill
            border.width: Theme.borderWidth
            border.color: root.edge
        }
    }

    Cut {
        card: root
        x: root.width
        width: root.offset
        height: root.height + root.offset
    }
    Cut {
        card: root
        y: root.height
        width: root.width
        height: root.offset
    }
    Cut {
        card: root
        x: root.width - root.radius
        y: root.height - root.radius
        width: root.radius
        height: root.radius
    }
}
