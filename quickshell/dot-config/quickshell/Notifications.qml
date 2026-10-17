import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

// Notification server + popups (replaces mako). Cards stack top-right, newest on top, at most
// three visible; each shows a countdown bar that pauses on hover, and closes with its X button.
Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false // plain text: no app can inject styling or links into cards
        onNotification: n => n.tracked = true
    }

    PanelWindow {
        id: panel

        // From the server, not list.count: a ListView in a hidden window never fills, so it'd stay 0
        visible: server.trackedNotifications.values.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.gapsOut
            right: Theme.gapsOut
        }
        implicitWidth: 360 + 16 // + room on the left for the entry spring's overshoot
        implicitHeight: Math.max(1, list.contentHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        // Only the cards take clicks
        mask: Region {
            item: list
        }

        ListView {
            id: list
            x: 16
            width: 360
            height: contentHeight
            interactive: false
            spacing: Theme.gapsIn
            verticalLayoutDirection: ListView.BottomToTop // newest (last) on top
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                required property int index
                notification: modelData
                width: list.width
                shown: index >= list.count - 3
            }

            // Cards animate their own entry/exit (NotificationCard); the rest of the stack glides
            // into place on the bar's spring
            displaced: Transition {
                SpringAnimation {
                    property: "y"
                    spring: 6
                    damping: 0.38
                    epsilon: 0.25
                }
            }
        }
    }
}
