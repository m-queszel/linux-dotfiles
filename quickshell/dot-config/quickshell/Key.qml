import QtQuick

Rectangle {
    id: root

    property string icon
    property string label
    property bool accent: false
    property int size: 34

    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: size > 30 ? 6 : 4
    color: accent ? Theme.primary : Theme.raise
    border.width: 2
    border.color: accent || mouse.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant
    transform: Translate {
        x: mouse.pressed ? 2 : 0
        y: mouse.pressed ? 2 : 0
    }

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked()

    Rectangle {
        z: -1
        x: mouse.pressed ? 0 : 2
        y: mouse.pressed ? 0 : 2
        width: root.width
        height: root.height
        radius: root.radius
        color: Theme.tertiary
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.accent ? Theme.onPrimary : Theme.onSurface
        font.family: Theme.iconFont
        font.pixelSize: Math.round(root.size * 0.47)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
