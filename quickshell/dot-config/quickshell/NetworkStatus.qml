import QtQuick
import Quickshell.Networking

RevealItem {
    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool wifi: device?.type === DeviceType.Wifi

    leader: !device ? "󰖪" : wifi ? "󰖩" : "󰈀"
    leaderColor: device ? Theme.onSurfaceVariant : Theme.error
    value: device ? device.name : "offline"
}
