import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => n.tracked = true
    }

    PanelWindow {
        id: panel

        visible: server.trackedNotifications.values.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.gapsOut
            right: Theme.gapsOut
        }
        implicitWidth: 360 + 16 + Theme.shadowOffset
        implicitHeight: Math.max(1, list.contentHeight + Theme.shadowOffset)
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        mask: Region {
            item: list
        }

        ListView {
            id: list
            x: 16
            width: 360
            height: contentHeight
            interactive: false
            spacing: Theme.gapsIn + Theme.shadowOffset
            verticalLayoutDirection: ListView.BottomToTop
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                required property int index
                notification: modelData
                width: list.width
                shown: index >= list.count - 3
            }

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
