import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property int toolbarH: 47
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/quasar"
    readonly property string colorsJson: Theme.stateDir + "/theme/colors.json"
    property var art: ({})
    property var queued: []
    property var asked: []
    property int sidebarW: 170
    property bool sidebarShown: true
    property int bookmarks: 0
    property int volumes: 1
    readonly property int listH: 68 + 30 * (3 + bookmarks + 1 + volumes)
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.lastIpcObject?.class === "thunar" && !t.lastIpcObject.floating)

    function file(name) {
        return name ? `file://${cacheDir}/${name}` : "";
    }

    function bucket(emptyH) {
        return Math.max(150, Math.round(emptyH / 50) * 50);
    }

    function loopFor(emptyH) {
        const have = art.heights ?? [];
        if (!art.stamp || !have.length)
            return "";
        const h = bucket(emptyH);
        const best = have.reduce((a, b) => Math.abs(b - h) < Math.abs(a - h) ? b : a);
        return file(`quasar-${best}-${art.stamp}.gif`);
    }

    function request(emptyH) {
        const h = bucket(emptyH);
        if (!art.stamp || (art.heights ?? []).includes(h) || asked.includes(h))
            return;
        asked = [...asked, h];
        queued = [...queued, h];
        if (!render.running)
            render.next();
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.slideWorkspaces(Hyprland.focusedWorkspace?.id ?? -1);
        }

        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2", "activewindowv2", "moveworkspacev2", "openlayer", "closelayer"].includes(event.name))
                settle.restart();
            if (event.name === "openwindow" && event.data.includes(",thunar,")) {
                thunarConf.running = true;
                devices.running = true;
            }
        }
    }

    property int wsFrom: -1
    property int wsTo: -1
    property real wsP: 1
    readonly property int wsDir: wsTo > wsFrom ? 1 : -1
    readonly property bool wsSliding: wsP < 1

    property real wsStart: 0
    readonly property int wsLeadMs: 25

    function slideWorkspaces(to) {
        if (to < 0 || to === wsTo)
            return;
        if (wsTo >= 0) {
            wsFrom = wsTo;
            wsStart = Date.now() - wsLeadMs;
            wsP = 0;
        }
        wsTo = to;
    }

    function easeOutQuint(x) {
        const bez = (t, a, b) => 3 * a * (1 - t) * (1 - t) * t + 3 * b * (1 - t) * t * t + t * t * t;
        let lo = 0, hi = 1;
        for (let i = 0; i < 20; i++) {
            const mid = (lo + hi) / 2;
            if (bez(mid, 0.23, 0.32) < x)
                lo = mid;
            else
                hi = mid;
        }
        return bez(lo, 1, 1);
    }

    Component.onCompleted: slideWorkspaces(Hyprland.focusedWorkspace?.id ?? -1)

    FrameAnimation {
        running: root.wsSliding
        onTriggered: {
            const x = (Date.now() - root.wsStart) / 300;
            root.wsP = x >= 1 ? 1 : root.easeOutQuint(x);
        }
    }

    Timer {
        id: settle
        interval: 150
        running: true
        onTriggered: Hyprland.refreshToplevels()
    }

    FileView {
        path: root.cacheDir + "/state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.art = JSON.parse(text());
            } catch (e) {
                console.warn("ThunarQuasar: unreadable state.json:", e);
            }
        }
    }

    property AnimatedImage shownLoop: null
    property string recolorNext: ""

    function recolor(colors) {
        if (recolorer.running) {
            recolorNext = colors;
            return;
        }
        const frame = shownLoop?.playing ? shownLoop.currentFrame + 4 : 0;
        recolorer.command = ["python3", "-I", Quickshell.shellDir + "/quasar.py", "recolor", colors, cacheDir, String(frame)];
        recolorer.running = true;
    }

    IpcHandler {
        target: "quasar"

        function recolor(colors: string): void {
            root.recolor(colors);
        }

        function bloom(colors: string, x: int, y: int): void {
            root.bloomAt = Qt.point(x, y);
            root.recolor(colors);
        }
    }

    property point bloomAt: Qt.point(-1, -1)
    property string glassShown: ""
    property string glassNext: ""
    property real bloomR: 0

    function glassChanged() {
        const w = file(art.wall);
        if (!w || w === glassShown || w === glassNext)
            return;
        if (bloomAt.x < 0 || !glassShown) {
            glassShown = w;
            return;
        }
        const s = Quickshell.screens[0];
        bloomEnd = Math.max(...[[s.x, s.y], [s.x + s.width, s.y], [s.x, s.y + s.height], [s.x + s.width, s.y + s.height]].map(([cx, cy]) => Math.hypot(cx - bloomAt.x, cy - bloomAt.y)));
        glassNext = w;
        bloom.restart();
    }

    property real bloomEnd: 0

    onArtChanged: glassChanged()

    NumberAnimation {
        id: bloom
        target: root
        property: "bloomR"
        from: 0
        to: root.bloomEnd
        duration: 1200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.enterCurve
        onFinished: {
            root.glassShown = root.glassNext;
            root.glassNext = "";
            root.bloomAt = Qt.point(-1, -1);
        }
    }

    Connections {
        target: Theme
        function onPaletteChanged() {
            const p = Theme.palette;
            if (root.art.palette !== (p.primary ?? "") + (p.surface ?? ""))
                root.recolor(root.colorsJson);
        }
    }

    Process {
        id: recolorer
        onExited: {
            if (root.recolorNext) {
                const next = root.recolorNext;
                root.recolorNext = "";
                root.recolor(next);
            }
        }
    }

    Process {
        id: render

        function next() {
            if (!root.queued.length)
                return;
            command = ["nice", "-n", "19", "python3", "-I", Quickshell.shellDir + "/quasar.py", "render", root.colorsJson, root.cacheDir, String(root.queued[0])];
            running = true;
        }

        onExited: {
            root.queued = root.queued.slice(1);
            next();
        }
    }

    Process {
        id: thunarConf
        running: true
        command: ["sh", "-c", "xfconf-query -c thunar -p /last-separator-position; xfconf-query -c thunar -p /last-side-pane 2>/dev/null || echo ThunarShortcutsPane"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [w, pane] = text.trim().split("\n");
                root.sidebarW = parseInt(w) || 170;
                root.sidebarShown = pane === "ThunarShortcutsPane";
            }
        }
    }

    Process {
        id: devices
        running: true
        command: ["gio", "mount", "-l"]
        stdout: StdioCollector {
            onStreamFinished: root.volumes = text.split("\n").filter(l => /^ {0,2}Volume\(|^Mount\(/.test(l)).length
        }
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/gtk-3.0/bookmarks"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.bookmarks = text().split("\n").filter(l => l.trim()).length
        onLoadFailed: root.bookmarks = 0
    }

    component ShadowStrip: PanelWindow {
        id: strip

        required property var ipc
        required property bool right
        required property real slide
        required property real fade
        readonly property real sx: ipc.at[0] + slide - 2 + 7
        readonly property int sy: ipc.at[1] - 2 + 7
        readonly property int sw: ipc.size[0] + 4
        readonly property int sh: ipc.size[1] + 4
        readonly property real lx: right ? ipc.at[0] + slide + ipc.size[0] + 2 : sx
        readonly property int ly: right ? sy : ipc.at[1] + ipc.size[1] + 2

        anchors {
            bottom: true
            left: true
        }
        margins {
            left: strip.lx - strip.screen.x
            bottom: strip.screen.y + strip.screen.height - strip.ly - implicitHeight
        }
        implicitWidth: right ? 7 : sw
        implicitHeight: right ? sh : 7
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-quasar"
        mask: Region {}

        Rectangle {
            x: strip.sx - strip.lx
            y: strip.sy - strip.ly
            width: strip.sw
            height: strip.sh
            radius: 10
            color: Theme.tertiary
            opacity: strip.fade
        }
    }

    Variants {
        model: root.windows

        Scope {
            id: win

            required property var modelData
            readonly property var ipc: modelData.lastIpcObject
            readonly property var mon: modelData.monitor
            readonly property bool covered: Hyprland.toplevels.values.some(t => t !== win.modelData && t.lastIpcObject?.fullscreen && t.lastIpcObject.workspace?.id === win.ipc?.workspace?.id)
            readonly property int wsId: ipc?.workspace?.id ?? -1
            readonly property bool entering: root.wsSliding && wsId === root.wsTo
            readonly property bool sliding: entering || (root.wsSliding && wsId === root.wsFrom)
            readonly property real slide: sliding ? (mon?.width ?? 0) / (mon?.scale ?? 1) * 0.15 * root.wsDir * (entering ? 1 - root.wsP : -root.wsP) : 0
            readonly property real fade: sliding ? (entering ? root.wsP : 1 - root.wsP) : 1
            readonly property bool shown: !!ipc?.at && !covered && (sliding || (root.wsTo < 0 ? mon?.activeWorkspace?.id : root.wsTo) === wsId)

            ShadowStrip {
                ipc: win.ipc
                right: true
                slide: win.slide
                fade: win.fade
                visible: win.shown
            }

            ShadowStrip {
                ipc: win.ipc
                right: false
                slide: win.slide
                fade: win.fade
                visible: win.shown
            }

            PanelWindow {
                id: panel

                visible: win.shown
                anchors {
                    bottom: true
                    left: true
                }
                margins {
                    left: (win.ipc?.at[0] ?? 0) + win.slide - panel.screen.x
                    bottom: panel.screen.y + panel.screen.height - (win.ipc?.at[1] ?? 0) - (win.ipc?.size[1] ?? 0)
                }
                implicitWidth: win.ipc?.size[0] ?? 1
                implicitHeight: win.ipc?.size[1] ?? 1
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell-quasar"
                mask: Region {}

                Image {
                    x: panel.screen.x - (win.ipc?.at[0] ?? 0) - win.slide
                    y: panel.screen.y - (win.ipc?.at[1] ?? 0)
                    width: panel.screen.width
                    height: panel.screen.height
                    source: root.glassShown
                    smooth: true
                    opacity: win.fade
                }

                Repeater {
                    model: root.glassNext ? Math.ceil(panel.height / 8) : 0

                    Item {
                        id: strip

                        required property int index
                        readonly property real ox: (win.ipc?.at[0] ?? 0) + win.slide
                        readonly property real oy: win.ipc?.at[1] ?? 0
                        readonly property real dy: Math.max(Math.abs(oy + index * 8 + 4 - root.bloomAt.y) - 4, 0)
                        readonly property real half: root.bloomR > dy ? Math.sqrt(root.bloomR * root.bloomR - dy * dy) : -1
                        readonly property real x0: Math.max(0, root.bloomAt.x - half - ox)
                        readonly property real x1: Math.min(panel.width, root.bloomAt.x + half - ox)

                        visible: half >= 0 && x1 > x0
                        x: x0
                        y: index * 8
                        width: Math.max(0, x1 - x0)
                        height: 8
                        clip: true
                        opacity: win.fade

                        Image {
                            x: panel.screen.x - strip.ox - strip.x
                            y: panel.screen.y - strip.oy - strip.y
                            width: panel.screen.width
                            height: panel.screen.height
                            source: root.glassNext
                            smooth: true
                        }
                    }
                }

                Item {
                    visible: root.sidebarShown
                    opacity: win.fade
                    y: root.toolbarH
                    width: root.sidebarW
                    height: parent.height - root.toolbarH
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        color: root.art.surface ?? Theme.palette.surface ?? "#1a120d"
                        opacity: 0.9
                    }

                    Item {
                        id: space

                        y: root.listH
                        width: parent.width
                        height: Math.max(0, parent.height - root.listH)
                        clip: true

                        function check() {
                            if (panel.visible && height > 120)
                                root.request(height);
                        }

                        onHeightChanged: check()
                        Connections {
                            target: root
                            function onArtChanged() {
                                space.check();
                            }
                        }

                        Image {
                            x: Math.round((parent.width - implicitWidth) / 2)
                            y: Math.round(parent.height / 2 - implicitHeight / 2)
                            source: root.file(root.art.stamp ? `backdrop-${root.art.stamp}.png` : "")
                            cache: false
                            smooth: false
                        }

                        AnimatedImage {
                            id: loop

                            x: Math.round((parent.width - implicitWidth) / 2)
                            y: Math.round(parent.height / 2 - implicitHeight / 2)
                            source: root.loopFor(space.height)
                            cache: false
                            smooth: false
                            playing: panel.visible
                            Component.onCompleted: root.shownLoop = loop
                            onPlayingChanged: {
                                if (playing)
                                    root.shownLoop = loop;
                            }
                        }
                    }
                }
            }
        }
    }
}
