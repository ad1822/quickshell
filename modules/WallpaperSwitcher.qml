import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: wallpaperWindow

    // Layer-shell setup
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "wallpaper-switcher"
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand
    WlrLayershell.exclusiveZone: 0

    anchors.bottom: true
    anchors.left: false
    anchors.right: false

    implicitWidth: 808
    implicitHeight: 112

    margins.bottom: 40

    color: "transparent"
    visible: false

    // App state
    property list<var> allWallpapers
    property list<var> filteredWallpapers
    property int selectedIndex: 0

    onVisibleChanged: {
        if (visible) {
            mainLayout.forceActiveFocus();
            selectedIndex = 0;
            filter("");
        }
    }

    onSelectedIndexChanged: {
        resultsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    // IPC Handler to toggle from binds
    IpcHandler {
        target: "wallpaperswitcher"
        function toggle(): void {
            wallpaperWindow.visible = !wallpaperWindow.visible;
        }
    }

    // Python-based fast directory scanner (sorted by modification time descending)
    Process {
        id: wallpaperScanner
        command: ["python3", "-c", "import os, json; d=os.path.expanduser('~/Pictures/Wallpaper'); ext=('.jpg','.jpeg','.png','.webp'); files=[e for e in os.scandir(d) if e.is_file() and e.name.lower().endswith(ext)]; files.sort(key=lambda x: os.path.getmtime(x.path), reverse=True); print(json.dumps([{'name': e.name, 'path': e.path} for e in files]))"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (!data) return;
                try {
                    allWallpapers = JSON.parse(data.trim());
                    filter("");
                } catch(e) {}
            }
        }
    }

    function filter(query) {
        var filtered = [];
        var lowerQuery = query.toLowerCase();
        for (var i = 0; i < allWallpapers.length; i++) {
            var item = allWallpapers[i];
            if (lowerQuery === "" || item.name.toLowerCase().indexOf(lowerQuery) !== -1) {
                filtered.push(item);
            }
        }
        filteredWallpapers = filtered;
        if (selectedIndex >= filtered.length) {
            selectedIndex = Math.max(0, filtered.length - 1);
        }
    }

    // Outer Container
    Rectangle {
        id: mainLayout
        anchors.fill: parent
        radius: 20
        color: "#e011111b" // Translucent Catppuccin Crust
        clip: true
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Right) {
                if (wallpaperWindow.filteredWallpapers.length > 0) {
                    wallpaperWindow.selectedIndex = (wallpaperWindow.selectedIndex + 1) % wallpaperWindow.filteredWallpapers.length;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                if (wallpaperWindow.filteredWallpapers.length > 0) {
                    wallpaperWindow.selectedIndex = (wallpaperWindow.selectedIndex - 1 + wallpaperWindow.filteredWallpapers.length) % wallpaperWindow.filteredWallpapers.length;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                if (wallpaperWindow.filteredWallpapers.length > 0 && wallpaperWindow.selectedIndex >= 0 && wallpaperWindow.selectedIndex < wallpaperWindow.filteredWallpapers.length) {
                    var selected = wallpaperWindow.filteredWallpapers[wallpaperWindow.selectedIndex];
                    Quickshell.execDetached(["/home/ad/config_bak/quickshell/scripts/set-wallpaper.sh", selected.path]);
                    wallpaperWindow.visible = false;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                wallpaperWindow.visible = false;
                event.accepted = true;
            }
        }

        // Horizontal Preview Ribbon
        ListView {
            id: resultsList
            anchors.fill: parent
            anchors.margins: 12
            orientation: ListView.Horizontal
            spacing: 16
            model: wallpaperWindow.filteredWallpapers
            clip: true

            delegate: Rectangle {
                width: 144
                height: 88
                color: "transparent"

                // Lazy loading: Only load the wallpaper file if it is within 8 items of selection cursor
                property bool shouldLoad: Math.abs(index - wallpaperWindow.selectedIndex) < 8

                // Apple TV-style outer focus ring
                Rectangle {
                    id: imgBorder
                    width: 140
                    height: 84
                    radius: 14
                    color: "transparent"
                    border.color: index === wallpaperWindow.selectedIndex ? Style.lavender : "transparent"
                    border.width: index === wallpaperWindow.selectedIndex ? 2 : 0
                    scale: index === wallpaperWindow.selectedIndex ? 1.05 : 1.0
                    anchors.centerIn: parent

                    Behavior on scale {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    // Rounded Thumbnail
                    Rectangle {
                        width: 132
                        height: 76
                        radius: 11
                        clip: true
                        color: Style.mantle
                        anchors.centerIn: parent

                        Image {
                            anchors.fill: parent
                            source: shouldLoad ? ("file://" + modelData.path) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            mipmap: true
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        wallpaperWindow.selectedIndex = index;
                    }
                    onClicked: {
                        Quickshell.execDetached(["/home/ad/config_bak/quickshell/scripts/set-wallpaper.sh", modelData.path]);
                        wallpaperWindow.visible = false;
                    }
                }
            }
        }
    }
}
