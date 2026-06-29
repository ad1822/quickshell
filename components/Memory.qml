import QtQuick
import Quickshell.Io

Rectangle {
    id: memRoot

    property int memUsage: 0

    signal clicked()
    signal hovered(bool isHovered)

    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 22
    color: "transparent"
    radius: 6

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "memory"
            color: Style.blue
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }

        Text {
            text: memRoot.memUsage + "%"
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }
    }

    Component.onCompleted: memProc.running = true

    Process {
        id: memProc
        command: ["sh", "-c", "grep -E 'MemTotal|MemAvailable' /proc/meminfo"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                var total = 0;
                var available = 0;
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("MemTotal:") === 0)
                        total = parseInt(line.split(/\s+/)[1]);
                    else if (line.indexOf("MemAvailable:") === 0)
                        available = parseInt(line.split(/\s+/)[1]);
                }
                if (total > 0)
                    memRoot.memUsage = Math.round(100 * (total - available) / total);
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: memProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: memRoot.clicked()
        onEntered: memRoot.hovered(true)
        onExited: memRoot.hovered(false)
    }
}
