import QtQuick
import Quickshell.Io

RevealItem {
    id: root

    property bool active: false
    property int cpu: 0
    property real memGiB: 0
    property var lastCpu: null

    leader: "󰍛"
    value: `cpu ${cpu}%  ·  mem ${memGiB.toFixed(1)}G`

    Timer {
        interval: 5000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu[1];
                root.cpu = dt > 0 ? Math.round(100 * (1 - (idle - root.lastCpu[0]) / dt)) : 0;
            }
            root.lastCpu = [idle, total];
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => Number(text().match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))[1]);
            root.memGiB = (kb("MemTotal") - kb("MemAvailable")) / 1048576;
        }
    }
}
