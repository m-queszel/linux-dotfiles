import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification: icon, app, title, body, X to close, and a countdown bar along the bottom
// that pauses while hovered. Critical notifications have no countdown and stay until closed.
Rectangle {
    id: card

    required property var notification
    property bool shown: true

    // The server destroys a notification just before its card is removed, so reads are null-safe
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    // Apps may request a timeout (expireTimeout is in ms); otherwise 3 s for low, 5 s for normal
    readonly property int timeoutMs: notification?.expireTimeout > 0 ? notification?.expireTimeout : notification?.urgency === NotificationUrgency.Low ? 3000 : 5000
    readonly property var defaultAction: notification?.actions.find(a => a.identifier === "default") ?? null

    // Slide in/out on the same spring as the bar pills. Closing animates out first and only then
    // tells the server, so the exit always plays (the server drops the card the moment it's closed).
    property real offset: 380
    property bool leaving: false
    property string closeWith: "dismiss"

    function leave(how) {
        if (leaving)
            return;
        closeWith = how;
        leaving = true;
        outAnim.start();
    }

    property bool entered: false
    Component.onCompleted: {
        offset = 0;
        entered = true;
    }
    x: offset
    opacity: entered && !leaving ? 1 : 0 // starts invisible: no flash at the final spot

    Behavior on offset {
        enabled: !card.leaving
        SpringAnimation {
            spring: 6
            damping: 0.38
            epsilon: 0.25
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 220
        }
    }

    NumberAnimation {
        id: outAnim
        target: card
        property: "offset"
        to: 400
        duration: 260
        easing.type: Easing.InCubic
        onFinished: card.closeWith === "expire" ? card.notification?.expire() : card.notification?.dismiss()
    }

    visible: shown
    height: shown ? content.implicitHeight + 28 : 0
    radius: Theme.radius
    color: Theme.pill
    border.width: 1
    border.color: critical ? Theme.error : Theme.outlineVariant
    clip: true

    HoverHandler {
        id: hover
    }

    // Clicking the card opens the app (if it offered that); the X only closes
    MouseArea {
        anchors.fill: parent
        enabled: card.defaultAction !== null
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            card.defaultAction.invoke();
            card.leave("dismiss");
        }
    }

    Row {
        id: content
        x: 14
        y: 14
        width: parent.width - 28 - 28 // room for the X button
        spacing: 12

        IconImage {
            id: icon
            readonly property string src: card.notification?.image || (card.notification?.appIcon ? Quickshell.iconPath(card.notification?.appIcon, true) : "")
            visible: src !== ""
            source: src
            implicitSize: 36
            asynchronous: true
        }

        Column {
            width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
            spacing: 3

            Text {
                width: parent.width
                text: card.notification?.appName ?? ""
                visible: text !== ""
                color: Theme.onSurfaceVariant
                font.family: Theme.font
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.notification?.summary ?? ""
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.notification?.body ?? ""
                visible: text !== ""
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }
    }

    // Close button
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 26
        height: 26
        radius: 13
        color: closeMouse.containsMouse ? Qt.alpha(Theme.onSurface, 0.12) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            anchors.centerIn: parent
            text: "\u{f0156}" // nf-md-close
            color: closeMouse.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant
            font.family: Theme.iconFont
            font.pixelSize: 14
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.leave("dismiss")
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Close notification"
    }

    // Countdown: shrinks to nothing, then the notification expires. Hovering pauses it.
    Rectangle {
        id: countdown
        visible: !card.critical
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Theme.radius
        height: 2
        radius: 1
        color: Theme.primary
        property real progress: 1
        width: (parent.width - 2 * Theme.radius) * progress

        NumberAnimation on progress {
            running: !card.critical
            paused: hover.hovered || !card.shown // hidden cards wait their turn instead of expiring unseen
            from: 1
            to: 0
            duration: card.timeoutMs
            onFinished: card.leave("expire")
        }
    }
}
