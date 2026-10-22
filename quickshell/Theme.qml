pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int radius: 8
    readonly property int gapsOut: 12
    readonly property int gapsIn: 6
    readonly property int pillHeight: 36
    readonly property int borderWidth: 2
    readonly property int shadowOffset: 5

    readonly property var enterCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var exitCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property int enterMs: 400
    readonly property int exitMs: 200

    readonly property string font: "0xProto Nerd Font"
    readonly property string iconFont: "0xProto Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 16

    property var palette: ({})
    property bool swapping: false

    readonly property color pillSolid: palette.surface_container ?? "#261e19"
    readonly property color pill: Qt.alpha(pillSolid, 0.9)
    readonly property color raise: palette.surface_container_high ?? "#312823"
    readonly property color track: palette.surface_container_highest ?? "#3d332d"
    readonly property color onPrimary: palette.on_primary ?? "#512400"
    readonly property color onSurface: palette.on_surface ?? "#f0dfd7"
    readonly property color onSurfaceVariant: palette.on_surface_variant ?? "#d7c2b8"
    readonly property color primary: palette.primary ?? "#ffb68a"
    readonly property color primaryContainer: palette.primary_container ?? "#723610"
    readonly property color primaryContainerText: palette.on_primary_container ?? "#ffdbc8"
    readonly property color tertiary: palette.tertiary ?? "#cbc992"
    readonly property color outlineVariant: palette.outline_variant ?? "#52443c"
    readonly property color error: palette.error ?? "#ffb4ab"

    readonly property var textFringe: [
        {
            x: -1,
            y: 0,
            color: root.primary
        },
        {
            x: 1,
            y: 0,
            color: root.tertiary
        }
    ]

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"

    Timer {
        id: swapEnd
        interval: 100
        onTriggered: root.swapping = false
    }

    FileView {
        path: root.stateDir + "/theme/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.swapping = true;
                root.palette = JSON.parse(text());
                swapEnd.restart();
            } catch (e) {
                console.warn("Theme: unreadable colors.json, keeping previous palette:", e);
            }
        }
    }
}
