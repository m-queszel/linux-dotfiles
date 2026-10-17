import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Two floating pills (workspaces left, status right), hidden until SUPER is held.
// Hyprland drives visibility with custom socket events (~/.config/hypr/confd/bar.lua):
//   bar:peek:1 / bar:peek:0   SUPER pressed / released
//   bar:pin:1  / bar:pin:0    SUPER+SHIFT+B (stays shown, still floating over windows)
Scope {
    id: root

    property bool peeking: false
    property bool pinned: false
    readonly property bool shown: peeking || pinned

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "custom")
                return;
            const m = event.data.match(/^bar:(peek|pin):([01])$/);
            if (!m)
                return;
            if (m[1] === "peek")
                root.peeking = m[2] === "1";
            else
                root.pinned = m[2] === "1";
        }
    }

    // Pinned state survives restarts in the same file the Hyprland side writes.
    FileView {
        path: Theme.stateDir + "/bar-pinned"
        printErrors: false
        onLoaded: root.pinned = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.gapsOut + Theme.pillHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore // always floats over windows, pinned or not
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"

            // Only the pills take clicks, and only while shown: hidden, everything passes through.
            mask: Region {
                Region {
                    item: root.shown ? leftPill : null
                }
                Region {
                    item: root.shown ? rightPill : null
                }
            }

            Pill {
                id: leftPill
                shown: root.shown
                x: Theme.gapsOut
                Workspaces {}
            }

            Pill {
                id: rightPill
                shown: root.shown
                x: panel.width - width - Theme.gapsOut
                spacing: 16

                Volume {}
                NetworkStatus {}
                SystemStats {
                    active: root.shown
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 18
                    color: Qt.alpha(Theme.outlineVariant, 0.7)
                }
                Clock {}
            }
        }
    }
}
