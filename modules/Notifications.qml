import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../components"

PanelWindow {
    id: notifWindow

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 600
    property int activeNotificationsCount: 0
    visible: activeNotificationsCount > 0 && barWindow.barExpanded
    color: "transparent"
    margins.top: 40
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: 0

    mask: Region {
        item: notifColumn
    }



    Column {
        id: notifColumn

        anchors.horizontalCenter: parent.horizontalCenter
        width: 360
        spacing: 8

        Repeater {
            id: notifRepeater
            model: globalNotifServer.trackedNotifications

            delegate: Rectangle {
                id: delegateRoot

                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                color: "#11111b"
                border.color: "#313244"
                border.width: 1
                radius: 12

                state: "incoming"

                states: [
                    State {
                        name: "incoming"
                        PropertyChanges { target: delegateRoot; width: 0; height: 0; opacity: 0 }
                        PropertyChanges { target: contentLayout; opacity: 0 }
                    },
                    State {
                        name: "active"
                        PropertyChanges { target: delegateRoot; width: 360; height: 68; opacity: 1 }
                        PropertyChanges { target: contentLayout; opacity: 1 }
                    },
                    State {
                        name: "exiting"
                        PropertyChanges { target: delegateRoot; width: 0; height: 0; opacity: 0 }
                        PropertyChanges { target: contentLayout; opacity: 0 }
                    }
                ]

                transitions: [
                    Transition {
                        from: "incoming"; to: "active"
                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation { property: "width"; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
                                NumberAnimation { property: "height"; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
                                NumberAnimation { property: "opacity"; duration: 250; easing.type: Easing.OutQuad }
                            }
                            NumberAnimation { target: contentLayout; property: "opacity"; duration: 150; easing.type: Easing.OutQuad }
                        }
                    },
                    Transition {
                        from: "active"; to: "exiting"
                        SequentialAnimation {
                            NumberAnimation { target: contentLayout; property: "opacity"; duration: 100; easing.type: Easing.OutQuad }
                            ParallelAnimation {
                                NumberAnimation { property: "width"; duration: 250; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "height"; duration: 250; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "opacity"; duration: 150; easing.type: Easing.OutQuad }
                            }
                            ScriptAction {
                                script: {
                                    modelData.dismiss();
                                }
                            }
                        }
                    }
                ]

                Component.onCompleted: delegateRoot.state = "active"

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

                        Text {
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            color: parent.containsMouse ? Style.red : Style.overlay1
                            anchors.centerIn: parent
                        }

                        onClicked: delegateRoot.state = "exiting"
                    }

                    Column {
                        id: textColumn
                        anchors.left: parent.left
                        anchors.right: closeButton.left
                        anchors.leftMargin: 16
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
            }
        }
    }
}
