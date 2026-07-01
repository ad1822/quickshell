import "../../components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell

PopupWindow {
    id: playerPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || parentMouseArea.containsMouse;
        } catch (e) {
        }
        try {
            p = p || prevMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || playMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || nextMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || progressMouse.containsMouse;
        } catch (e) {
        }
        return p;
    }

    // Wrapped collapsed size
    function closePopup() {
        playerPopupContent.width = 40;
        playerPopupContent.height = 20;
        playerPopupContent.opacity = 0;
        destroyTimer.start();
    }

    // Expanded opened size (Centered compact 300x100)
    function cancelClose() {
        destroyTimer.stop();
        playerPopupContent.width = 300;
        playerPopupContent.height = 115;
        playerPopupContent.opacity = 1;
    }

    // Function to format seconds into MM:SS format
    function formatTime(secs) {
        if (isNaN(secs) || secs <= 0)
            return "0:00";

        var m = Math.floor(secs / 60);
        var s = Math.floor(secs % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            playerOpenTimer.stop();
            playerCloseTimer.stop();
            if (destroyTimer.running)
                playerPopup.cancelClose();

        } else {
            playerCloseTimer.start();
        }
    }
    anchor.window: barWindow
    // Center the 300px popup in the middle of the screen
    anchor.rect.x: (barWindow.width / 2) - 150
    anchor.rect.y: barWindow.height + 2
    implicitWidth: 350
    implicitHeight: 115
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            playerPopupLoader.active = false;

    }

    Timer {
        id: destroyTimer

        interval: 300
        repeat: false
        onTriggered: playerPopupLoader.active = false
    }

    Item {
        anchors.fill: parent

        // Left Fillet (Inverted Border Corner)
        Item {
            id: playerPopupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            // Masked background container to shape blurred artwork and crust base
            Item {
                id: backgroundContainer

                anchors.fill: parent
                layer.enabled: true

                // Base crust color
                Rectangle {
                    anchors.fill: parent
                    color: Style.crust
                }

                // Blurred Album Art Background
                Image {
                    id: bgArtImage

                    anchors.fill: parent
                    source: (playerWidget.localArtUrl !== "") ? playerWidget.localArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    asynchronous: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: bgArtImage
                    blurEnabled: true
                    blur: 0.6
                    opacity: 0.8
                    visible: playerWidget.localArtUrl !== ""
                }

                // Dark overlay to ensure text contrast
                Rectangle {
                    anchors.fill: parent
                    color: "#aa0c0c0f"
                    visible: playerWidget.localArtUrl !== ""
                }

                layer.effect: OpacityMask {

                    maskSource: Rectangle {
                        width: backgroundContainer.width
                        height: backgroundContainer.height + 24
                        y: -24
                        radius: 24
                    }

                }

            }

            MouseArea {
                id: parentMouseArea

                anchors.fill: parent
                hoverEnabled: true
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    playerPopupContent.width = 300;
                    playerPopupContent.height = 115;
                    playerPopupContent.opacity = 1;
                }
            }

            // Details & Controls Layout
            Column {
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                // Top / Middle Row: Title, Artist and Play/Pause Button
                Row {
                    width: parent.width
                    height: 52

                    // Song Info Column
                    Column {
                        width: parent.width - 44
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        // Speaker / Player Label
                        Row {
                            spacing: 4

                            Text {
                                text: "volume_up"
                                color: Style.subtext1
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: playerWidget.playerName !== "" ? playerWidget.playerName : "Media Player"
                                color: Style.subtext1
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: 180
                            }

                        }

                        Text {
                            text: playerWidget.title
                            color: Style.text
                            font.family: Style.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: playerWidget.artist
                            color: Style.subtext0
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            width: parent.width
                            elide: Text.ElideRight
                            visible: playerWidget.artist !== ""
                        }

                    }

                    // Play Button Circle on Right
                    Item {
                        width: 44
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: playBtnCard

                            width: 36
                            height: 36
                            radius: 18
                            color: playMouse.containsMouse ? "#f5e0dc" : "#ffffff"
                            scale: playMouse.containsMouse ? 1.08 : 1
                            anchors.centerIn: parent

                            Text {
                                text: playerWidget.isPlaying ? "pause" : "play_arrow"
                                color: "#11111b"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: playMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: playerWidget.togglePlay()
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                    }

                }

                // Bottom Row: Controls & Progress Bar
                Row {
                    width: parent.width
                    height: 24
                    spacing: 8

                    // Skip Back
                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "skip_previous"
                            color: prevMouse.containsMouse ? Style.mauve : Style.text
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                            scale: prevMouse.containsMouse ? 1.1 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }

                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        MouseArea {
                            id: prevMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playerWidget.prevTrack()
                        }

                    }

                    // Progress Track Bar
                    Item {
                        width: parent.width - 64
                        height: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: progressTrack

                            width: parent.width
                            height: 4
                            radius: 2
                            color: Style.surface1
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: progressFill

                                height: parent.height
                                radius: 2
                                color: Style.mauve
                                width: Math.min(parent.width * (playerWidget.length > 0 ? (playerWidget.position / playerWidget.length) : 0), parent.width)
                            }

                        }

                        MouseArea {
                            id: progressMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (playerWidget.length > 0) {
                                    var clickPct = mouse.x / width;
                                    var targetSecs = Math.round(clickPct * playerWidget.length);
                                    Quickshell.execDetached(["playerctl", "position", targetSecs.toString()]);
                                }
                            }
                        }

                    }

                    // Skip Forward
                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "skip_next"
                            color: nextMouse.containsMouse ? Style.mauve : Style.text
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                            scale: nextMouse.containsMouse ? 1.1 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }

                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        MouseArea {
                            id: nextMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playerWidget.nextTrack()
                        }

                    }

                }

            }

            Behavior on width {
                NumberAnimation {
                    duration: Style.durationExpressiveDefaultSpatial
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: Style.durationExpressiveDefaultSpatial
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationExpressiveDefaultEffects
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                }

            }

        }

    }

}
