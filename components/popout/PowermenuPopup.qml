import QtQuick
import Quickshell
import Quickshell.Io as QsIo
import Quickshell.Wayland
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
    anchor.rect.x: barWindow.width - implicitWidth - 10
    anchor.rect.y: barWindow.height
    implicitWidth: 200
    implicitHeight: 70
    color: "transparent"
    visible: true

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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
        focus: visible

        property int activeIndex: 0

        onVisibleChanged: {
            if (visible) {
                forceActiveFocus();
                activeIndex = 0;
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                // If keyboard tab navigates, reset/stop the auto-close timer so it doesn't close on the user
                closeTimer.stop();
                if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                    activeIndex = (activeIndex - 1 + 3) % 3;
                } else {
                    activeIndex = (activeIndex + 1) % 3;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                if (activeIndex === 0) {
                    logoutProc.running = true;
                } else if (activeIndex === 1) {
                    rebootProc.running = true;
                } else if (activeIndex === 2) {
                    shutdownProc.running = true;
                }
                powermenuPopup.closePopup();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                powermenuPopup.closePopup();
                event.accepted = true;
            }
        }

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
                color: (logoutMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 0)) ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "logout"
                    color: (logoutMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 0)) ? Style.red : Style.lavender
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
                color: (rebootMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 1)) ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "restart_alt"
                    color: (rebootMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 1)) ? Style.red : Style.lavender
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
                color: (shutdownMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 2)) ? Style.surface1 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: "power_settings_new"
                    color: (shutdownMouse.containsMouse || (popupContent.focus && popupContent.activeIndex === 2)) ? Style.red : Style.lavender
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

    QsIo.Process {
        id: logoutProc
        command: ["sh", "-c", "hyprshutdown -t 'Loging Out... ' --post-cmd 'logout -P 0'"]
    }

    QsIo.Process {
        id: rebootProc
        command: ["sh", "-c", "reboot"]
    }

    QsIo.Process {
        id: shutdownProc
        command: ["sh", "-c", "hyprshutdown -t 'Shutting Down...' --post-cmd 'shutdown -P 0'"]
    }
}
