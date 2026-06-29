import QtQuick
import Quickshell.Io

Rectangle {
    id: netRoot

    property string rxSpeedFormatted: "0 B/s"
    property string txSpeedFormatted: "0 B/s"

    signal clicked()
    signal hovered(bool isHovered)

    function formatSpeed(bytes) {
        if (bytes < 1024)
            return bytes + " B/s";

        var kb = bytes / 1024;
        if (kb < 1024)
            return kb.toFixed(1) + " Kb/s";

        var mb = kb / 1024;
        return mb.toFixed(1) + " Mb/s";
    }

    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 22
    color: "transparent"
    radius: 6

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "arrow_downward"
            color: Style.green
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }

        Text {
            text: netRoot.rxSpeedFormatted
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }

        Item { width: 4; height: 1 }

        Text {
            text: "arrow_upward"
            color: Style.red
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }

        Text {
            text: netRoot.txSpeedFormatted
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
        }
    }

    Process {
        id: netProc

        command: ["sh", "-c", "dev=$(ip route | grep default | head -1 | awk '{print $5}'); " + "[ -z \"$dev\" ] && dev=$(awk -F: 'NR>2 {print $1}' /proc/net/dev | tr -d ' ' | grep -vE 'lo|veth|docker|br-|tun' | head -1); " + "[ -z \"$dev\" ] && dev=\"wlan0\"; " + "read -r rx1 tx1 <<< $(awk -v dev=\"$dev\" '$1 ~ dev {print $2, $10}' /proc/net/dev); " + "while true; do " + "  sleep 1; " + "  read -r rx2 tx2 <<< $(awk -v dev=\"$dev\" '$1 ~ dev {print $2, $10}' /proc/net/dev); " + "  echo \"$((rx2 - rx1)) $((tx2 - tx1))\"; " + "  rx1=$rx2; " + "  tx1=$tx2; " + "done"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                var parts = data.trim().split(/\s+/);
                if (parts.length >= 2) {
                    var rx = parseInt(parts[0]);
                    var tx = parseInt(parts[1]);
                    netRoot.rxSpeedFormatted = netRoot.formatSpeed(rx);
                    netRoot.txSpeedFormatted = netRoot.formatSpeed(tx);
                }
            }
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: netRoot.clicked()
        onEntered: netRoot.hovered(true)
        onExited: netRoot.hovered(false)
    }

}
