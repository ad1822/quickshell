import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../components"

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

    function closePopup() {
        playerPopupContent.width = 40;
        playerPopupContent.height = 20;
        playerPopupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        playerPopupContent.width = 400;
        playerPopupContent.height = 120;
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

    // Function to sanitize local and remote art URLs
    function sanitizeArtUrl(url) {
        if (!url)
            return "";

        url = url.trim();
        if (url === "")
            return "";

        // If it starts with file:// but has only 2 slashes after colon (file://home/...), fix to file:///
        if (url.indexOf("file://") === 0 && url.indexOf("file:///") !== 0)
            return "file:///" + url.substring(7);

        // If it's already a URL (http, https, file), return it
        if (url.indexOf("http://") === 0 || url.indexOf("https://") === 0 || url.indexOf("file://") === 0)
            return url;

        // If it starts with /, it's a local absolute path, so prepend file://
        if (url.indexOf("/") === 0)
            return "file://" + url;

        return url;
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
    // Center the popup in the middle of the screen
    anchor.rect.x: (barWindow.width / 2) - 225
    anchor.rect.y: barWindow.height
    implicitWidth: 450
    implicitHeight: 120
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            playerPopupLoader.active = false;
    }

    // Timer to defer loader destruction until close animation ends
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
                strokeColor: Style.surface1
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
                strokeColor: Style.surface1
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

            // Left border mask (erases the vertical border in the fillet zone)
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 2
                height: 24
                color: Style.crust
            }

            // Right border mask (erases the vertical border in the fillet zone)
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
                    playerPopupContent.width = 400;
                    playerPopupContent.height = 120;
                    playerPopupContent.opacity = 1;
                }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16

                // Left Side: Album Art / Image Thumbnail
                Rectangle {
                    width: 96
                    height: 96
                    radius: 8
                    color: Style.surface0
                    border.color: Style.surface1
                    border.width: 0
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: albumArtImage

                        anchors.fill: parent
                        source: playerPopup.sanitizeArtUrl(playerWidget.localArtUrl)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: albumArtImage.status === Image.Ready
                    }

                    // Placeholder when no album art is loaded
                    Text {
                        text: "music_note"
                        color: Style.subtext1
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 32
                        anchors.centerIn: parent
                        visible: albumArtImage.status !== Image.Ready
                    }
                }

                // Right Side: Details, Progress, and Controls
                Column {
                    width: parent.width - 96 - 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Row 1: Track details (Title & Artist)
                    Column {
                        width: parent.width
                        spacing: 2

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

                    // Row 2: Progress Bar
                    Column {
                        width: parent.width
                        spacing: 4

                        // Progress Line
                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Style.surface1

                            Rectangle {
                                height: parent.height
                                radius: 2
                                color: Style.maroon
                                width: Math.min(parent.width * (playerWidget.length > 0 ? (playerWidget.position / playerWidget.length) : 0), parent.width)
                            }

                            MouseArea {
                                id: progressMouse

                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }

                        // Time Label
                        Text {
                            text: playerPopup.formatTime(playerWidget.position) + " / " + playerPopup.formatTime(playerWidget.length)
                            color: Style.subtext0
                            font.family: Style.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    // Row 3: Control Buttons Wrapper (Item centerer)
                    Item {
                        width: parent.width
                        height: 32

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 20

                            // Previous Button
                            Item {
                                width: 32
                                height: 32

                                Text {
                                    text: "skip_previous"
                                    color: prevMouse.containsMouse ? Style.mauve : Style.text
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: prevMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: playerWidget.prevTrack()
                                }
                            }

                            // Play/Pause Button
                            Item {
                                width: 32
                                height: 32

                                Text {
                                    text: playerWidget.isPlaying ? "pause" : "play_arrow"
                                    color: playMouse.containsMouse ? Style.mauve : (playerWidget.isPlaying ? Style.green : Style.text)
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: playMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: playerWidget.togglePlay()
                                }
                            }

                            // Next Button
                            Item {
                                width: 32
                                height: 32

                                Text {
                                    text: "skip_next"
                                    color: nextMouse.containsMouse ? Style.mauve : Style.text
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    anchors.centerIn: parent
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
