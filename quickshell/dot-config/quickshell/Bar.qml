import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

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
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-bar"

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
