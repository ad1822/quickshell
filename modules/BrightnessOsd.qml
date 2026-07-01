import "../components"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: osdWindow

    property int currentBrightness: 0

    function trigger(brightness) {
        if (Quickshell.screens && Hyprland.focusedMonitor) {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === Hyprland.focusedMonitor.name) {
                    osdWindow.screen = Quickshell.screens[i];
                    break;
                }
            }
        }
        currentBrightness = brightness;
        dismissTimer.stop();
        osdWindow.visible = true;
        card.active = true;
        hideTimer.restart();
    }

    anchors.bottom: true
    anchors.left: true
    implicitWidth: 180
    implicitHeight: 180
    color: "transparent"
    margins.left: screen ? (screen.width - implicitWidth) / 2 : 0
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    visible: false

    Timer {
        id: hideTimer

        interval: 1800
        repeat: false
        onTriggered: {
            card.active = false;
            dismissTimer.start();
        }
    }

    Timer {
        id: dismissTimer

        interval: 350
        repeat: false
        onTriggered: osdWindow.visible = false
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
        y: active ? 20 : 100
        opacity: active ? 1 : 0

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: {
                    if (osdWindow.currentBrightness <= 0)
                        return "brightness_low";

                    if (osdWindow.currentBrightness < 33)
                        return "brightness_low";

                    if (osdWindow.currentBrightness < 66)
                        return "brightness_medium";

                    return "brightness_high";
                }
                color: Style.yellow
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 130
                height: 4
                radius: 2
                color: Style.surface0
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * (osdWindow.currentBrightness / 100)
                    height: parent.height
                    radius: 2
                    color: Style.yellow

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
