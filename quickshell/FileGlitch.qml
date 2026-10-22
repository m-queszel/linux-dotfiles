import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"
    readonly property var kinds: ({
            image: ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "ico"],
            audio: ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"],
            video: ["mp4", "mkv", "webm", "mov", "avi"],
            package: ["zip", "tar", "gz", "xz", "zst", "7z", "rar", "bz2", "deb", "rpm"],
            exec: ["sh", "bash", "zsh", "appimage", "run", "bin"],
            config: ["toml", "yaml", "yml", "ini", "conf", "cfg"],
            code: ["lua", "qml", "py", "js", "ts", "c", "h", "cpp", "rs", "go", "java", "json", "html", "css", "rasi"]
        })
    readonly property var effects: ({
            delete: ["clean", "rgb", "tear", "scan", "line", "pinch", "dot"],
            move: ["clean", "rgb", "half", "quarter", "dot"],
            rename: ["scan", "tear", "rgb", "clean", "clean", "clean", "line", "dot"]
        })

    readonly property string dir: {
        const t = ToplevelManager.activeToplevel;
        return t?.appId === "thunar" && t.title.startsWith("/") ? t.title : "";
    }

    property int knownTrash: -1
    property real trashedAt: 0
    property var names: null
    property var folders: new Set()
    property string namesDir: ""
    property var vanished: []

    property string label: ""
    property string kind: "text"
    property point at: Qt.point(0, 0)
    property var seq: []
    property int step: -1
    readonly property string fx: step >= 0 ? seq[step] ?? "" : ""
    property var tear: []

    function kindOf(name) {
        if (folders.has(name))
            return "folder";
        const dot = name.lastIndexOf(".");
        const ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
        return Object.keys(kinds).find(k => kinds[k].includes(ext)) ?? "text";
    }

    function play(effect, items) {
        label = items.length > 1 ? `${items.length} items` : items[0];
        kind = items.length > 1 ? (effect === "delete" ? "trash" : "folder") : kindOf(items[0]);
        tear = [0, 6, 11, 17].map((y, i) => ({
                    y: y,
                    h: [6, 5, 6, 5][i],
                    dx: Math.round((Math.random() * 2 - 1) * 7)
                }));
        seq = effects[effect];
        cursor.running = true;
    }

    function checkTrash() {
        if (trash.status !== FolderListModel.Ready)
            return;
        const added = trash.count - knownTrash;
        const first = knownTrash < 0;
        knownTrash = trash.count;
        if (first || added <= 0 || dir === "")
            return;
        trashedAt = Date.now();
        play("delete", added > 1 ? Array(added).fill("") : [trash.get(0, "fileName").replace(/\.trashinfo$/, "")]);
    }

    function checkDir() {
        if (here.status !== FolderListModel.Ready || dir === "")
            return;
        const now = new Set();
        const dirsNow = new Set();
        for (let i = 0; i < here.count; i++) {
            const name = here.get(i, "fileName");
            now.add(name);
            if (here.get(i, "fileIsDir"))
                dirsNow.add(name);
        }
        const before = namesDir === dir ? names : null;
        folders = before ? new Set([...folders, ...dirsNow]) : dirsNow;
        names = now;
        namesDir = dir;
        if (!before)
            return;
        const gone = [...before].filter(n => !now.has(n));
        const added = [...now].filter(n => !before.has(n));
        if (gone.length === 1 && added.length === 1)
            play("rename", added);
        else if (gone.length && !added.length) {
            vanished = gone;
            settle.restart();
        }
    }

    FolderListModel {
        id: trash
        folder: "file://" + root.dataHome + "/Trash/info"
        nameFilters: ["*.trashinfo"]
        showDirs: false
        sortField: FolderListModel.Time
        onStatusChanged: root.checkTrash()
        onCountChanged: root.checkTrash()
    }

    FolderListModel {
        id: here
        folder: root.dir ? "file://" + root.dir : ""
        showHidden: true
        sortField: FolderListModel.Unsorted
        onStatusChanged: root.checkDir()
        onCountChanged: root.checkDir()
    }

    Timer {
        id: settle
        interval: 250
        onTriggered: {
            if (Date.now() - root.trashedAt > 1000)
                root.play("move", root.vanished);
        }
    }

    Process {
        id: cursor
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = JSON.parse(text);
                root.at = Qt.point(p.x, p.y);
                root.step = 0;
                stepper.restart();
            }
        }
    }

    Timer {
        id: stepper
        interval: 33
        repeat: true
        onTriggered: {
            if (++root.step >= root.seq.length) {
                root.step = -1;
                stop();
            }
        }
    }

    LazyLoader {
        active: root.step >= 0

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => root.at.x >= s.x && root.at.x < s.x + s.width && root.at.y >= s.y && root.at.y < s.y + s.height) ?? Quickshell.screens[0]
            anchors {
                top: true
                left: true
            }
            margins {
                left: Math.round(root.at.x - screen.x - width / 2)
                top: Math.round(root.at.y - screen.y - height / 2)
            }
            implicitWidth: chip.width + 32
            implicitHeight: 40
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-glitch"
            mask: Region {}

            Rectangle {
                visible: root.fx === "rgb"
                x: chip.x - 3
                y: chip.y
                width: chip.width
                height: chip.height
                color: Theme.primary
            }

            Rectangle {
                visible: root.fx === "rgb"
                x: chip.x + 3
                y: chip.y
                width: chip.width
                height: chip.height
                color: Theme.tertiary
            }

            Item {
                id: chip

                visible: ["clean", "rgb", "tear", "scan", "half", "quarter"].includes(root.fx)
                x: Math.round((win.width - width) / 2)
                y: Math.round((win.height - height) / 2)
                width: text.implicitWidth + 36
                height: 22
                scale: root.fx === "half" ? 0.5 : root.fx === "quarter" ? 0.25 : 1

                Rectangle {
                    anchors.fill: parent
                    color: Theme.primaryContainer
                }

                Image {
                    x: 6
                    y: 3
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    source: `file://${root.dataHome}/icons/PixelInk/16x16/mimetypes/pixelink-${root.kind}.svg`
                    smooth: false
                    cache: false
                }

                Text {
                    id: text
                    x: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.label
                    color: Theme.primaryContainerText
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }

            Repeater {
                model: root.fx === "tear" ? root.tear : root.fx === "scan" ? Array.from({
                    length: 11
                }, (_, i) => ({
                            y: i * 2,
                            h: 1,
                            dx: i % 2 ? 2 : -2
                        })) : []

                ShaderEffectSource {
                    required property var modelData

                    sourceItem: chip
                    hideSource: true
                    sourceRect: Qt.rect(0, modelData.y, chip.width, modelData.h)
                    x: chip.x + modelData.dx
                    y: chip.y + modelData.y
                    width: chip.width
                    height: modelData.h
                }
            }

            Rectangle {
                visible: root.fx === "tear"
                x: chip.x + (root.tear[0]?.dx ?? 0) * 2
                y: chip.y + 9
                width: Math.round(chip.width * 0.4)
                height: 2
                color: Theme.tertiary
            }

            Rectangle {
                visible: ["line", "pinch", "dot"].includes(root.fx)
                anchors.centerIn: parent
                width: ({
                        line: chip.width + 8,
                        pinch: Math.round(chip.width * 0.25),
                        dot: 3
                    })[root.fx] ?? 0
                height: root.fx === "dot" ? 3 : 2
                color: Theme.onSurface

                Rectangle {
                    visible: root.fx === "line"
                    anchors.top: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.primary
                }
            }
        }
    }
}
