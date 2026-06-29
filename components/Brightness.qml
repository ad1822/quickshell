import QtQuick
import Quickshell.Io

Rectangle {
    id: brightRoot

    property int brightness: 0
    property bool isAdjusting: false // Guard property to prevent drag overrides

    signal hovered(bool isHovered)

    // Map 0-100 brightness into the 7-step brightness_1..brightness_7 icon set
    function brightnessIcon(level) {
        if (level <= 0)
            return "brightness_1";
        else if (level < 17)
            return "brightness_2";
        else if (level < 34)
            return "brightness_3";
        else if (level < 50)
            return "brightness_4";
        else if (level < 67)
            return "brightness_5";
        else if (level < 84)
            return "brightness_6";
        else
            return "brightness_7";
    }

    implicitWidth: contentText.implicitWidth + 8
    implicitHeight: 22
    color: "transparent"
    radius: 6
    Component.onCompleted: brightProc.running = true

    Text {
        id: contentText

        text: brightRoot.brightnessIcon(brightRoot.brightness)
        color: Style.lavender
        font.family: "Material Symbols Rounded"
        font.pixelSize: Style.fontSize
        font.weight: Style.fontWeight
        anchors.centerIn: parent
    }

    Process {
        id: brightProc

        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        running: false

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                if (!brightRoot.isAdjusting)
                    brightRoot.brightness = parseInt(data.trim()) || 0;

            }
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: brightRoot.hovered(true)
        onExited: brightRoot.hovered(false)
    }

}
