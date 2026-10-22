import QtQuick
import Quickshell

RevealItem {
    leader: Qt.formatTime(clock.date, "h:mm AP")
    leaderIsIcon: false
    leaderBold: true
    leaderColor: Theme.onSurface
    value: Qt.formatDate(clock.date, "dddd d MMMM")
    revealLeft: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
