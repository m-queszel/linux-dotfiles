import QtQuick

Rectangle {
    id: root

    property bool shown: false
    property alias spacing: row.spacing
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * 14
    implicitHeight: Theme.pillHeight
    radius: Theme.radius
    color: Theme.pill

    y: shown ? Theme.gapsOut : -height
    opacity: shown ? 1 : 0

    Behavior on y {
        SpringAnimation {
            spring: 6
            damping: 0.38
            epsilon: 0.25
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 400
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 6
    }
}
