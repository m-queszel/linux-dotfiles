import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false

    Component.onCompleted: {
        shown = true;
        Glitch.burst();
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData

            PanelWindow {
                id: panel

                screen: screenScope.modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: strip.height + Theme.shadowOffset
                color: "transparent"
                exclusiveZone: strip.height
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                mask: Region {
                    item: strip
                }

                Item {
                    id: strip

                    width: panel.width
                    height: Theme.pillHeight + Theme.borderWidth
                    y: root.shown ? 0 : -height - Theme.shadowOffset

                    Behavior on y {
                        NumberAnimation {
                            duration: Theme.enterMs
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.enterCurve
                        }
                    }

                    Rectangle {
                        y: parent.height
                        width: parent.width
                        height: Theme.shadowOffset
                        color: Theme.tertiary
                    }

                    Rectangle {
                        y: Theme.pillHeight
                        width: parent.width
                        height: Theme.borderWidth
                        color: Theme.primary
                    }

                    Rectangle {
                        width: parent.width
                        height: Theme.pillHeight
                        color: Theme.pill

                        Behavior on color {
                            enabled: !Theme.swapping
                            ColorAnimation {
                                duration: 400
                            }
                        }
                    }

                    Row {
                        x: Theme.gapsOut + Glitch.jitter
                        height: Theme.pillHeight

                        Workspaces {}
                    }

                    Visualizer {
                        x: (strip.width - width) / 2
                        popup: media
                    }

                    Row {
                        x: strip.width - width - Theme.gapsOut + Glitch.jitter
                        height: Theme.pillHeight
                        spacing: 16

                        Volume {
                            onClicked: sound.open = !sound.open
                        }
                        NetworkStatus {
                            onClicked: sound.open = !sound.open
                        }
                        SystemStats {
                            active: root.shown
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 18
                            color: Qt.alpha(Theme.outlineVariant, 0.7)
                        }
                        Clock {}
                    }
                }
            }

            PanelWindow {
                screen: screenScope.modelData
                visible: media.open || sound.open

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-catcher"

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        media.open = false;
                        sound.open = false;
                    }
                }
            }

            MediaPopup {
                id: media
                screen: screenScope.modelData
            }

            SoundPopup {
                id: sound
                screen: screenScope.modelData
            }

            VolumeOsd {
                screen: screenScope.modelData
                suppressed: sound.open
            }

            ScreenCorners {
                screen: screenScope.modelData
            }

            DesktopCards {
                screen: screenScope.modelData
            }
        }
    }
}
