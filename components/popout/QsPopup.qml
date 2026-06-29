import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../components"

PopupWindow {
    id: qsPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || parentMouseArea.containsMouse;
        } catch (e) {
        }
        try {
            p = p || volSliderMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || brightSliderMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || volKnobMouse.containsMouse;
        } catch (e) {
        }
        try {
            p = p || brightKnobMouse.containsMouse;
        } catch (e) {
        }
        return p;
    }

    function closePopup() {
        popupContent.width = 40;
        popupContent.height = 20;
        popupContent.opacity = 0;
        destroyTimer.start();
    }

    function cancelClose() {
        destroyTimer.stop();
        popupContent.width = 280;
        popupContent.height = 110;
        popupContent.opacity = 1;
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            qsOpenTimer.stop();
            qsCloseTimer.stop();
            if (destroyTimer.running)
                qsPopup.cancelClose();
        } else {
            qsCloseTimer.start();
        }
    }
    anchor.window: barWindow
    anchor.rect.x: rightContainer.x + (barVolumeWidget.x + barBrightnessWidget.x) / 2 + (barVolumeWidget.width / 2) - 164
    anchor.rect.y: barWindow.height
    implicitWidth: 328
    implicitHeight: 110
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            qsPopupLoader.active = false;
    }

    Timer {
        id: destroyTimer

        interval: 300
        repeat: false
        onTriggered: qsPopupLoader.active = false
    }

    Item {
        anchors.fill: parent

        // Left Fillet (Inverted Border Corner)
        Shape {
            id: leftFillet

            width: 24
            height: 24
            anchors.right: popupContent.left
            anchors.top: popupContent.top
            opacity: popupContent.opacity
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
            id: rightFillet

            width: 24
            height: 24
            anchors.left: popupContent.right
            anchors.top: popupContent.top
            opacity: popupContent.opacity
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
            id: popupContent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 40
            height: 20
            clip: true
            opacity: 0

            Rectangle {
                id: popupBg

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
                propagateComposedEvents: true
            }

            // Content layout
            Column {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                // VOLUME ROW
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8

                    Item {
                        id: volSliderContainer

                        width: parent.width
                        height: 32

                        Rectangle {
                            id: volTrack

                            width: parent.width
                            height: 6
                            radius: 3
                            color: Style.surface1
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: volFill

                                width: parent.width * (barVolumeWidget.volume / 100)
                                height: parent.height
                                radius: 3
                                color: barVolumeWidget.isMuted ? Style.overlay1 : Style.blue
                            }

                            // 22px Knob containing the Volume Icon
                            Rectangle {
                                id: volKnob

                                readonly property bool active: volKnobMouse.containsMouse || volSliderMouse.pressed

                                width: 22
                                height: 22
                                radius: 11
                                color: barVolumeWidget.isMuted ? Style.red : Style.blue
                                border.color: active ? Style.rosewater : Style.base
                                border.width: active ? 2.5 : 1.5
                                x: volFill.width - 11
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: {
                                        if (barVolumeWidget.isMuted)
                                            return "volume_off";

                                        if (barVolumeWidget.volume < 33)
                                            return "volume_down";

                                        if (barVolumeWidget.volume < 66)
                                            return "volume_down";

                                        return "volume_up";
                                    }
                                    color: Style.base
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 11
                                    font.weight: Style.fontWeight
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: volKnobMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    propagateComposedEvents: true
                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.LeftButton)
                                            mouse.accepted = false;
                                    }
                                    onClicked: (mouse) => {
                                        Quickshell.execDetached(["pamixer", "-t"]);
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: volSliderMouse

                            function updateVolume(mouse) {
                                var pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                Quickshell.execDetached(["pamixer", "--set-volume", pct.toString()]);
                                barVolumeWidget.volume = pct;
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onPressed: (mouse) => {
                                return updateVolume(mouse);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed)
                                    updateVolume(mouse);
                            }

                            // Bind the volume adjustment guard to prevent background processes from overriding drags
                            Binding {
                                target: barVolumeWidget
                                property: "isAdjusting"
                                value: volSliderMouse.pressed
                            }
                        }
                    }
                }

                // BRIGHTNESS ROW
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8

                    Item {
                        id: brightSliderContainer

                        width: parent.width
                        height: 32

                        Rectangle {
                            id: brightTrack

                            width: parent.width
                            height: 6
                            radius: 3
                            color: Style.surface1
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: brightFill

                                width: parent.width * (barBrightnessWidget.brightness / 100)
                                height: parent.height
                                radius: 3
                                color: Style.mauve
                            }

                            // 22px Knob containing the Brightness Icon
                            Rectangle {
                                id: brightKnob

                                readonly property bool active: brightKnobMouse.containsMouse || brightSliderMouse.pressed

                                width: 22
                                height: 22
                                radius: 11
                                color: Style.mauve
                                border.color: active ? Style.rosewater : Style.base
                                border.width: active ? 2.5 : 1.5
                                x: brightFill.width - 11
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: barBrightnessWidget.brightnessIcon(barBrightnessWidget.brightness)
                                    color: Style.base
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 11
                                    font.weight: Style.fontWeight
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: brightKnobMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    propagateComposedEvents: true
                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.LeftButton)
                                            mouse.accepted = false;
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: brightSliderMouse

                            function updateBrightness(mouse) {
                                var pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                var clamped = Math.max(10, Math.min(100, pct));
                                Quickshell.execDetached(["brightnessctl", "s", clamped + "%"]);
                                barBrightnessWidget.brightness = clamped;
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onPressed: (mouse) => {
                                return updateBrightness(mouse);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed)
                                    updateBrightness(mouse);
                            }

                            // Bind the brightness adjustment guard
                            Binding {
                                target: barBrightnessWidget
                                property: "isAdjusting"
                                value: brightSliderMouse.pressed
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

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: qsPopup.cancelClose()
    }
}
