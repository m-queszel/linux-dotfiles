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
    property real reveal: open ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? Theme.enterMs : Theme.exitMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.open ? Theme.enterCurve : Theme.exitCurve
        }
    }

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
    visible: reveal > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dropdown"
    // OnDemand, not Exclusive: Hyprland sends every click to exclusive layers, which starves the click-away catcher
    WlrLayershell.keyboardFocus: interactive && open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Card {
        id: card

        attached: true
        // Slides out from under the bar; the window edge clips it
        y: -(height + Theme.shadowOffset) * (1 - root.reveal)
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
