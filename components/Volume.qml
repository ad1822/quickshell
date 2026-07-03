import QtQuick
import Quickshell.Io

Rectangle {
    // Material Symbols has no distinct "medium" glyph, reuse down

    id: volRoot

    property int volume: 0
    property bool isMuted: false
    property bool isHeadphones: false
    property bool isAdjusting: false // Guard property to ignore async feedback loop jitter while dragging

    signal hovered(bool isHovered)

    function volumeIcon(level, muted) {
        if (muted)
            return "volume_off";
        if (volRoot.isHeadphones)
            return "headphones";
        if (level <= 0)
            return "volume_off";
        else if (level < 33)
            return "volume_down";
        else if (level < 66)
            return "volume_down";
        else
            return "volume_up";
    }

    implicitWidth: contentText.implicitWidth + 8
    implicitHeight: 22
    color: "transparent"
    radius: 8

    Text {
        id: contentText

        text: volRoot.volumeIcon(volRoot.volume, volRoot.isMuted)
        color: volRoot.isMuted ? Style.red : Style.lavender
        font.family: "Material Symbols Rounded"
        font.pixelSize: Style.fontSize + 2
        font.weight: Style.fontWeight
        anchors.centerIn: parent
    }

    Process {
        id: volProc

        command: ["sh", "-c",
            "get_status() { " +
            "  echo \"$(pamixer --get-volume)::$(pamixer --get-mute)::$(pactl list sinks | grep -A 100 \"$(pactl get-default-sink)\" | grep \"Active Port\" | grep -qiE 'headphone|headset|bluez' && echo 'true' || echo 'false')\"; " +
            "}; " +
            "get_status; " +
            "pactl subscribe | grep --line-buffered \"Event 'change' on sink\" | while read -r line; do " +
            "  get_status; " +
            "done"
        ]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                var parts = data.trim().split("::");
                if (parts.length >= 3) {
                    if (!volRoot.isAdjusting)
                        volRoot.volume = parseInt(parts[0]) || 0;

                    volRoot.isMuted = (parts[1].trim() === "true");
                    volRoot.isHeadphones = (parts[2].trim() === "true");
                }
            }
        }

    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: volRoot.hovered(true)
        onExited: volRoot.hovered(false)
    }

}
