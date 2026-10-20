import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool open: false
    property bool interactive: true
    property int cardWidth: 340
    property real left: 0
    property alias spacing: body.spacing
    default property alias content: body.data

    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.pillHeight
        left: root.left
    }
    implicitWidth: cardWidth + Theme.shadowOffset
    implicitHeight: card.height + Theme.shadowOffset
    color: "transparent"
    visible: open
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dropdown"
    WlrLayershell.keyboardFocus: interactive && open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Card {
        id: card

        attached: true
        width: root.cardWidth
        height: body.implicitHeight + 28
        focus: true
        Keys.onEscapePressed: root.open = false

        Column {
            id: body

            x: 14
            y: 14
            width: parent.width - 28
            spacing: 8
        }
    }
}
