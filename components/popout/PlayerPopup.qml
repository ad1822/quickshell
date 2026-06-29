import "../../components"
import QtQuick
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
    anchor.rect.y: barWindow.height
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
        Shape {
            id: playerLeftFillet

            width: 24
            height: 24
            anchors.right: playerPopupContent.left
            anchors.top: playerPopupContent.top
            opacity: playerPopupContent.opacity
            visible: opacity > 0.01
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Style.crust
                strokeColor: "transparent"
                startX: 0
                startY: 0

                PathLine {
                    x: 24
                    y: 0
                }

                PathLine {
                    x: 24
                    y: 24
                }

                PathArc {
                    x: 0
                    y: 0
                    radiusX: 24
                    radiusY: 24
                    direction: PathArc.Counterclockwise
                }

            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Style.crust
                strokeWidth: 0
                startX: 24
                startY: 24

                PathArc {
                    x: 0
                    y: 0
                    radiusX: 24
                    radiusY: 24
                    direction: PathArc.Counterclockwise
                }

            }

        }

        // Right Fillet (Inverted Border Corner)
        Shape {
            id: playerRightFillet

            width: 24
            height: 24
            anchors.left: playerPopupContent.right
            anchors.top: playerPopupContent.top
            opacity: playerPopupContent.opacity
            visible: opacity > 0.01
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Style.crust
                strokeColor: "transparent"
                startX: 24
                startY: 0

                PathLine {
                    x: 0
                    y: 0
                }

                PathLine {
                    x: 0
                    y: 24
                }

                PathArc {
                    x: 24
                    y: 0
                    radiusX: 24
                    radiusY: 24
                    direction: PathArc.Clockwise
                }

            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Style.crust
                strokeWidth: 0
                startX: 0
                startY: 24

                PathArc {
                    x: 24
                    y: 0
                    radiusX: 24
                    radiusY: 24
                    direction: PathArc.Clockwise
                }

            }

        }

        Item {
            id: playerPopupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            // Base Card background
            Rectangle {
                id: playerPopupBg

                anchors.top: parent.top
                anchors.topMargin: -24
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: 24
                color: Style.crust
                border.color: Style.surface1
                border.width: 0
            }

            // Left border mask
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 2
                height: 24
                color: Style.crust
            }

            // Right border mask
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 2
                height: 24
                color: Style.crust
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

                // Title & Artist Row
                Column {
                    width: parent.width
                    spacing: 1

                    Text {
                        text: playerWidget.title
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 13
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

                // Progress Bar & Stamps Row
                Row {
                    width: parent.width
                    spacing: 12

                    Item {
                        width: parent.width - timeText.implicitWidth - 12
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

                    // Time stamps
                    Text {
                        id: timeText

                        // text: playerPopup.formatTime(playerWidget.position) + " / " + playerPopup.formatTime(playerWidget.length)
                        color: Style.subtext0
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                // Playback Buttons Row (Aligned Right)
                Item {
                    width: parent.width
                    height: 28

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // Skip Back
                        Item {
                            width: 24
                            height: 24

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

                        // Circular highlighted Play/Pause
                        Rectangle {
                            id: playBtnCard

                            width: 24
                            height: 24
                            radius: 12
                            color: playMouse.containsMouse ? Style.pink : Style.mauve
                            scale: playMouse.containsMouse ? 1.1 : 1

                            Text {
                                text: playerWidget.isPlaying ? "pause" : "play_arrow"
                                color: Style.base
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: playMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: playerWidget.togglePlay()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }

                            }

                        }

                        // Skip Forward
                        Item {
                            width: 24
                            height: 24

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
