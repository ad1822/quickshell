import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo
import "../../components"

PopupWindow {
    id: wifiPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || wifiParentMouseArea.containsMouse;
        } catch (e) {
        }
        try {
            p = p || wifiPopup.isAnyItemHovered;
        } catch (e) {
        }
        try {
            p = p || scanMouse.containsMouse;
        } catch (e) {
        }
        return p;
    }
    property bool isAnyItemHovered: false

    function refreshWifi() {
        wifiListModel.clear();
        wifiScanProc.running = true;
    }

    anchor.window: barWindow
    // Align the popup's center to the WifiIcon widget's center (globally mapped)
    anchor.rect.x: rightContainer.x + wifiIconWidget.x + (wifiIconWidget.width / 2) - 164
    anchor.rect.y: barWindow.height
    implicitWidth: 328
    implicitHeight: 280
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            wifiPopupLoader.active = false;
    }
    function closePopup() {
        wifiPopupContent.width = 40;
        wifiPopupContent.height = 20;
        wifiPopupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        wifiPopupContent.width = 280;
        wifiPopupContent.height = 280;
        wifiPopupContent.opacity = 1;
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            wifiOpenTimer.stop();
            wifiCloseTimer.stop();
            if (destroyTimer.running)
                wifiPopup.cancelClose();
        } else {
            wifiCloseTimer.start();
        }
    }

    Timer {
        id: destroyTimer

        interval: 800
        repeat: false
        onTriggered: wifiPopupLoader.active = false
    }

    ListModel {
        id: wifiListModel
    }

    QsIo.Process {
        id: wifiScanProc

        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        running: false

        stdout: QsIo.StdioCollector {
            onStreamFinished: {
                wifiListModel.clear();
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    var parts = line.split(":");
                    if (parts.length >= 3) {
                        var active = parts[0] === "yes";
                        var ssid = parts[1];
                        if (ssid === "")
                            continue;

                        var signal = parseInt(parts[2]) || 0;
                        var security = parts[3] || "";
                        var found = false;
                        for (var j = 0; j < wifiListModel.count; j++) {
                            if (wifiListModel.get(j).ssid === ssid) {
                                found = true;
                                wifiListModel.set(j, {
                                    "active": active || wifiListModel.get(j).active,
                                    "ssid": ssid,
                                    "signal": Math.max(signal, wifiListModel.get(j).signal),
                                    "security": security
                                });
                                break;
                            }
                        }
                        if (!found) {
                            wifiListModel.append({
                                "active": active,
                                "ssid": ssid,
                                "signal": signal,
                                "security": security
                            });
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: wifiScanTimer

        interval: 10000
        running: wifiPopup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiPopup.refreshWifi()
    }

    Timer {
        id: refreshTimer

        interval: 1500
        running: false
        repeat: false
        onTriggered: wifiPopup.refreshWifi()
    }

    Item {
        anchors.fill: parent

        // Left Fillet
        Shape {
            id: wifiLeftFillet

            width: 24
            height: 24
            anchors.right: wifiPopupContent.left
            anchors.top: wifiPopupContent.top
            opacity: wifiPopupContent.opacity
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

        // Right Fillet
        Shape {
            id: wifiRightFillet

            width: 24
            height: 24
            anchors.left: wifiPopupContent.right
            anchors.top: wifiPopupContent.top
            opacity: wifiPopupContent.opacity
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
            id: wifiPopupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            Rectangle {
                id: wifiPopupBg

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

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 2
                height: 24
                color: Style.crust
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 2
                height: 24
                color: Style.crust
            }

            MouseArea {
                id: wifiParentMouseArea

                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    wifiPopupContent.width = 280;
                    wifiPopupContent.height = 280;
                    wifiPopupContent.opacity = 1;
                }
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                Item {
                    width: parent.width
                    height: 24

                    Text {
                        text: "Wi-Fi Networks"
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "refresh"
                        color: Style.green
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 14
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: scanMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
                                wifiPopup.refreshWifi();
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Style.surface1
                }

                ListView {
                    width: parent.width
                    height: parent.height - 24 - 1 - 12
                    model: wifiListModel
                    spacing: 4
                    clip: true

                    delegate: Item {
                        width: ListView.view.width
                        height: 32

                        Rectangle {
                            anchors.fill: parent
                            color: itemMouseArea.containsMouse ? Style.surface0 : "transparent"
                            radius: 4
                        }

                        MouseArea {
                            id: itemMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: wifiPopup.isAnyItemHovered = true
                            onExited: wifiPopup.isAnyItemHovered = false
                        }

                        Text {
                            id: sigIcon

                            text: {
                                if (model.signal >= 75)
                                    return "network_wifi_3_bar";

                                if (model.signal >= 50)
                                    return "network_wifi_3_bar";

                                if (model.signal >= 25)
                                    return "network_wifi_2_bar";

                                return "signal_wifi_4_bar";
                            }
                            color: model.active ? Style.green : Style.text
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: ssidText

                            text: model.ssid
                            color: model.active ? Style.green : Style.text
                            font.family: Style.fontFamily
                            font.pixelSize: 12
                            font.weight: model.active ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                            anchors.left: sigIcon.right
                            anchors.leftMargin: 12
                            anchors.right: lockIcon.visible ? lockIcon.left : actionIcon.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: lockIcon

                            text: "lock"
                            visible: model.security !== "" && model.security !== "--"
                            color: Style.subtext0
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 11
                            anchors.right: actionIcon.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: actionIcon

                            text: model.active ? "link_off" : "link"
                            color: model.active ? Style.red : Style.green
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 13
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.active)
                                        Quickshell.execDetached(["nmcli", "connection", "down", model.ssid]);
                                    else
                                        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", model.ssid]);
                                    refreshTimer.start();
                                }
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
