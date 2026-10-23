import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property var apps: ["spotify", "discord"]
    readonly property int tabW: 76
    readonly property int tabH: 84
    readonly property int railTop: 28
    readonly property int edge: 12
    property string shown: ""
    property string last: "spotify"
    property rect modal: Qt.rect(0, 0, 0, 0)
    property bool peek: false
    readonly property bool open: shown !== ""
    readonly property string iconDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/icons/PixelInk/24x24/apps/"
    property string icons: iconDir
    readonly property color glass: Qt.alpha(Theme.palette.surface ?? "#1a1110", 0.72)
    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    property string menuFifo: ""
    property point menuAt: Qt.point(0, 0)
    property string menuApp: ""
    readonly property var menuItems: {
        const own = {
            discord: [["voice", "Join / leave voice", "v"], ["mute", "Mute mic", "alt+v"], ["deafen", "Deafen", "alt+d"]],
            spotify: [["play", "Play / pause", "space"], ["next", "Next track", "n"], ["previous", "Previous track", "p"], ["lyrics", "Lyrics", "l"], ["search", "Search", "/"]]
        }[menuApp] ?? [];
        return own.concat(own.length ? [["", "", ""]] : [], [["copy", "Copy", "⇧ drag"], ["paste", "Paste", ""]]);
    }

    function toggle(app) {
        toggler.command = ["hyprctl", "eval", `Drawer.toggle("${app}")`];
        toggler.running = true;
    }

    function pick(choice) {
        if (!menuFifo)
            return;
        picker.command = ["sh", "-c", 'printf "%s\\n" "$1" > "$2"', "sh", choice, menuFifo];
        picker.running = true;
        menuFifo = "";
    }

    Process {
        id: toggler
    }

    Process {
        id: syncer

        command: ["hyprctl", "eval", "Drawer.sync()"]
    }

    Timer {
        interval: 500
        running: true
        onTriggered: syncer.running = true
    }

    Process {
        id: picker
    }

    IpcHandler {
        target: "drawer"

        function menu(fifo: string, x: int, y: int, app: string): void {
            root.pick("none");
            root.menuApp = app;
            root.menuAt = Qt.point(x, y);
            root.menuFifo = fifo;
        }
    }

    PanelWindow {
        id: menuWin

        screen: root.screen
        visible: root.menuFifo !== ""
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-drawer-menu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onReleased: root.pick("none")
        }

        Card {
            x: Math.min(root.menuAt.x - root.screen.x, menuWin.width - width - 12)
            y: Math.min(root.menuAt.y - root.screen.y, menuWin.height - height - 12)
            width: 230
            height: items.implicitHeight + 12
            focus: true
            Keys.onEscapePressed: root.pick("none")

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: items

                x: 6
                y: 6
                width: parent.width - 12

                Repeater {
                    model: root.menuItems

                    Rectangle {
                        id: item

                        required property var modelData
                        readonly property bool line: modelData[0] === ""

                        width: items.width
                        height: line ? 9 : 30
                        radius: 5
                        color: !line && itemHover.hovered ? Theme.raise : "transparent"

                        Rectangle {
                            visible: item.line
                            x: 6
                            y: 4
                            width: parent.width - 12
                            height: 1
                            color: Theme.outlineVariant
                        }

                        Text {
                            visible: !item.line
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.modelData[1]
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: itemHover.hovered ? Theme.primary : Theme.onSurface
                        }

                        Text {
                            visible: !item.line
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.modelData[2]
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.palette.outline ?? Theme.onSurfaceVariant
                        }

                        HoverHandler {
                            id: itemHover

                            enabled: !item.line
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            enabled: !item.line
                            onTapped: root.pick(item.modelData[0])
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "custom" || !event.data.startsWith("drawer>>"))
                return;
            const [state, x, y, w, h] = event.data.slice(8).split(",");
            const prev = root.shown;
            const next = state === "none" ? "" : state;
            root.modal = Qt.rect(+x, +y, +w, +h);
            ind.jump = !prev && !!next;
            if (next)
                root.last = next;
            root.shown = next;
            ind.jump = false;
            if (!next)
                root.pick("none");
            if (root.shown) {
                root.peek = false;
                if (prev && prev !== root.shown)
                    rail.knock(root.shown, root.apps.indexOf(root.shown) > root.apps.indexOf(prev) ? 1 : -1);
            }
        }
    }

    Connections {
        target: Theme

        function onPaletteChanged() {
            root.icons = "";
            Qt.callLater(() => root.icons = root.iconDir);
        }
    }

    PanelWindow {
        id: strip

        screen: root.screen
        anchors {
            right: true
            bottom: true
        }
        margins.bottom: win.sh - (win.railY + win.cardH / 2 + implicitHeight / 2)
        implicitWidth: root.edge
        implicitHeight: 260
        mask: root.open || root.peek ? none : edgeArea
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-drawer"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            x: parent.width - 5
            y: (parent.height - height) / 2
            width: 5
            height: 96
            radius: 3
            color: Theme.primary
            opacity: root.open || root.peek ? 0 : 1

            Rectangle {
                x: -3
                z: -1
                width: parent.width
                height: parent.height
                radius: 3
                color: Theme.tertiary
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.exitMs
                }
            }
        }

        Region {
            id: none
        }

        Region {
            id: edgeArea

            item: edgeMouse
        }

        MouseArea {
            id: edgeMouse

            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (!root.open)
                    root.peek = true;
            }
        }
    }

    PanelWindow {
        id: win

        readonly property real sw: root.screen.width
        readonly property real sh: root.screen.height
        readonly property real cardW: root.tabW + 20 + Theme.radius
        readonly property real cardH: root.tabH * 2 + 30
        readonly property real barTop: Hyprland.focusedMonitor?.lastIpcObject?.reserved?.[1] ?? 38
        readonly property real modalW: root.modal.width || Math.round(Math.min(1150, Math.max(720, sw * 0.33)))
        readonly property real modalH: root.modal.height || Math.round(Math.min(850, Math.max(520, sh * 0.6)))
        readonly property real modalY: root.modal.width ? root.modal.y - root.screen.y : barTop + Math.round((sh - barTop - modalH) / 2)
        readonly property real dockX: (root.modal.width ? root.modal.x - root.screen.x : sw - 14 - modalW) - root.tabW + 2
        readonly property real railY: modalY + root.railTop - 10
        readonly property real left: Math.min(dockX - 10, sw - cardW - 40) - 10
        readonly property real top: railY - 10
        readonly property real bottom: railY + cardH + 10

        screen: root.screen
        anchors {
            right: true
            bottom: true
        }
        margins.bottom: sh - bottom
        implicitWidth: sw - left
        implicitHeight: bottom - top
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-drawer"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {
            item: hit
        }

        Item {
            id: hit

            x: rail.x + (rail.docked ? 10 : 0)
            y: rail.y + (rail.docked ? 10 : 0)
            width: rail.docked ? root.tabW : win.cardW
            height: rail.docked ? root.tabH * 2 + 10 : win.cardH
        }

        Item {
            id: rail

            readonly property bool docked: root.open
            readonly property bool moving: docked || root.peek
            property real spring: 0

            function knock(app, dir) {
                const face = app === "spotify" ? spotifyTab : discordTab;
                face.knock(dir);
            }

            x: docked ? win.dockX - 10 - win.left : root.peek ? win.sw - win.cardW + Theme.radius - win.left : win.sw + 20 - win.left
            y: win.railY - win.top
            width: win.cardW
            height: win.cardH

            Behavior on x {
                NumberAnimation {
                    duration: rail.moving ? Theme.enterMs : Theme.exitMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: rail.moving ? Theme.enterCurve : Theme.exitCurve
                }
            }
            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        leave.stop();
                    else if (root.peek)
                        leave.restart();
                }
            }

            Timer {
                id: leave
                interval: 250
                onTriggered: root.peek = false
            }

            Card {
                anchors.fill: parent
                color: root.glass
                opacity: rail.docked ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.exitMs
                    }
                }
            }

            Item {
                id: ind

                readonly property real target: 10 + root.apps.indexOf(root.last) * (root.tabH + 10)
                property bool jump: false

                x: 10
                y: target
                width: root.tabW
                height: root.tabH
                clip: true
                opacity: rail.docked ? 1 : 0

                Behavior on y {
                    enabled: !ind.jump

                    SpringAnimation {
                        spring: 7
                        damping: 0.38
                        epsilon: 0.25
                    }
                }

                Rectangle {
                    width: parent.width + 10
                    height: parent.height
                    radius: Theme.radius
                    color: root.glass
                    border.width: Theme.borderWidth
                    border.color: Theme.primary
                }
            }

            DrawerTab {
                id: spotifyTab

                app: "spotify"
                index: 0
                docked: rail.docked
                shown: root.shown
                indY: ind.y
                glass: root.glass
                icons: root.icons
                onClicked: root.toggle(app)
            }

            DrawerTab {
                id: discordTab

                app: "discord"
                index: 1
                docked: rail.docked
                shown: root.shown
                indY: ind.y
                glass: root.glass
                icons: root.icons
                onClicked: root.toggle(app)
            }
        }
    }

    property bool settled: false

    onShownChanged: {
        if (!shown)
            settled = false;
        else if (!settled)
            settleTimer.restart();
    }

    Timer {
        id: settleTimer

        interval: Theme.enterMs
        onTriggered: root.settled = true
    }

    DrawerShade {
        strip: Qt.rect(root.modal.x + root.modal.width, root.modal.y + Theme.shadowGap, Theme.shadowGap, root.modal.height - Theme.shadowGap)
    }

    DrawerShade {
        strip: Qt.rect(root.modal.x + Theme.shadowGap, root.modal.y + root.modal.height, root.modal.width, Theme.shadowGap)
    }

    component DrawerShade: PanelWindow {
        id: shade

        required property rect strip

        screen: root.screen
        visible: root.modal.width > 0
        anchors {
            left: true
            bottom: true
        }
        margins.left: strip.x - root.screen.x
        margins.bottom: root.screen.y + root.screen.height - strip.y - strip.height
        implicitWidth: Math.max(1, strip.width)
        implicitHeight: Math.max(1, strip.height)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-drawer-shade"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Item {
            anchors.fill: parent
            clip: true
            opacity: root.settled ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.settled ? 140 : 0
                }
            }

            Rectangle {
                x: root.modal.x + Theme.shadowGap - shade.strip.x
                y: root.modal.y + Theme.shadowGap - shade.strip.y
                width: root.modal.width
                height: root.modal.height
                radius: Theme.radius
                color: Theme.tertiary
            }
        }
    }

    component DrawerTab: Item {
        id: tab

        required property string app
        required property int index
        required property bool docked
        required property string shown
        required property string icons
        readonly property int tabW: 76
        readonly property int tabH: 84
        readonly property bool selected: shown === app
        required property real indY
        required property color glass
        property real kick: 0
        property real kickV: 0
        readonly property real spread: 1 + Math.min(1, Math.abs(kickV) / 230)
        readonly property bool hot: hover.hovered
        property real lift: hot ? -2 : 0

        Behavior on lift {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        function knock(dir) {
            kickV = dir * 230;
            kicking.running = true;
        }

        signal clicked

        x: 10
        y: 10 + index * (tabH + 10)
        width: tabW
        height: tabH

        FrameAnimation {
            id: kicking

            onTriggered: {
                const h = Math.min(0.05, frameTime) / 8, w = 38, z = 0.5;
                for (let i = 0; i < 8; i++) {
                    tab.kickV += (-w * w * tab.kick - 2 * z * w * tab.kickV) * h;
                    tab.kick += tab.kickV * h;
                }
                if (Math.abs(tab.kick) < 0.05 && Math.abs(tab.kickV) < 1) {
                    tab.kick = 0;
                    tab.kickV = 0;
                    running = false;
                }
            }
        }

        Item {
            width: parent.width - 2
            height: parent.height + Theme.shadowOffset
            clip: true
            opacity: tab.docked ? Math.min(1, Math.abs(tab.indY - tab.y) / (tab.tabH + 10)) : 0

            Item {
                y: tab.tabH
                width: parent.width
                height: Theme.shadowOffset
                clip: true

                Rectangle {
                    y: Theme.shadowOffset - tab.tabH
                    width: parent.width + 10
                    height: tab.tabH
                    radius: Theme.radius
                    color: Theme.tertiary
                }
            }

            Rectangle {
                width: parent.width + 10
                height: tab.tabH
                radius: Theme.radius
                color: tab.hot ? Qt.alpha(Theme.raise, 0.8) : tab.glass
                border.width: Theme.borderWidth
                border.color: Theme.outlineVariant

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.raise
            opacity: !tab.docked && tab.hot ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }

        Column {
            x: 2 + (parent.width - 4 - width) / 2
            y: (parent.height - height) / 2 + tab.kick + tab.lift
            spacing: 6

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48
                height: 48

                Image {
                    x: -1
                    width: 48
                    height: 48
                    sourceSize: Qt.size(48, 48)
                    source: tab.icons ? `file://${tab.icons}pixelink-${tab.app}-fringe-a.svg` : ""
                    cache: false
                    smooth: false
                    opacity: Math.min(1, tab.spread - 1)
                }
                Image {
                    x: 1
                    width: 48
                    height: 48
                    sourceSize: Qt.size(48, 48)
                    source: tab.icons ? `file://${tab.icons}pixelink-${tab.app}-fringe-b.svg` : ""
                    cache: false
                    smooth: false
                    opacity: Math.min(1, tab.spread - 1)
                }
                Image {
                    width: 48
                    height: 48
                    sourceSize: Qt.size(48, 48)
                    source: tab.icons ? `file://${tab.icons}pixelink-${tab.app}.svg` : ""
                    cache: false
                    smooth: false
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: label.implicitWidth
                height: label.implicitHeight

                Text {
                    x: -Math.round(tab.spread)
                    text: tab.app
                    font: label.font
                    color: Theme.primary
                }
                Text {
                    x: Math.round(tab.spread)
                    text: tab.app
                    font: label.font
                    color: Theme.tertiary
                }
                Text {
                    id: label

                    text: tab.app
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: tab.hot ? Theme.primary : Theme.onSurface

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }
                }
            }
        }

        HoverHandler {
            id: hover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: tab.clicked()
        }
    }
}
