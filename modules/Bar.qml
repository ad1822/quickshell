import "../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: barWindow

    property bool modulesExpanded: false
    property bool barExpanded: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    margins.top: barWindow.barExpanded ? 0 : 4
    color: "transparent"

    Rectangle {
        id: barBg

        anchors.centerIn: parent
        height: 30
        color: "#11111b"
        width: barWindow.barExpanded ? parent.width : (barClock.width + 10)
        radius: barWindow.barExpanded ? 0 : 6

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on radius {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

    }

    Clock {
        id: barClock

        anchors.centerIn: barBg
        height: barBg.height
        barExpanded: barWindow.barExpanded

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: barWindow.barExpanded = !barWindow.barExpanded
        }

    }

    Row {
        id: rightContainer

        anchors.right: parent.right
        anchors.rightMargin: barWindow.barExpanded ? 0 : -500
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 6
        layoutDirection: Qt.RightToLeft
        opacity: barWindow.barExpanded ? 1 : 0

        Battery {
            id: barBatteryWidget

            height: parent.height
        }

        WifiIcon {
            id: wifiIconWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    wifiCloseTimer.stop();
                    wifiOpenTimer.start();
                } else {
                    wifiOpenTimer.stop();
                    wifiCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Volume {
            id: barVolumeWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    qsCloseTimer.stop();
                    qsOpenTimer.start();
                } else {
                    qsOpenTimer.stop();
                    qsCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Brightness {
            id: barBrightnessWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    qsCloseTimer.stop();
                    qsOpenTimer.start();
                } else {
                    qsOpenTimer.stop();
                    qsCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        WallpaperButton {
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Player {
            id: playerWidget

            forceVisible: playerPopupLoader.active
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered && playerWidget.activePlayer !== null) {
                    playerCloseTimer.stop();
                    playerOpenTimer.start();
                } else {
                    playerOpenTimer.stop();
                    playerCloseTimer.start();
                }
            }
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    Workspaces {
        id: workspacesWidget

        anchors.left: parent.left
        anchors.leftMargin: barWindow.barExpanded ? 8 : -300
        anchors.verticalCenter: parent.verticalCenter
        opacity: barWindow.barExpanded ? 1 : 0

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    // --- Hamburger Button Card ---
    Rectangle {
        id: hamburgerButton

        anchors.left: workspacesWidget.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 6
        color: hamburgerMouse.containsMouse ? Style.surface0 : Style.base
        border.color: Style.surface1
        border.width: 0
        opacity: barWindow.barExpanded ? 1 : 0

        // Centered morphing vector lines
        Item {
            anchors.centerIn: parent
            width: 12
            height: 12

            // Top Line
            Rectangle {
                id: topLine

                width: 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: barWindow.modulesExpanded ? 6 : 3
                transformOrigin: Item.Center
                rotation: barWindow.modulesExpanded ? 45 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1
                    }

                }

            }

            // Middle Line
            Rectangle {
                id: middleLine

                width: barWindow.modulesExpanded ? 0 : 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: 6
                opacity: barWindow.modulesExpanded ? 0 : 1

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }

                }

            }

            // Bottom Line
            Rectangle {
                id: bottomLine

                width: 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: barWindow.modulesExpanded ? 6 : 9
                transformOrigin: Item.Center
                rotation: barWindow.modulesExpanded ? -45 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1
                    }

                }

            }

        }

        MouseArea {
            id: hamburgerMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: barWindow.modulesExpanded = !barWindow.modulesExpanded
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    // --- CPU Popup Timers & Loader ---
    Timer {
        id: openTimer

        interval: 300 // Mouse must stay 300ms to open
        repeat: false
        onTriggered: {
            closeTimer.stop();
            popupLoader.active = true;
        }
    }

    Timer {
        id: closeTimer

        interval: 200
        repeat: false
        onTriggered: popupLoader.active = false
    }

    // --- Memory Popup Timers ---
    Timer {
        id: memOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            memCloseTimer.stop();
            memPopupLoader.active = true;
        }
    }

    Timer {
        id: memCloseTimer

        interval: 200
        repeat: false
        onTriggered: memPopupLoader.active = false
    }

    // --- Network Popup Timers ---
    Timer {
        id: netOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            netCloseTimer.stop();
            netPopupLoader.active = true;
        }
    }

    Timer {
        id: netCloseTimer

        interval: 200
        repeat: false
        onTriggered: netPopupLoader.active = false
    }

    // --- Wifi Popup Timers & Loader ---
    Timer {
        id: wifiOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            wifiCloseTimer.stop();
            wifiPopupLoader.active = true;
        }
    }

    Timer {
        id: wifiCloseTimer

        interval: 200
        repeat: false
        onTriggered: wifiPopupLoader.active = false
    }

    Loader {
        id: wifiPopupLoader

        active: false
        source: "../components/popout/WifiPopup.qml"
    }



    // --- Player Popup Timers & Loader ---
    Timer {
        id: playerOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            playerCloseTimer.stop();
            if (playerPopupLoader.active && playerPopupLoader.item)
                playerPopupLoader.item.cancelClose();
            else
                playerPopupLoader.active = true;
        }
    }

    Timer {
        id: playerCloseTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (playerPopupLoader.item)
                playerPopupLoader.item.closePopup();
            else
                playerPopupLoader.active = false;
        }
    }

    Loader {
        id: playerPopupLoader

        active: false
        source: "../components/popout/PlayerPopup.qml"
    }

    // --- Quick Settings (Volume/Brightness) Popup Timers & Loader ---
    Timer {
        id: qsOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            qsCloseTimer.stop();
            if (qsPopupLoader.active && qsPopupLoader.item)
                qsPopupLoader.item.cancelClose();
            else
                qsPopupLoader.active = true;
        }
    }

    Timer {
        id: qsCloseTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (qsPopupLoader.item)
                qsPopupLoader.item.closePopup();
            else
                qsPopupLoader.active = false;
        }
    }

    Loader {
        id: qsPopupLoader

        active: false
        source: "../components/popout/QsPopup.qml"
    }

    // --- Smoothly Collapsible Modules Container ---
    Item {
        id: modulesContainer

        property int marginVal: barWindow.modulesExpanded ? 10 : 0

        anchors.left: hamburgerButton.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        clip: true
        anchors.leftMargin: marginVal
        width: barWindow.modulesExpanded ? (netWidget.x + netWidget.width) : 0
        opacity: (barWindow.barExpanded && barWindow.modulesExpanded) ? 1 : 0

        Process {
            id: cpuWidget

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    closeTimer.stop();
                    openTimer.start();
                } else {
                    openTimer.stop();
                    closeTimer.start();
                }
            }
        }

        Memory {
            id: memWidget

            anchors.left: cpuWidget.right
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    memCloseTimer.stop();
                    memOpenTimer.start();
                } else {
                    memOpenTimer.stop();
                    memCloseTimer.start();
                }
            }
        }

        Rectangle {
            id: memNetSeparator

            width: 1
            height: 12
            color: Style.surface1
            anchors.left: memWidget.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Network {
            id: netWidget

            anchors.left: memNetSeparator.right
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    netCloseTimer.stop();
                    netOpenTimer.start();
                } else {
                    netOpenTimer.stop();
                    netCloseTimer.start();
                }
            }
        }

        Behavior on marginVal {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }

        }

    }

    // --- CPU Popup Loader ---
    Loader {
        id: popupLoader

        active: false
        source: "../components/popout/CpuPopup.qml"
    }

    // --- Memory Popup Loader ---
    Loader {
        id: memPopupLoader

        active: false
        source: "../components/popout/MemPopup.qml"
    }

    // --- Network Popup Loader ---
    Loader {
        id: netPopupLoader

        active: false
        source: "../components/popout/NetPopup.qml"
    }

}
