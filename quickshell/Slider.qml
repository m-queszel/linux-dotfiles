import QtQuick

Item {
    id: root

    property real value: 0
    property int thickness: 10
    property int knob: 18
    property string label
    readonly property real centre: knob / 2 + value * (width - knob)

    signal moved(real value)

    function set(v) {
        v = Math.max(0, Math.min(1, v));
        if (v !== value)
            moved(v);
    }

    implicitHeight: 28
    activeFocusOnTab: true
    Keys.onLeftPressed: set(value - 0.05)
    Keys.onRightPressed: set(value + 0.05)

    Accessible.role: Accessible.Slider
    Accessible.name: label

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2
        color: Theme.track
        border.width: 2
        border.color: Theme.onSurfaceVariant

        Rectangle {
            x: 2
            y: 2
            width: Math.max(0, root.centre - 2)
            height: parent.height - 4
            radius: height / 2
            color: Theme.primary
        }
    }

    Rectangle {
        readonly property real grow: mouse.containsMouse || mouse.pressed || root.activeFocus ? 1.15 : 1
        x: root.centre - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.knob * grow
        height: width
        radius: width / 2
        color: Theme.pillSolid
        border.width: 2
        border.color: Theme.onSurface

        Behavior on width {
            NumberAnimation {
                duration: 120
            }
        }

        Rectangle {
            z: -1
            x: 2
            y: 2
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.tertiary
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            root.forceActiveFocus();
            root.set((event.x - root.knob / 2) / (root.width - root.knob));
        }
        onPositionChanged: event => {
            if (pressed)
                root.set((event.x - root.knob / 2) / (root.width - root.knob));
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.set(root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
