import "../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

PopupWindow {
    id: notifWindow

    property int activeNotificationsCount: 0
    property bool entranceActive: false
    property bool windowVisible: false

    function checkState() {
        var targetActive = (activeNotificationsCount > 0 && barWindow.barExpanded);
        if (targetActive) {
            exitTimer.stop();
            windowVisible = true;
            entranceTimer.start();
        } else {
            entranceTimer.stop();
            entranceActive = false;
            exitTimer.start();
        }
    }

    onActiveNotificationsCountChanged: {
        checkState();
    }

    anchor.window: barWindow
    anchor.rect.x: (barWindow.width / 2) - 204
    anchor.rect.y: barWindow.height
    implicitWidth: 408
    implicitHeight: 600
    color: "transparent"
    visible: windowVisible

    Connections {
        function onBarExpandedChanged() {
            checkState();
        }

        target: barWindow
    }

    Timer {
        id: entranceTimer

        interval: 50
        repeat: false
        onTriggered: entranceActive = true
    }

    Timer {
        id: exitTimer

        // Give the collapse-to-pill animation time to finish before the
        // window (and its layershell surface) is torn down.
        interval: 800
        repeat: false
        onTriggered: windowVisible = false
    }

    Item {
        id: notifWindowContent

        anchors.fill: parent
        visible: notifColumn.implicitHeight > 0

        // Left Fillet
        Shape {
            id: leftFillet

            width: 24
            height: 24
            anchors.right: notifContainer.left
            anchors.top: notifContainer.top
            opacity: notifContainer.opacity
            visible: opacity > 0.01
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "#11111b"
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
            id: rightFillet

            width: 24
            height: 24
            anchors.left: notifContainer.right
            anchors.top: notifContainer.top
            opacity: notifContainer.opacity
            visible: opacity > 0.01
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "#11111b"
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

        // The Island itself. Instead of animating width/height/opacity as
        // three independent Behaviors (which all run in parallel and never
        // feel like a "capsule opening up"), this uses an explicit state +
        // multi-stage Transition so the shape actually unfolds in sequence,
        // the way the macOS Dynamic Island does.
        Item {
            id: notifContainer

            readonly property int collapsedWidth: 40
            readonly property int collapsedHeight: 20
            readonly property int expandedWidth: 360
            readonly property real expandedHeight: notifColumn.implicitHeight > 0 ? notifColumn.implicitHeight + 12 : 20

            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            clip: true

            width: entranceActive ? expandedWidth : collapsedWidth
            height: entranceActive ? expandedHeight : collapsedHeight
            opacity: entranceActive ? 1 : 0

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

            Rectangle {
                id: notifBg

                anchors.top: parent.top
                anchors.topMargin: -24
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: 24
                color: "#11111b"
            }

            Column {
                id: notifColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 12
                spacing: 8

                Repeater {
                    id: notifRepeater

                    model: globalNotifServer.trackedNotifications

                    delegate: Rectangle {
                        id: delegateRoot

                        // Fully expanded target geometry
                        readonly property int expandedWidth: 336
                        readonly property int expandedHeight: 68
                        readonly property int expandedRadius: 20

                        function getIconSource() {
                            var iconName = modelData.icon || modelData.appIcon;
                            if (!iconName)
                                return "";

                            if (iconName.indexOf("/") === 0)
                                return "file://" + iconName;

                            var resolved = Quickshell.iconPath(iconName);
                            if (resolved)
                                return (resolved.toString().indexOf("/") === 0) ? "file://" + resolved : resolved;

                            return "";
                        }

                        anchors.horizontalCenter: parent.horizontalCenter
                        clip: true
                        color: "#11111b"
                        border.color: Style.surface0
                        border.width: 0
                        radius: expandedRadius
                        scale: 1
                        transformOrigin: Item.Center
                        state: "incoming"
                        Component.onCompleted: delegateRoot.state = "active"
                        states: [
                            State {
                                name: "incoming"

                                PropertyChanges {
                                    target: delegateRoot
                                    width: delegateRoot.expandedWidth
                                    height: delegateRoot.expandedHeight
                                    radius: delegateRoot.expandedRadius
                                    opacity: 0
                                    scale: 0.9
                                }

                                PropertyChanges {
                                    target: contentLayout
                                    opacity: 0
                                }

                            },
                            State {
                                name: "active"

                                PropertyChanges {
                                    target: delegateRoot
                                    width: delegateRoot.expandedWidth
                                    height: delegateRoot.expandedHeight
                                    radius: delegateRoot.expandedRadius
                                    opacity: 1
                                    scale: 1
                                }

                                PropertyChanges {
                                    target: contentLayout
                                    opacity: 1
                                }

                            },
                            State {
                                name: "exiting"

                                PropertyChanges {
                                    target: delegateRoot
                                    width: delegateRoot.expandedWidth
                                    height: delegateRoot.expandedHeight
                                    radius: delegateRoot.expandedRadius
                                    opacity: 0
                                    scale: 0.9
                                }

                                PropertyChanges {
                                    target: contentLayout
                                    opacity: 0
                                }

                            }
                        ]
                        transitions: [
                            Transition {
                                from: "incoming"
                                to: "active"

                                NumberAnimation {
                                    properties: "opacity,scale"
                                    duration: 260
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.1
                                }

                            },
                            Transition {
                                from: "active"
                                to: "exiting"

                                SequentialAnimation {
                                    NumberAnimation {
                                        properties: "opacity,scale"
                                        to: 0
                                        duration: 180
                                        easing.type: Easing.InQuad
                                    }

                                    ScriptAction {
                                        script: {
                                            modelData.dismiss();
                                        }
                                    }

                                }

                            }
                        ]

                        Timer {
                            interval: 5000
                            running: true
                            repeat: false
                            onTriggered: delegateRoot.state = "exiting"
                        }

                        Item {
                            id: contentLayout

                            anchors.fill: parent

                            MouseArea {
                                id: closeButton

                                width: 20
                                height: 20
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: delegateRoot.state = "exiting"

                                Text {
                                    text: "close"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 16
                                    color: parent.containsMouse ? Style.red : Style.overlay1
                                    anchors.centerIn: parent
                                }

                            }

                            Image {
                                id: appIcon

                                source: delegateRoot.getIconSource()
                                width: 32
                                height: 32
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                visible: source !== ""
                            }

                            Column {
                                id: textColumn

                                anchors.left: appIcon.visible ? appIcon.right : parent.left
                                anchors.right: closeButton.left
                                anchors.leftMargin: appIcon.visible ? 10 : 16
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Row {
                                    spacing: 6
                                    width: parent.width

                                    Text {
                                        text: modelData.appName || "Notification"
                                        color: Style.mauve
                                        font.family: Style.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                }

                                Text {
                                    text: modelData.summary || ""
                                    color: Style.text
                                    font.family: Style.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.body || ""
                                    color: Style.subtext1
                                    font.family: Style.fontFamily
                                    font.pixelSize: 11
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }

                            }

                        }

                    }

                }

                // Smooth reflow whenever notifications are added/removed above/below a given item
                move: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 380
                        easing.type: Easing.OutBack
                        easing.overshoot: 0.6
                    }

                }

            }

        }

    }

    mask: Region {
        item: notifContainer
    }

}
