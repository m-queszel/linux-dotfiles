pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property real jitter: 0
    property real spread: 1

    function burst() {
        steps.restart();
    }

    SequentialAnimation {
        id: steps

        PropertyAction {
            target: root
            property: "jitter"
            value: -3
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 3
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: 2
        }
        PropertyAction {
            target: root
            property: "spread"
            value: -2.5
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: -1
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 4
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: 3
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 2
        }
        PauseAnimation {
            duration: 50
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: -1
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 1.5
        }
        PauseAnimation {
            duration: 60
        }
        PropertyAction {
            target: root
            property: "jitter"
            value: 0
        }
        PropertyAction {
            target: root
            property: "spread"
            value: 1
        }
    }
}
