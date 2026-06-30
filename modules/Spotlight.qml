import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets

PanelWindow {
    id: spotlightWindow

    property var allApps: []
    property var filteredItems: []
    property int selectedIndex: 0

    function toggle() {
        visible = !visible;
        if (visible) {
            searchText.text = "";
            searchText.forceActiveFocus();
            filter("");
            selectedIndex = 0;
        }
    }

    function calculateMath(query) {
        // Safe evaluation of mathematical expressions
        var mathRegex = /^[0-9+\-*/%().\s]+$/;
        if (!mathRegex.test(query)) return null;
        if (/^[0-9.\s]+$/.test(query)) return null;
        try {
            var res = Function('"use strict"; return (' + query + ')')();
            if (typeof res === 'number' && !isNaN(res) && isFinite(res)) {
                return res;
            }
        } catch (e) {}
        return null;
    }

    function getBinaryName(execStr) {
        if (!execStr) return "";
        var trimmed = execStr.trim();
        var firstWord = trimmed.split(" ")[0];
        var lastSlash = firstWord.lastIndexOf("/");
        if (lastSlash !== -1) {
            return firstWord.substring(lastSlash + 1);
        }
        return firstWord;
    }

    function filter(text) {
        // If search is empty, show absolutely no suggestions (macOS style)
        if (!text || text.trim() === "") {
            filteredItems = [];
            selectedIndex = 0;
            return;
        }
        
        var query = text.trim();
        var items = [];

        // 1. Math Calculation
        var calcResult = calculateMath(query);
        if (calcResult !== null) {
            items.push({
                name: query + " = " + calcResult,
                desc: "Calculation (Enter to copy)",
                type: "calc",
                value: calcResult,
                icon: "calculate"
            });
        }

        // 2. Matching Apps
        var queryLower = query.toLowerCase();
        var appMatches = [];
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            var nameLower = app.name.toLowerCase();
            var binaryLower = getBinaryName(app.exec).toLowerCase();
            
            var score = 0;
            
            // 2.1 Name Match
            if (nameLower === queryLower) {
                score += 1000;
            } else if (nameLower.indexOf(queryLower) === 0) {
                score += 500;
            } else if (nameLower.indexOf(" " + queryLower) !== -1) {
                score += 200;
            } else if (nameLower.indexOf(queryLower) !== -1) {
                score += 100;
            }
            
            // 2.2 Binary Name Match (only match actual binary filename, not arguments/URLs)
            if (binaryLower === queryLower) {
                score += 400;
            } else if (binaryLower.indexOf(queryLower) === 0) {
                score += 150;
            } else if (binaryLower.indexOf(queryLower) !== -1) {
                score += 50;
            }
            
            if (score > 0) {
                appMatches.push({
                    app: app,
                    score: score
                });
            }
        }

        // Sort by score descending, and alphabetically if scores are equal
        appMatches.sort(function(a, b) {
            if (b.score !== a.score) {
                return b.score - a.score;
            }
            var nameA = a.app.name.toLowerCase();
            var nameB = b.app.name.toLowerCase();
            if (nameA < nameB) return -1;
            if (nameA > nameB) return 1;
            return 0;
        });

        // Add top 5 matching apps to items
        var limit = Math.min(appMatches.length, 5);
        for (var j = 0; j < limit; j++) {
            var matchedApp = appMatches[j].app;
            items.push({
                name: matchedApp.name,
                desc: "Application",
                type: "app",
                exec: matchedApp.exec,
                icon: matchedApp.icon
            });
        }

        // 3. Search Google on Zen Browser
        items.push({
            name: "Search Google for '" + query + "'",
            desc: "Search in Zen Browser",
            type: "web",
            exec: 'zen-browser "https://www.google.com/search?q=' + encodeURIComponent(query) + '"',
            icon: "language"
        });

        filteredItems = items;
        selectedIndex = 0;
    }

    // Window Setup
    anchors.top: true
    anchors.left: true
    implicitWidth: 600
    implicitHeight: mainLayout.height

    // macOS Spotlight sits slightly elevated on the screen
    margins.top: screen ? (screen.height - implicitHeight) / 3.5 : 150
    margins.left: screen ? (screen.width - implicitWidth) / 2 : 200

    color: "transparent"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: false

    Shortcut {
        sequence: "Escape"
        onActivated: spotlightWindow.visible = false
    }

    // App List Fetcher
    Process {
        id: appFetcher
        command: ["python3", "-c", "
import os, glob, json, re
apps = []
paths = ['/usr/share/applications/*.desktop', os.path.expanduser('~/.local/share/applications/*.desktop')]
seen = set()
for p in paths:
    for fpath in glob.glob(p):
        try:
            with open(fpath, 'r', errors='ignore') as f:
                content = f.read()
            entry = re.search(r'\\[Desktop Entry\\](.*?)(?=\\n\\[|$)', content, re.DOTALL)
            if entry:
                lines = entry.group(1).split('\\n')
                name, exec_cmd, icon, nodisplay = None, None, None, False
                for line in lines:
                    if '=' in line:
                        k, v = line.split('=', 1)
                        k, v = k.strip(), v.strip()
                        if k == 'Name': name = v
                        elif k == 'Exec': exec_cmd = re.sub(r'%[fFuUiIdDnNoNvkU]', '', v).strip()
                        elif k == 'Icon': icon = v
                        elif k == 'NoDisplay' and v.lower() == 'true': nodisplay = True
                if name and exec_cmd and not nodisplay:
                    if name not in seen:
                        seen.add(name)
                        apps.append({'name': name, 'exec': exec_cmd, 'icon': icon or 'application-x-executable'})
        except: pass
apps.sort(key=lambda x: x['name'].lower())
print(json.dumps(apps))
"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (!data) return;
                try {
                    allApps = JSON.parse(data.trim());
                    filter("");
                } catch(e) {}
            }
        }
    }

    // IPC Handler to toggle from bindings
    IpcHandler {
        target: "spotlight"
        function toggle(): void {
            spotlightWindow.toggle();
        }
    }

    // Outer Container
    Rectangle {
        id: mainLayout
        width: parent.width
        height: childrenRect.height + (spotlightWindow.filteredItems.length > 0 ? 16 : 0)
        radius: 14
        color: Style.crust
        border.color: Style.surface1
        border.width: 1.5

        Column {
            width: parent.width
            spacing: 0

            // Search Header
            Row {
                width: parent.width
                height: 56
                spacing: 16
                leftPadding: 20
                rightPadding: 20

                Text {
                    text: "search"
                    color: Style.lavender
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchText
                    width: parent.width - 76
                    height: parent.height
                    color: Style.text
                    font.family: Style.fontFamily
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: true
                    selectByMouse: true

                    onActiveFocusChanged: {
                        if (!activeFocus && spotlightWindow.visible) {
                            spotlightWindow.visible = false;
                        }
                    }

                    Text {
                        text: "Search"
                        color: Style.overlay0
                        font.family: parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        visible: parent.text.length === 0
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                    }

                    onTextChanged: {
                        spotlightWindow.filter(text);
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down) {
                            if (spotlightWindow.filteredItems.length > 0) {
                                spotlightWindow.selectedIndex = (spotlightWindow.selectedIndex + 1) % spotlightWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (spotlightWindow.filteredItems.length > 0) {
                                spotlightWindow.selectedIndex = (spotlightWindow.selectedIndex - 1 + spotlightWindow.filteredItems.length) % spotlightWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (spotlightWindow.filteredItems.length > 0 && spotlightWindow.selectedIndex >= 0 && spotlightWindow.selectedIndex < spotlightWindow.filteredItems.length) {
                                var item = spotlightWindow.filteredItems[spotlightWindow.selectedIndex];
                                if (item.type === "calc") {
                                    Quickshell.execDetached(["sh", "-c", "echo -n '" + item.value + "' | wl-copy"]);
                                } else {
                                    Quickshell.execDetached(["sh", "-c", item.exec]);
                                    if (item.type === "web") {
                                        Hyprland.dispatch("hl.dsp.focus({ workspace = 1 })");
                                    }
                                }
                                spotlightWindow.visible = false;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            spotlightWindow.visible = false;
                            event.accepted = true;
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                width: parent.width
                height: 1
                color: Style.surface0
                visible: spotlightWindow.filteredItems.length > 0
            }

            // Results List
            ListView {
                id: resultsList
                width: parent.width
                height: count * 44
                model: spotlightWindow.filteredItems
                interactive: false
                visible: count > 0

                // Spacing around list items
                topMargin: 8
                bottomMargin: 8

                delegate: Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    id: delegateBg
                    height: 44
                    color: index === spotlightWindow.selectedIndex ? Style.surface1 : "transparent"
                    radius: 8
                    border.color: index === spotlightWindow.selectedIndex ? Style.surface2 : "transparent"
                    border.width: 1

                    property int horizontalPadding: 8
                    x: horizontalPadding
                    width: parent.width - (horizontalPadding * 2)

                    Item {
                      width: parent.width
                      height: parent.height

                       // Icon Container
                       Item {
                         id: itemIcon
                         width: 20
                         height: 20
                         anchors.left: parent.left
                         anchors.leftMargin: 14
                         anchors.verticalCenter: parent.verticalCenter

                          // Icon (Material Symbol for non-apps)
                          Text {
                            text: modelData ? modelData.icon : ""
                            color: index === spotlightWindow.selectedIndex ? Style.mauve : Style.subtext0
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                            visible: !modelData || modelData.type !== "app"
                          }

                          // Icon (Image/IconImage for apps)
                          IconImage {
                            source: (modelData && modelData.type === "app" && modelData.icon) ? (modelData.icon.indexOf("/") === 0 ? "file://" + modelData.icon : Quickshell.iconPath(modelData.icon)) : ""
                            width: 20
                            height: 20
                            anchors.centerIn: parent
                            visible: modelData && modelData.type === "app"
                          }
                       }

                      // App / Item Title
                      Text {
                        text: modelData.name
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 14
                        font.weight: index === spotlightWindow.selectedIndex ? Font.Bold : Font.Normal
                        anchors.left: itemIcon.right
                        anchors.leftMargin: 12
                        anchors.right: descText.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                      }

                      // Category Description
                      Text {
                        id: descText
                        text: modelData.desc
                        color: Style.overlay1
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      onEntered: spotlightWindow.selectedIndex = index
                      onClicked: {
                        if (modelData.type === "calc") {
                          Quickshell.execDetached(["sh", "-c", "echo -n '" + modelData.value + "' | wl-copy"]);
                        } else {
                          Quickshell.execDetached(["sh", "-c", modelData.exec]);
                          if (modelData.type === "web") {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = 1 })");
                          }
                        }
                        spotlightWindow.visible = false;
                      }
                    }
                  }
                }
              }
            }
          }
