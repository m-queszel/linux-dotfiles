import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Card {
    id: card

    required property var notification
    property bool shown: true

    // The server destroys a notification just before its card is removed, so reads are null-safe
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property int timeoutMs: notification?.expireTimeout > 0 ? notification?.expireTimeout : notification?.urgency === NotificationUrgency.Low ? 3000 : 5000
    readonly property var defaultAction: notification?.actions.find(a => a.identifier === "default") ?? null

    // Animate out before telling the server: it drops the card the moment it's closed
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
    opacity: entered && !leaving ? 1 : 0

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
    edge: critical ? Theme.error : Theme.primary

    HoverHandler {
        id: hover
    }

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
        width: parent.width - 28 - 28
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
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
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

    Key {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        size: 22
        icon: "\u{f0156}"
        label: "Close notification"
        onClicked: card.leave("dismiss")
    }

    Rectangle {
        id: countdown
        visible: !card.critical
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: card.border.width
        height: 3
        color: Theme.primary
        property real progress: 1
        width: (parent.width - 2 * card.border.width) * progress

        NumberAnimation on progress {
            running: !card.critical
            paused: hover.hovered || !card.shown
            from: 1
            to: 0
            duration: card.timeoutMs
            onFinished: card.leave("expire")
        }
    }
}
