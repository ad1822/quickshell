import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../components"

PopupWindow {
    id: battPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || battParentMouseArea.containsMouse;
        } catch (e) {
        }
        return p;
    }

    function closePopup() {
        battPopupContent.width = 40;
        battPopupContent.height = 20;
        battPopupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        battPopupContent.width = 240;
        battPopupContent.height = 90;
        battPopupContent.opacity = 1;
    }

    anchor.window: barWindow
    // Align the popup's center to the Battery widget's center (globally mapped)
    anchor.rect.x: rightContainer.x + barBatteryWidget.x + (barBatteryWidget.width / 2) - 144
    anchor.rect.y: barWindow.height
    implicitWidth: 288
    implicitHeight: 90
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible) {
        }
    }
    onIsMouseOverChanged: {
        if (isMouseOver) {
            battOpenTimer.stop();
            battCloseTimer.stop();
            if (destroyTimer.running)
                battPopup.cancelClose();
        } else {
            battCloseTimer.start();
        }
    }

    Timer {
        id: destroyTimer

        interval: 300
        repeat: false
        onTriggered: battPopupLoader.active = false
    }

    Item {
        anchors.fill: parent

        // Left Fillet
        Shape {
            id: battLeftFillet

            width: 24
            height: 24
            anchors.right: battPopupContent.left
            anchors.top: battPopupContent.top
            opacity: battPopupContent.opacity
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
            id: battRightFillet

            width: 24
            height: 24
            anchors.left: battPopupContent.right
            anchors.top: battPopupContent.top
            opacity: battPopupContent.opacity
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
            id: battPopupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            Rectangle {
                id: battPopupBg

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
                id: battParentMouseArea

                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    battPopupContent.width = 240;
                    battPopupContent.height = 90;
                    battPopupContent.opacity = 1;
                }
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 8

                Item {
                    width: parent.width
                    height: 20

                    Text {
                        text: "Battery Status"
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: {
                            if (!barBatteryWidget.isLaptopBattery)
                                return "No battery";

                            return Math.round(barBatteryWidget.percentage * 100) + "%";
                        }
                        color: {
                            var pct = Math.round(barBatteryWidget.percentage * 100);
                            if (pct <= 20)
                                return Style.red;

                            if (pct <= 40)
                                return Style.yellow;

                            return Style.green;
                        }
                        font.family: Style.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    function formatSeconds(s) {
                        if (s <= 0)
                            return "";

                        var hr = Math.floor(s / 3600) % 60;
                        var min = Math.floor(s / 60) % 60;
                        var comps = [];
                        if (hr > 0)
                            comps.push(hr + "h");

                        if (min > 0)
                            comps.push(min + "m");

                        return comps.join(" ");
                    }

                    text: {
                        if (!barBatteryWidget.isLaptopBattery)
                            return "No laptop battery detected";

                        var stateText = barBatteryWidget.isCharging ? "Charging" : "Discharging";
                        var timeVal = UPower.onBattery ? UPower.displayDevice.timeToEmpty : UPower.displayDevice.timeToFull;
                        var timeStr = formatSeconds(timeVal);
                        if (timeStr !== "")
                            return stateText + " • " + timeStr + (UPower.onBattery ? " remaining" : " until charged");

                        return stateText + (barBatteryWidget.isCharging ? " • Fully charged!" : "");
                    }
                    color: Style.subtext0
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width
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
