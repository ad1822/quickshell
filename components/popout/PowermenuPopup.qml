import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"

PopupWindow {
    id: powermenuPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || parentMouseArea.containsMouse;
        } catch (e) {}
        return p;
    }

    function closePopup() {
        popupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        popupContent.opacity = 1;
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            closeTimer.stop();
            if (destroyTimer.running)
                powermenuPopup.cancelClose();
        } else {
            closeTimer.start();
        }
    }

    anchor.window: barWindow
    anchor.rect.x: barWindow.width / 2 - implicitWidth / 2
    anchor.rect.y: barWindow.height
    implicitWidth: 200
    implicitHeight: 70
    color: "transparent"
    visible: true

    onVisibleChanged: {
        if (!visible)
            powermenuPopupLoader.active = false;
    }

    Timer {
        id: destroyTimer
        interval: 150
        repeat: false
        onTriggered: powermenuPopupLoader.active = false
    }

    Timer {
        id: closeTimer
        interval: 1500
        repeat: false
        onTriggered: powermenuPopup.closePopup()
    }

    Component.onCompleted: {
        closeTimer.start();
    }

    Rectangle {
        id: popupContent
        anchors.fill: parent
        radius: 20
        color: Style.crust
        border.color: Style.surface1
        border.width: 1.5
        opacity: 1

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MouseArea {
            id: parentMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }

        Row {
            anchors.centerIn: parent
            spacing: 16

            // Logout
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: logoutMouse.containsMouse ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "logout"
                    color: logoutMouse.containsMouse ? Style.red : Style.lavender
                    Behavior on color { ColorAnimation { duration: 150 } }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        logoutProc.running = true;
                        powermenuPopup.closePopup();
                    }
                }
            }

            // Reboot
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: rebootMouse.containsMouse ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "restart_alt"
                    color: rebootMouse.containsMouse ? Style.red : Style.lavender
                    Behavior on color { ColorAnimation { duration: 150 } }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        rebootProc.running = true;
                        powermenuPopup.closePopup();
                    }
                }
            }

            // Shutdown
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: shutdownMouse.containsMouse ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "power_settings_new"
                    color: shutdownMouse.containsMouse ? Style.red : Style.lavender
                    Behavior on color { ColorAnimation { duration: 150 } }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        shutdownProc.running = true;
                        powermenuPopup.closePopup();
                    }
                }
            }
        }
    }

    Process {
        id: logoutProc
        command: ["sh", "-c", "hyprshutdown -t 'Loging Out... ' --post-cmd 'logout -P 0'"]
    }

    Process {
        id: rebootProc
        command: ["sh", "-c", "reboot"]
    }

    Process {
        id: shutdownProc
        command: ["sh", "-c", "hyprshutdown -t 'Shutting Down...' --post-cmd 'shutdown -P 0'"]
    }
}
