import QtQuick
import Quickshell.Io

Rectangle {
    id: wifiRoot

    property string connectionState: "disconnected" // wifi, ethernet, disconnected

    signal clicked()
    signal hovered(bool isHovered)

    implicitWidth: contentText.implicitWidth + 8
    implicitHeight: 22
    color: "transparent"
    radius: 6
    Component.onCompleted: wifiProc.running = true

    Text {
        id: contentText

        text: {
            if (wifiRoot.connectionState === "wifi")
                return "wifi";
            else if (wifiRoot.connectionState === "ethernet")
                return "settings_ethernet";
            else
                return "wifi_off";
        }
        color: wifiRoot.connectionState === "disconnected" ? Style.red : Style.lavender
        font.family: "Material Symbols Rounded"
        font.pixelSize: Style.fontSize
        font.weight: Style.fontWeight
        anchors.centerIn: parent
    }

    Process {
        id: wifiProc

        command: ["sh", "-c", "dev=$(ip route | grep default | head -1 | awk '{print $5}'); " + "if [ -z \"$dev\" ]; then echo \"disconnected\"; " + "elif [[ \"$dev\" == w* ]]; then echo \"wifi\"; " + "else echo \"ethernet\"; fi"]
        running: false

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                wifiRoot.connectionState = data.trim();
            }
        }

    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wifiRoot.clicked()
        onEntered: wifiRoot.hovered(true)
        onExited: wifiRoot.hovered(false)
    }

}
