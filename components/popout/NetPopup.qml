import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo
import "../../components"

PopupWindow {
    id: netPopup

    anchor.window: barWindow
    // Align the popup's center to the Network widget's center (globally mapped)
    anchor.rect.x: modulesContainer.x + netWidget.x + (netWidget.width / 2) - 140
    anchor.rect.y: barWindow.height
    implicitWidth: 280
    implicitHeight: 160
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            netPopupLoader.active = false;
    }
    Component.onCompleted: {
        topNetProcessesProc.running = true;
    }

    ListModel {
        id: topNetProcessesModel
    }

    QsIo.Process {
        id: topNetProcessesProc

        command: ["nethogs", "-t"]

        stdout: QsIo.SplitParser {
            property var tempProcesses: []

            onRead: (data) => {
                if (!data)
                    return ;

                var line = data.trim();
                if (line.indexOf("Refreshing:") === 0) {
                    if (tempProcesses.length > 0) {
                        var totalTx = 0;
                        var totalRx = 0;
                        var validProcesses = [];
                        for (var i = 0; i < tempProcesses.length; i++) {
                            var p = tempProcesses[i];
                            var nameLower = p.name.toLowerCase();
                            if (nameLower === "unknown" || nameLower === "nethogs" || nameLower === "sh" || nameLower === "bash")
                                continue;

                            totalTx += p.tx;
                            totalRx += p.rx;
                            validProcesses.push(p);
                        }
                        if (validProcesses.length > 0) {
                            var uploadSorted = totalTx > totalRx;
                            if (uploadSorted)
                                validProcesses.sort((a, b) => {
                                    return b.tx - a.tx;
                                });
                            else
                                validProcesses.sort((a, b) => {
                                    return b.rx - a.rx;
                                });
                            topNetProcessesModel.clear();
                            for (var j = 0; j < validProcesses.length && j < 5; j++) {
                                var item = validProcesses[j];
                                topNetProcessesModel.append({
                                    "name": item.name,
                                    "tx": item.tx,
                                    "rx": item.rx,
                                    "isUploadSorted": uploadSorted
                                });
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
                            var fullPath = progInfo.split("/")[0];
                            var progName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
                            if (progName === "")
                                progName = fullPath;

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
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    netOpenTimer.stop();
                    netCloseTimer.stop();
                }
                onExited: netCloseTimer.start()
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    netPopupContent.width = 220;
                    netPopupContent.height = 160;
                    netPopupContent.opacity = 1;
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 10
                model: topNetProcessesModel
                spacing: 6
                clip: true

                delegate: Item {
                    width: ListView.view.width
                    height: 18

                    Text {
                        id: dirIcon

                        text: model.isUploadSorted ? "arrow_upward" : "arrow_downward"
                        color: model.isUploadSorted ? Style.peach : Style.green
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 11
                        width: 12
                        horizontalAlignment: Text.AlignHCenter
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: speedText

                        width: 45
                        horizontalAlignment: Text.AlignRight
                        text: {
                            var speed = model.isUploadSorted ? model.tx : model.rx;
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
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.left: dirIcon.right
                        anchors.leftMargin: 6
                        anchors.right: speedText.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
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
