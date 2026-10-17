pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// Workspace dots: always 1-5, plus any higher workspace that exists. The active dot stretches
// with a spring; occupied ones are darker. Click to switch (Lua dispatch syntax).
Row {
    id: root

    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))

    height: parent.height
    spacing: 0

    Repeater {
        model: root.count

        delegate: Item {
            id: slot

            required property int index
            readonly property int wsId: index + 1
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0

            width: dot.width + 8
            height: root.height

            Rectangle {
                id: dot
                anchors.centerIn: parent
                height: 9
                radius: height / 2
                width: slot.active ? 26 : 9
                color: slot.active ? Theme.primary : mouse.containsMouse ? Qt.alpha(Theme.primary, 0.6) : Qt.alpha(Theme.onSurface, slot.occupied ? 0.45 : 0.18)

                Behavior on width {
                    SpringAnimation {
                        spring: 4
                        damping: 0.3
                        epsilon: 0.25
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${slot.wsId} })`)
            }
        }
    }
}
