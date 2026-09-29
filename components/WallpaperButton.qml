import QtQuick
import Quickshell.Io
// Namespaced: components/Style is this shell's palette, qs.Commons.Style holds
// the bar geometry tokens the imported widgets size themselves from.
import qs.Commons as Omarchy

// This button predates the imported panel widgets and used to carry its own
// 26x22 slot, its own glyph size and an accent colour of its own, which left
// it visibly smaller and differently tinted than the icons beside it. It now
// takes the same three tokens they do, so the row reads evenly.
Rectangle {
    id: wallRoot

    implicitWidth: Omarchy.Style.bar.iconSlot
    implicitHeight: Omarchy.Style.bar.iconSlot
    color: "transparent"
    radius: 8

    Text {
        text: "wallpaper"
        // Style.lavender is what OmarchyBarApi hands the other bar glyphs as
        // barForeground, so this matches rather than standing out.
        color: Style.text
        font.family: "Material Symbols Rounded"
        font.pixelSize: Omarchy.Style.bar.iconFont
        font.variableAxes: { "wght": 300 }
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
