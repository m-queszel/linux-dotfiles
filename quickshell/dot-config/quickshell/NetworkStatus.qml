import QtQuick
import Quickshell.Networking

// Connection status from NetworkManager: icon by device type, device name on hover.
RevealItem {
    readonly property var device: Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool wifi: device?.type === DeviceType.Wifi

    leader: !device ? "󰖪" : wifi ? "󰖩" : "󰈀"
    leaderColor: device ? Theme.onSurfaceVariant : Theme.error
    value: device ? device.name : "offline"
}
