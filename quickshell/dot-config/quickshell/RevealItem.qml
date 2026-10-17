import QtQuick

// A leader (icon or text) whose value slides out next to it on hover.
Item {
    id: root

    property string leader
    property bool leaderIsIcon: true
    property bool leaderBold: false
    property string value
    property bool revealLeft: false // value slides out to the left of the leader
    property color leaderColor: hover.hovered && leaderIsIcon ? Theme.primary : Theme.onSurfaceVariant

    signal clicked
    signal scrolled(int steps) // positive = up

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.pillHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: root.revealLeft ? Qt.RightToLeft : Qt.LeftToRight

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.leader
            color: root.leaderColor
            font.family: root.leaderIsIcon ? Theme.iconFont : Theme.font
            font.pixelSize: root.leaderIsIcon ? Theme.iconSize : Theme.fontSize
            font.weight: root.leaderBold ? Font.Bold : Font.Normal

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        // Clipped slot whose width animates from 0, so the value slides out instead of popping.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            height: label.implicitHeight
            width: hover.hovered ? label.implicitWidth + 8 : 0

            Behavior on width {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                x: root.revealLeft ? 0 : 8
                text: root.value
                color: Theme.onSurface
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                opacity: hover.hovered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
