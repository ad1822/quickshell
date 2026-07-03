import QtQuick
import Quickshell.Io

Rectangle {
    id: wallRoot

    implicitWidth: 26
    implicitHeight: 22
    color: "transparent"
    radius: 8

    Text {
        text: "wallpaper"
        color: mouseArea.containsMouse ? Style.mauve : Style.mauve
        font.family: "Material Symbols Rounded"
        font.pixelSize: Style.fontSize
        font.weight: Style.fontWeight
        anchors.centerIn: parent
    }

    Process {
        id: changeWallpaperProc

        command: ["sh", "-c", "/home/ad/.config/waybar/scripts/change-wallpaper.sh; pkill hyprpaper; nohup hyprpaper >/dev/null 2>&1 &"]
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            changeWallpaperProc.running = true;
        }
    }

}
