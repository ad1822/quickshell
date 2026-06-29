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

        command: [
            "sh", "-c",
            "dir=$(ls -d /sys/class/backlight/* 2>/dev/null | head -1); " +
            "if [ -n \"$dir\" ] && [ -d \"$dir\" ]; then " +
            "  max=$(cat \"$dir/max_brightness\"); " +
            "  last=\"\"; " +
            "  while true; do " +
            "    curr=$(cat \"$dir/brightness\"); " +
            "    if [ \"$curr\" != \"$last\" ]; then " +
            "      echo $(( curr * 100 / max )); " +
            "      last=\"$curr\"; " +
            "    fi; " +
            "    sleep 0.15; " +
            "  done; " +
            "fi"
        ]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                var val = parseInt(data.trim());
                if (!isNaN(val)) {
                    if (!brightRoot.isAdjusting)
                        brightRoot.brightness = val;
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: brightRoot.hovered(true)
        onExited: brightRoot.hovered(false)
    }

}
