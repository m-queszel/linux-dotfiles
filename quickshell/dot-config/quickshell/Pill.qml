import QtQuick

// A rounded pill that slides down from above the screen edge when `shown`.
// Children are laid out in a row; the pill grows smoothly as they do.
Rectangle {
    id: root

    property bool shown: false
    property alias spacing: row.spacing
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * 14
    implicitHeight: Theme.pillHeight
    radius: Theme.radius
    color: Theme.pill

    // Hidden just above the screen edge, so the slide is short and the peek feels instant
    y: shown ? Theme.gapsOut : -height
    opacity: shown ? 1 : 0

    Behavior on y {
        // Like the "gentle" window spring in look.lua: fast start, soft settle
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
