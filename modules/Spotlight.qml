import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

PanelWindow {
    id: spotlightWindow

    property var allApps: []
    property var filteredItems: []
    property int selectedIndex: 0
    property bool onlyAppsMode: false

    function toggle() {
        visible = !visible;
        if (visible) {
            searchText.text = "";
            searchText.forceActiveFocus();
            onlyAppsMode = false;
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
        if (!spotlightWindow.onlyAppsMode) {
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
        }

        // 2. Matching Apps
        var queryLower = query.toLowerCase();
        var appMatches = [];
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            if (app.name.toLowerCase().indexOf(queryLower) !== -1 || app.exec.toLowerCase().indexOf(queryLower) !== -1) {
                appMatches.push({
                    name: app.name,
                    desc: "Application",
                    type: "app",
                    exec: app.exec,
                    icon: app.icon
                });
            }
        }
        items = items.concat(appMatches.slice(0, 5));

        // 3. Search Google on Zen Browser
        if (!spotlightWindow.onlyAppsMode) {
            items.push({
                name: "Search Google for '" + query + "'",
                desc: "Search in Zen Browser",
                type: "web",
                exec: 'zen-browser "https://www.google.com/search?q=' + encodeURIComponent(query) + '"',
                icon: "language"
            });
        }

        filteredItems = items;
        selectedIndex = 0;
    }

    // Window Setup
    anchors.top: true
    anchors.left: false
    anchors.right: false
    implicitWidth: 600
    implicitHeight: mainLayout.height

    // Positioned using a fixed height reference of 100 to prevent vertical jumping and sit slightly lower
    margins.top: screen ? (screen.height - 100) / 3.5 : 150

    color: "transparent"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: false

    // App List Fetcher
    Process {
        id: appFetcher
        command: ["python3", "-c", "
import os, glob, json
icon_dict = {}
if os.path.exists('/usr/share/pixmaps'):
    for file in os.listdir('/usr/share/pixmaps'):
        name, ext = os.path.splitext(file)
        if ext.lower() in ['.png', '.svg', '.xpm']:
            icon_dict[name.lower()] = os.path.join('/usr/share/pixmaps', file)

search_patterns = [
    '/usr/share/icons/*/apps',
    '/usr/share/icons/*/*/apps',
    os.path.expanduser('~/.local/share/icons/*/apps'),
    os.path.expanduser('~/.local/share/icons/*/*/apps'),
]
for pattern in search_patterns:
    for apps_dir in glob.glob(pattern):
        if os.path.isdir(apps_dir):
            for file in os.listdir(apps_dir):
                name, ext = os.path.splitext(file)
                if ext.lower() in ['.png', '.svg', '.xpm']:
                    name_lower = name.lower()
                    if name_lower not in icon_dict:
                        icon_dict[name_lower] = os.path.join(apps_dir, file)

def resolve_icon(icon):
    if not icon: return ''
    if icon.startswith('/') or icon.startswith('~'):
        return os.path.expanduser(icon)
    res = icon_dict.get(icon.lower(), '')
    if not res:
        for k, v in icon_dict.items():
            if icon.lower() in k:
                return v
    return res

apps = []
paths = ['/usr/share/applications/*.desktop', os.path.expanduser('~/.local/share/applications/*.desktop')]
seen = set()
for p in paths:
    for fpath in glob.glob(p):
        try:
            with open(fpath, 'r', errors='ignore') as f:
                lines = f.readlines()
            name, exec_cmd, icon, nodisplay = None, None, None, False
            in_entry = False
            for line in lines:
                line = line.strip()
                if line == '[Desktop Entry]':
                    in_entry = True
                    continue
                if line.startswith('[') and line.endswith(']'):
                    in_entry = False
                if in_entry and '=' in line:
                    k, v = line.split('=', 1)
                    k, v = k.strip(), v.strip()
                    if k == 'Name': name = v
                    elif k == 'Exec': exec_cmd = v
                    elif k == 'Icon': icon = v
                    elif k == 'NoDisplay' and v.lower() == 'true': nodisplay = True
            if name and exec_cmd and not nodisplay:
                if name not in seen:
                    seen.add(name)
                    for code in ['%f', '%F', '%u', '%U', '%i', '%d', '%n', '%N', '%k', '%v', '%m']:
                        exec_cmd = exec_cmd.replace(code, '')
                    exec_cmd = exec_cmd.strip()
                    apps.append({'name': name, 'exec': exec_cmd, 'icon': resolve_icon(icon)})
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
        height: searchRow.height + (spotlightWindow.filteredItems.length > 0 ? (divider.height + listContainer.height) : 0)
        radius: 24
        color: Style.crust
        border.color: Style.surface1
        border.width: 1.5
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // Search Header
            Row {
                id: searchRow
                width: parent.width
                height: 56
                spacing: 12
                leftPadding: 20
                rightPadding: 20

                Text {
                    text: "search"
                    color: Style.lavender
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Wrapper row for tag pill and text input
                Row {
                    id: inputWrapper
                    width: parent.width - 56
                    height: parent.height
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    // Tag Pill representing "Applications Only" filter mode
                    Rectangle {
                        id: appTag
                        height: 28
                        color: Style.surface1
                        border.color: Style.mauve
                        border.width: 1
                        radius: 14
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true

                        // Animated width and opacity
                        width: spotlightWindow.onlyAppsMode ? (tagText.implicitWidth + 28) : 0
                        opacity: spotlightWindow.onlyAppsMode ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "apps"
                                color: Style.mauve
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: tagText
                                text: "Applications"
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    TextInput {
                        id: searchText
                        width: parent.width - (appTag.visible ? appTag.width + parent.spacing : 0)
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
                            if (event.key === Qt.Key_Tab) {
                                spotlightWindow.onlyAppsMode = !spotlightWindow.onlyAppsMode;
                                spotlightWindow.filter(text);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backspace) {
                                if (text.length === 0 && spotlightWindow.onlyAppsMode) {
                                    spotlightWindow.onlyAppsMode = false;
                                    spotlightWindow.filter(text);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Down) {
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
                                    spotlightWindow.visible = false;
                                    try {
                                        if (item.type === "calc") {
                                            Quickshell.execDetached(["sh", "-c", "echo -n '" + item.value + "' | wl-copy"]);
                                        } else {
                                            Quickshell.execDetached(["sh", "-c", item.exec]);
                                            if (item.type === "web") {
                                                Hyprland.dispatch("hl.dsp.focus({ workspace = 1 })");
                                            }
                                        }
                                    } catch (e) {
                                        console.log("Error running search item:", e);
                                    }
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                spotlightWindow.visible = false;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                id: divider
                width: parent.width
                height: 1
                color: Style.surface0
                visible: spotlightWindow.filteredItems.length > 0
            }

            // Results List Container
            Item {
                id: listContainer
                width: parent.width
                height: resultsList.height + 16
                visible: spotlightWindow.filteredItems.length > 0

                ListView {
                    id: resultsList
                    width: parent.width
                    y: 8
                    spacing: 6
                    model: spotlightWindow.filteredItems
                    interactive: false

                    // Compute clean height with spacing included
                    height: spotlightWindow.filteredItems.length > 0 ? (spotlightWindow.filteredItems.length * 48 + (spotlightWindow.filteredItems.length - 1) * spacing) : 0

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    populate: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Rectangle {
                        id: delegateBg
                        height: 48
                        color: index === spotlightWindow.selectedIndex ? Style.surface1 : "transparent"
                        radius: 8
                        border.color: index === spotlightWindow.selectedIndex ? Style.surface2 : "transparent"
                        border.width: 1
anchors.horizontalCenter: parent.horizontalCenter

                        property int horizontalPadding: 8
                        x: horizontalPadding
                        width: parent.width - (horizontalPadding * 2)

                        Item {
                            anchors.fill: parent

                            // Icon Container
                            Item {
                                id: iconContainer
                                width: 24
                                height: 24
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter

                                // Actual App Icon Image
                                Image {
                                    id: appIconImg
                                    anchors.fill: parent
                                    source: {
                                        if (modelData.type !== "app") return "";
                                        var icon = modelData.icon;
                                        if (!icon) return "";
                                        return "file://" + icon;
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    visible: modelData.type === "app" && source !== ""
                                }

                                // Material Symbol Icon for Calc / Web or Fallback for App
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (modelData.type === "calc") return "calculate";
                                        if (modelData.type === "web") return "language";
                                        return "apps";
                                    }
                                    color: index === spotlightWindow.selectedIndex ? Style.mauve : Style.subtext0
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                    visible: modelData.type !== "app" || appIconImg.status === Image.Error || appIconImg.status === Image.Null
                                }
                            }

                            // App / Item Title
                            Text {
                                text: modelData.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Normal
                                anchors.left: iconContainer.right
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
                                spotlightWindow.visible = false;
                                try {
                                    if (modelData.type === "calc") {
                                        Quickshell.execDetached(["sh", "-c", "echo -n '" + modelData.value + "' | wl-copy"]);
                                    } else {
                                      Quickshell.execDetached(["sh", "-c", modelData.exec]);
                                      if (modelData.type === "web") {
                                        Hyprland.dispatch("hl.dsp.focus({ workspace = 1 })");
                                      }
                                    }
                                  } catch (e) {
                                    console.log("Error clicking search item:", e);
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
