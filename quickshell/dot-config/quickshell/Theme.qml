pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens for the whole shell. Sizes mirror ~/.config/hypr/confd/look.lua.
// Colors are generated from the wallpaper by matugen (`wallpaper <image>`) into
// $XDG_STATE_HOME/theme/colors.json and reload live; the fallbacks cover a fresh install.
Singleton {
    id: root

    readonly property int radius: 14
    readonly property int gapsOut: 12
    readonly property int gapsIn: 6
    readonly property int pillHeight: 36

    readonly property string font: "Nunito"
    readonly property string iconFont: "0xProto Nerd Font"
    readonly property int fontSize: 13
    readonly property int iconSize: 16

    property var palette: ({})

    readonly property color pill: Qt.alpha(palette.surface_container_high ?? "#2f2621", 0.88)
    readonly property color onSurface: palette.on_surface ?? "#f0dfd7"
    readonly property color onSurfaceVariant: palette.on_surface_variant ?? "#d7c2b8"
    readonly property color primary: palette.primary ?? "#ffb68a"
    readonly property color outlineVariant: palette.outline_variant ?? "#52443c"
    readonly property color error: palette.error ?? "#ffb4ab"

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"

    FileView {
        path: root.stateDir + "/theme/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: unreadable colors.json, keeping previous palette:", e);
            }
        }
    }
}
