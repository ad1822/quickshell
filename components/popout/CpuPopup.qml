import "../../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo

PopupWindow {
    id: cpuPopup

    readonly property bool isMouseOver: {
        var p = false;
        try {
            p = p || parentMouseArea.containsMouse;
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
        popupContent.width = 150;
        popupContent.height = 230;
        popupContent.opacity = 1;
    }

    function getProcessInfo(name, cpuStr) {
        var cpu = parseFloat(cpuStr) || 0;
        var nameLower = name.toLowerCase();
        var icon = "developer_board"; // default CPU chip icon
        var iconColor = Style.blue;
        if (nameLower.indexOf("firefox") !== -1 || nameLower.indexOf("chrome") !== -1 || nameLower.indexOf("chromium") !== -1 || nameLower.indexOf("zen") !== -1 || nameLower.indexOf("web") !== -1) {
            icon = "language";
            iconColor = Style.green;
        } else if (nameLower.indexOf("nvim") !== -1 || nameLower.indexOf("vim") !== -1 || nameLower.indexOf("code") !== -1 || nameLower.indexOf("emacs") !== -1) {
            icon = "terminal";
            iconColor = Style.mauve;
        } else if (nameLower.indexOf("kitty") !== -1 || nameLower.indexOf("foot") !== -1 || nameLower.indexOf("alacritty") !== -1 || nameLower.indexOf("terminal") !== -1 || nameLower.indexOf("fish") !== -1 || nameLower.indexOf("bash") !== -1 || nameLower.indexOf("zsh") !== -1) {
            icon = "terminal";
            iconColor = Style.peach;
        } else if (nameLower.indexOf("hyprland") !== -1 || nameLower.indexOf("quickshell") !== -1 || nameLower.indexOf("qs") !== -1) {
            icon = "widgets";
            iconColor = Style.lavender;
        } else if (nameLower.indexOf("discord") !== -1 || nameLower.indexOf("vesktop") !== -1) {
            icon = "forum";
            iconColor = Style.blue;
        } else if (nameLower.indexOf("spotify") !== -1) {
            icon = "music_note";
            iconColor = Style.green;
        } else if (nameLower.indexOf("steam") !== -1) {
            icon = "sports_esports";
            iconColor = Style.sky;
        } else if (nameLower.indexOf("systemd") !== -1 || nameLower.indexOf("dbus") !== -1 || nameLower.indexOf("pipewire") !== -1 || nameLower.indexOf("wireplumber") !== -1) {
            icon = "settings";
            iconColor = Style.overlay2;
        }
        if (cpu > 20)
            iconColor = Style.red;
        else if (cpu > 5 && iconColor === Style.blue)
            iconColor = Style.yellow;
        return {
            "icon": icon,
            "color": iconColor
        };
    }

    onIsMouseOverChanged: {
        if (isMouseOver) {
            openTimer.stop();
            closeTimer.stop();
            if (destroyTimer.running)
                cpuPopup.cancelClose();

        } else {
            closeTimer.start();
        }
    }
    anchor.window: barWindow
    // Align the popup's center to the CPU widget's center (globally mapped)
    anchor.rect.x: modulesContainer.x + cpuWidget.x + (cpuWidget.width / 2) - 110
    anchor.rect.y: barWindow.height
    implicitWidth: 220
    implicitHeight: 230
    color: "transparent"
    visible: true
    onVisibleChanged: {
        if (!visible)
            popupLoader.active = false;

    }
    Component.onCompleted: {
        topProcessesProc.running = true;
    }

    Timer {
        id: destroyTimer

        interval: 800
        repeat: false
        onTriggered: popupLoader.active = false
    }

    ListModel {
        id: topProcessesModel
    }

    QsIo.Process {
        id: topProcessesProc

        command: ["sh", "-c", "ps -eo pcpu,comm --sort=-pcpu | tail -n +2 | head -13"]

        stdout: QsIo.StdioCollector {
            onStreamFinished: {
                topProcessesModel.clear();
                var lines = this.text.trim().split("\n");
                var count = 0;
                for (var i = 0; i < lines.length && count < 10; i++) {
                    var line = lines[i].trim();
                    if (line === "")
                        continue;

                    var parts = line.split(/\s+/);
                    var cpu = parts[0];
                    var name = parts.slice(1).join(" ");
                    if (name === "ps" || name === "sh" || name === "bash")
                        continue;

                    topProcessesModel.append({
                        "name": name,
                        "cpu": cpu
                    });
                    count++;
                }
            }
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: topProcessesProc.running = true
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

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: {
                    popupContent.width = 150;
                    popupContent.height = 230;
                    popupContent.opacity = 1;
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: 10
                model: topProcessesModel
                spacing: 6
                clip: true

                delegate: Row {
                    property var info: getProcessInfo(model.name, model.cpu)

                    width: ListView.view.width
                    spacing: 8
                    height: 18

                    Text {
                        text: info.icon
                        color: info.color
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        width: 14
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 22
                        text: model.name
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
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
                    duration: Style.durationExpressiveSlowSpatial
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Style.expressiveSlowSpatialCurve
                }
            }

        }

    }

}
