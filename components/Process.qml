import QtQuick
import Quickshell.Io

Rectangle {
    id: cpuRoot

    signal clicked()
    signal hovered(bool isHovered)

    property int lastCpuTotal: 0
    property int lastCpuIdle: 0
    property int cpuUsage: 0

    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 22
    color: "transparent"
    radius: 6

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "developer_board"
            color: Style.blue
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }

        Text {
            text: cpuRoot.cpuUsage + "%"
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return;

                var p = data.trim().split(/\s+/);
                var idle = parseInt(p[4]) + parseInt(p[5]);
                var total = p.slice(1, 8).reduce((a, b) => {
                    return a + parseInt(b);
                }, 0);

                if (cpuRoot.lastCpuTotal > 0) {
                    var diffTotal = total - cpuRoot.lastCpuTotal;
                    var diffIdle = idle - cpuRoot.lastCpuIdle;
                    if (diffTotal > 0) {
                        cpuRoot.cpuUsage = Math.round(100 * (1 - diffIdle / diffTotal));
                    }
                }

                cpuRoot.lastCpuTotal = total;
                cpuRoot.lastCpuIdle = idle;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cpuRoot.clicked()
        onEntered: cpuRoot.hovered(true)
        onExited: cpuRoot.hovered(false)
    }

    Component.onCompleted: cpuProc.running = true
}
