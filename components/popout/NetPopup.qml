import "../../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo

PopupWindow {
    id: netPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || parentMouseArea.containsMouse;
        } catch (e) {
        }
        return p;
    }

    function closePopup() {
        netPopupContent.width = 40;
        netPopupContent.height = 20;
        netPopupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        netPopupContent.width = 220;
        netPopupContent.height = 140;
        netPopupContent.opacity = 1;
    }

    // Function to format speed value into human-readable B/K/M formats
    function formatSpeed(speed) {
        if (speed <= 0)
            return "-";

        if (speed < 1) {
            var bytes = speed * 1024;
            if (bytes < 10)
                return "-";

            return Math.round(bytes) + "B";
        }
        if (speed < 1024)
            return speed.toFixed(1) + "K";

        return (speed / 1024).toFixed(1) + "M";
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            netOpenTimer.stop();
            netCloseTimer.stop();
            if (destroyTimer.running)
                netPopup.cancelClose();

        } else {
            netCloseTimer.start();
        }
    }
    anchor.window: barWindow
    // Align the popup's center to the Network widget's average position (completely static)
    anchor.rect.x: modulesContainer.x + 5
    anchor.rect.y: barWindow.height
    implicitWidth: 280
    implicitHeight: 140
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            netPopupLoader.active = false;

    }
    Component.onCompleted: {
        topNetProcessesProc.running = true;
    }

    Timer {
        id: destroyTimer

        interval: 800
        repeat: false
        onTriggered: netPopupLoader.active = false
    }

    ListModel {
        id: downloadModel
    }

    ListModel {
        id: uploadModel
    }

    QsIo.Process {
        id: topNetProcessesProc

        command: ["stdbuf", "-oL", "nethogs", "-t"]

        stdout: QsIo.SplitParser {
            property var tempProcesses: []

            onRead: (data) => {
                if (!data)
                    return ;

                var line = data.trim();
                if (line.indexOf("Refreshing:") === 0) {
                    if (tempProcesses.length > 0) {
                        var validProcesses = [];
                        for (var i = 0; i < tempProcesses.length; i++) {
                            var p = tempProcesses[i];
                            var nameLower = p.name.toLowerCase();
                            if (nameLower === "unknown" || nameLower === "nethogs" || nameLower === "sh" || nameLower === "bash")
                                continue;

                            validProcesses.push(p);
                        }
                        if (validProcesses.length > 0) {
                            // 1. Sort and extract top 2 downloads
                            var dlProcesses = validProcesses.slice();
                            dlProcesses.sort((a, b) => {
                                return b.rx - a.rx;
                            });
                            downloadModel.clear();
                            var dlCount = 0;
                            for (var j = 0; j < dlProcesses.length && dlCount < 2; j++) {
                                var dlItem = dlProcesses[j];
                                if (dlItem.rx > 0.01) {
                                    downloadModel.append({
                                        "name": dlItem.name,
                                        "rx": dlItem.rx
                                    });
                                    dlCount++;
                                }
                            }
                            // 2. Sort and extract top 2 uploads
                            var ulProcesses = validProcesses.slice();
                            ulProcesses.sort((a, b) => {
                                return b.tx - a.tx;
                            });
                            uploadModel.clear();
                            var ulCount = 0;
                            for (var k = 0; k < ulProcesses.length && ulCount < 2; k++) {
                                var ulItem = ulProcesses[k];
                                if (ulItem.tx > 0.01) {
                                    uploadModel.append({
                                        "name": ulItem.name,
                                        "tx": ulItem.tx
                                    });
                                    ulCount++;
                                }
                            }
                        }
                    }
                    tempProcesses = [];
                } else {
                    var parts = line.split(/\s+/);
                    if (parts.length >= 3) {
                        var progInfo = parts[0];
                        var tx = parseFloat(parts[1]) || 0;
                        var rx = parseFloat(parts[2]) || 0;
                        if (tx > 0 || rx > 0) {
                            var subParts = progInfo.split("/");
                            var progName = "unknown";
                            if (subParts.length >= 3)
                                progName = subParts[subParts.length - 3];
                            else if (subParts.length > 0)
                                progName = subParts[0];
                            tempProcesses.push({
                                "name": progName,
                                "tx": tx,
                                "rx": rx
                            });
                        }
                    }
                }
            }
        }

    }

    Item {
        anchors.fill: parent

        // Left Fillet (Inverted Border Corner)
        Shape {
            id: netLeftFillet

            width: 24
            height: 24
            anchors.right: netPopupContent.left
            anchors.top: netPopupContent.top
            opacity: netPopupContent.opacity
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

        }

        // Right Fillet (Inverted Border Corner)
        Shape {
            id: netRightFillet

            width: 24
            height: 24
            anchors.left: netPopupContent.right
            anchors.top: netPopupContent.top
            opacity: netPopupContent.opacity
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

        }

        Item {
            id: netPopupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            Rectangle {
                id: netPopupBg

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
                propagateComposedEvents: true
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    netPopupContent.width = 220;
                    netPopupContent.height = 140;
                    netPopupContent.opacity = 1;
                }
            }

            // Details & Split Layout
            Column {
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // --- DOWNLOADS SECTION ---
                Column {
                    width: parent.width
                    spacing: 4

                    // Placeholder if empty
                    Text {
                        text: "No active downloads"
                        color: Style.overlay1
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        visible: downloadModel.count === 0
                    }

                    Repeater {
                        model: downloadModel

                        delegate: Item {
                            width: parent.width
                            height: 16

                            Text {
                                id: dlIcon

                                text: "arrow_downward"
                                color: Style.green
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 10
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: model.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                anchors.left: dlIcon.right
                                anchors.leftMargin: 6
                                anchors.right: dlSpeedText.left
                                anchors.rightMargin: 6
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: dlSpeedText

                                text: netPopup.formatSpeed(model.rx)
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                    }

                }

                // --- HORIZONTAL SEPARATOR ---
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Style.surface1
                }

                // --- UPLOADS SECTION ---
                Column {
                    width: parent.width
                    spacing: 4

                    // Placeholder if empty
                    Text {
                        text: "Scanning"
                        color: Style.overlay1
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        visible: uploadModel.count === 0
                    }

                    Repeater {
                        model: uploadModel

                        delegate: Item {
                            width: parent.width
                            height: 16

                            Text {
                                id: ulIcon

                                text: "arrow_upward"
                                color: Style.peach
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 10
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: model.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                anchors.left: ulIcon.right
                                anchors.leftMargin: 6
                                anchors.right: ulSpeedText.left
                                anchors.rightMargin: 6
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: ulSpeedText

                                text: netPopup.formatSpeed(model.tx)
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                    }

                }

            }

            Behavior on width {
                NumberAnimation {
                    duration: Style.durationExpressiveSlowSpatial
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveSlowSpatialCurve
                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: Style.durationExpressiveSlowSpatial
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveSlowSpatialCurve
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.durationExpressiveSlowEffects
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveSlowEffectsCurve
                }

            }

        }

    }

}
