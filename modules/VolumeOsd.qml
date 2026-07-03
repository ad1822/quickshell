import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: osdWindow

    property int currentVolume: 0
    property bool isMuted: false
    property bool isHeadphones: false

    function trigger(vol, muted, headphones) {
        if (Quickshell.screens && Hyprland.focusedMonitor) {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === Hyprland.focusedMonitor.name) {
                    osdWindow.screen = Quickshell.screens[i];
                    break;
                }
            }
        }
        currentVolume = vol;
        isMuted = muted;
        isHeadphones = headphones || false;
        dismissTimer.stop();
        osdWindow.visible = true; // Instantly map window on screen
        card.active = true; // Trigger slide-up animation
        hideTimer.restart();
    }

    anchors.bottom: true
    anchors.left: true
    implicitWidth: 180
    implicitHeight: 180
    color: "transparent"
    // Align horizontally in the center of the active monitor screen
    margins.left: screen ? (screen.width - implicitWidth) / 2 : 0
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    // Start completely invisible (unmapped by Wayland compositor, click-through)
    visible: false

    Timer {
        id: hideTimer

        interval: 1800 // Display for 1.8 seconds
        repeat: false
        onTriggered: {
            card.active = false; // Slide down
            dismissTimer.start(); // Wait for slide animation to finish before unmapping
        }
    }

    Timer {
        id: dismissTimer

        interval: 350 // Matches slide-down transition duration
        repeat: false
        onTriggered: {
            osdWindow.visible = false; // Unmap window (completely click-through again)
        }
    }

    Rectangle {
        id: card

        property bool active: false

        width: parent.width
        height: 38
        radius: 19
        color: Style.crust
        border.color: Style.surface1
        border.width: 1
        anchors.horizontalCenter: parent.horizontalCenter
        // Slide & fade positioning (floats 52px above screen edge)
        y: active ? 20 : 100
        opacity: active ? 1 : 0

        Row {
            // Percentage Label

            anchors.centerIn: parent
            spacing: 6

            // Volume Icon
            Text {
                text: {
                    if (osdWindow.isMuted || osdWindow.currentVolume <= 0)
                        return "volume_off";

                    if (osdWindow.isHeadphones)
                        return "headphones";

                    if (osdWindow.currentVolume < 33)
                        return "volume_down";

                    if (osdWindow.currentVolume < 66)
                        return "volume_down";

                    return "volume_up";
                }
                color: osdWindow.isMuted ? Style.red : Style.mauve
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                verticalAlignment: Text.AlignVCenter
            }

            // Progress Bar Track
            Rectangle {
                width: 130
                height: 4
                radius: 2
                color: Style.surface0
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: osdWindow.isMuted ? Style.overlay1 : Style.mauve
                    width: parent.width * (osdWindow.currentVolume / 100)

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutQuad
                        }

                    }

                }

            }

        }

        Behavior on y {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
                easing.overshoot: 0.8
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }

        }

    }

}
