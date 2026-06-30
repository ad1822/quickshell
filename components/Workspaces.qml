import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland
import "../components"

Rectangle {
    id: root

    width: row.width + 20
    height: row.height + 20
    color: Style.mantle
    radius: 6

    Item {
        id: container

        anchors.centerIn: parent
        width: row.width
        height: row.height

        property int activeIndex: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id - 1) : 0

        // 1. The Active Sliding Indicator
        Rectangle {
            id: activeIndicator

            height: 6
            radius: 3
            color: Style.blue
            anchors.verticalCenter: parent.verticalCenter

            // Bindings to match the active dot wrapper's position and width dynamically
            x: {
                var activeChild = repeater.itemAt(container.activeIndex);
                return activeChild ? activeChild.x : 0;
            }
            width: {
                var activeChild = repeater.itemAt(container.activeIndex);
                return activeChild ? activeChild.width : 40;
            }

            // Spring slide animation
            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.4
                }
            }

            // Smooth scale/stretch animation
            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutQuad
                }
            }
        }

        // 2. The Workspace Dots Row
        Row {
            id: row

            spacing: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 12

            Repeater {
                id: repeater
                model: 4

                Item {
                    id: dotWrapper

                    // Wrapper width changes based on state to push siblings
                    width: isActive ? 40 : (hasWindows ? 10 : 6)
                    height: 12

                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    property bool hasWindows: ws !== undefined

                    // Smooth layout adjustment when width changes
                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuad
                        }
                    }

                    // Dot Rectangle
                    Rectangle {
                        id: dotItem

                        anchors.centerIn: parent
                        height: 6
                        width: isActive ? 24 : (hasWindows ? 10 : 6)
                        radius: 3

                        color: {
                            if (isActive) return "transparent"; // Let activeIndicator show through
                            if (hasWindows) return Style.text;
                            return Style.overlay0;
                        }

                        opacity: dotMouse.containsMouse ? 1.0 : (isActive ? 1.0 : (hasWindows ? 0.8 : 0.4))

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }

                        Behavior on width {
                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                        }
                    }

                    // Hover number text overlay
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: isActive ? Style.base : Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        opacity: dotMouse.containsMouse ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        id: dotMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })")
                    }
                }
            }
        }
    }
}
