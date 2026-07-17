import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io as QsIo

PanelWindow {
    id: passWindow

    property string storeDir: "/home/ad/work/side/pass"
    property string currentPath: "/home/ad/work/side/pass"
    property var allItems: []
    property var recursiveItems: []
    property var filteredItems: []
    property int selectedIndex: 0
    property bool searchMode: false

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            // Run pending checker
            pendingChecker.running = true;
        }
    }

    function openWindow() {
        visible = true;
        searchText.text = "";
        searchText.forceActiveFocus();
        currentPath = storeDir;
        searchMode = false;
        allItems = [];
        recursiveItems = [];
        filteredItems = [];
        selectedIndex = 0;
        listFetcher.running = true;
        recursiveFetcher.running = true;
    }

    function filter(text) {
        var query = text.trim().toLowerCase();
        if (query === "") {
            if (passWindow.searchMode) {
                filteredItems = recursiveItems;
            } else {
                filteredItems = allItems;
            }
            selectedIndex = 0;
            return;
        }

        var matches = [];
        var listToSearch = recursiveItems;
        for (var i = 0; i < listToSearch.length; i++) {
            var item = listToSearch[i];
            if (item.name.toLowerCase().indexOf(query) !== -1) {
                matches.push(item);
            }
        }
        filteredItems = matches;
        selectedIndex = 0;
    }

    // Window Setup
    anchors.top: true
    anchors.left: false
    anchors.right: false
    implicitWidth: 550
    implicitHeight: mainLayout.height

    margins.top: screen ? (screen.height - 100) / 3.5 : 150

    color: "transparent"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: false

    // Pending Checker Process
    QsIo.Process {
        id: pendingChecker
        command: ["sh", "-c", "if [ -f /tmp/pass-rofi-pending ]; then secret=$(cat /tmp/pass-rofi-pending); pass show \"$secret\" | head -n1 | wl-copy && (sleep 45 && [ \"$(wl-paste 2>/dev/null)\" = \"$(pass show \"$secret\" | head -n1)\" ] && wl-copy -c) & echo \"COPIED:$secret\"; else echo \"NONE\"; fi"]
        running: false
        stdout: QsIo.SplitParser {
            onRead: (data) => {
                if (!data) return;
                var res = data.trim();
                if (res.startsWith("COPIED:")) {
                    var secret = res.substring(7);
                    Quickshell.execDetached(["notify-send", "--expire-time=10000", "-a", "Pass", "Password Copied", secret]);
                    Quickshell.execDetached(["sh", "-c", "rm -f /tmp/pass-rofi-pending"]);
                } else if (res === "NONE") {
                    passWindow.openWindow();
                }
            }
        }
    }

    // List Fetcher Process (Directories/Files)
    QsIo.Process {
        id: listFetcher
        command: ["python3", "-c", "import os, json, sys\nstore = sys.argv[1]\ncurrent = sys.argv[2]\nentries = []\nif current != store:\n    entries.append({'name': '⬅ Back', 'type': 'back'})\nentries.append({'name': '🔍 Search entire store', 'type': 'search_action'})\ntry:\n    items = os.listdir(current)\n    dirs = []\n    files = []\n    for item in items:\n        if item.startswith('.'): continue\n        full = os.path.join(current, item)\n        if os.path.isdir(full):\n            dirs.append({'name': item + '/', 'type': 'dir', 'path': full})\n        elif item.endswith('.gpg'):\n            name = item[:-4]\n            rel = os.path.relpath(full, store)[:-4]\n            files.append({'name': name, 'type': 'file', 'path': rel})\n    dirs.sort(key=lambda x: x['name'].lower())\n    files.sort(key=lambda x: x['name'].lower())\n    entries.extend(dirs)\n    entries.extend(files)\nexcept:\n    pass\nprint(json.dumps(entries))", passWindow.storeDir, passWindow.currentPath]
        running: false
        stdout: QsIo.SplitParser {
            onRead: (data) => {
                if (!data) return;
                try {
                    allItems = JSON.parse(data.trim());
                    filter(searchText.text);
                } catch(e) {}
            }
        }
    }

    // Recursive Fetcher Process (Search Cache)
    QsIo.Process {
        id: recursiveFetcher
        command: ["python3", "-c", "import os, json, sys\nstore = sys.argv[1]\nentries = []\nfor root, dirs, files in os.walk(store):\n    dirs[:] = [d for d in dirs if not d.startswith('.')]\n    for file in files:\n        if file.endswith('.gpg'):\n            full = os.path.join(root, file)\n            rel = os.path.relpath(full, store)[:-4]\n            entries.append({'name': rel, 'type': 'file', 'path': rel})\nentries.sort(key=lambda x: x['name'].lower())\nprint(json.dumps(entries))", passWindow.storeDir]
        running: false
        stdout: QsIo.SplitParser {
            onRead: (data) => {
                if (!data) return;
                try {
                    recursiveItems = JSON.parse(data.trim());
                    filter(searchText.text);
                } catch(e) {}
            }
        }
    }


    // Outer Container
    Rectangle {
        id: mainLayout
        width: parent.width
        height: searchRow.height + (passWindow.filteredItems.length > 0 ? (divider.height + listContainer.height) : 0)
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
                    text: "vpn_key"
                    color: Style.lavender
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchText
                    width: parent.width - 56
                    height: parent.height
                    color: Style.text
                    font.family: Style.fontFamily
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: true
                    selectByMouse: true

                    onActiveFocusChanged: {
                        if (!activeFocus && passWindow.visible) {
                            passWindow.visible = false;
                        }
                    }

                    Text {
                        text: passWindow.searchMode ? "Search Entire Password Store..." : "Search " + (passWindow.currentPath === passWindow.storeDir ? "Store" : passWindow.currentPath.substring(passWindow.currentPath.lastIndexOf('/') + 1)) + "..."
                        color: Style.overlay0
                        font.family: parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        visible: parent.text.length === 0
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                    }

                    onTextChanged: {
                        passWindow.filter(text);
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            if (passWindow.filteredItems.length > 0) {
                                if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                                    passWindow.selectedIndex = (passWindow.selectedIndex - 1 + passWindow.filteredItems.length) % passWindow.filteredItems.length;
                                } else {
                                    passWindow.selectedIndex = (passWindow.selectedIndex + 1) % passWindow.filteredItems.length;
                                }
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (passWindow.filteredItems.length > 0) {
                                passWindow.selectedIndex = (passWindow.selectedIndex + 1) % passWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (passWindow.filteredItems.length > 0) {
                                passWindow.selectedIndex = (passWindow.selectedIndex - 1 + passWindow.filteredItems.length) % passWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (passWindow.filteredItems.length > 0 && passWindow.selectedIndex >= 0 && passWindow.selectedIndex < passWindow.filteredItems.length) {
                                var item = passWindow.filteredItems[passWindow.selectedIndex];
                                if (item.type === "back") {
                                    passWindow.currentPath = passWindow.currentPath.substring(0, passWindow.currentPath.lastIndexOf('/'));
                                    searchText.text = "";
                                    passWindow.listFetcher.running = true;
                                } else if (item.type === "search_action") {
                                    passWindow.searchMode = true;
                                    searchText.text = "";
                                    passWindow.filter("");
                                } else if (item.type === "dir") {
                                    passWindow.currentPath = item.path;
                                    searchText.text = "";
                                    passWindow.listFetcher.running = true;
                                } else if (item.type === "file") {
                                    passWindow.visible = false;
                                    var username = item.path.substring(item.path.lastIndexOf('/') + 1);
                                    // Copy Username
                                    Quickshell.execDetached(["sh", "-c", "printf '%s' \"" + username + "\" | wl-copy"]);
                                    // Save pending secret path
                                    Quickshell.execDetached(["sh", "-c", "printf '%s' \"" + item.path + "\" > /tmp/pass-rofi-pending"]);
                                    // Notify
                                    Quickshell.execDetached(["notify-send", "--expire-time=10000", "-a", "Pass", "Username Copied", "Run shortcut again for password"]);
                                }
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            passWindow.visible = false;
                            event.accepted = true;
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
                visible: passWindow.filteredItems.length > 0
            }

            // Results List Container
            Item {
                id: listContainer
                width: parent.width
                height: resultsList.height + 16
                visible: passWindow.filteredItems.length > 0

                ListView {
                    id: resultsList
                    width: parent.width
                    y: 8
                    spacing: 6
                    model: passWindow.filteredItems
                    interactive: true
                    clip: true
                    currentIndex: passWindow.selectedIndex

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    height: {
                        var count = Math.min(passWindow.filteredItems.length, 6);
                        return count > 0 ? (count * 48 + (count - 1) * spacing) : 0;
                    }

                    delegate: Rectangle {
                        id: delegateBg
                        height: 48
                        color: index === passWindow.selectedIndex ? Style.surface1 : "transparent"
                        radius: 8
                        border.color: index === passWindow.selectedIndex ? Style.surface2 : "transparent"
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

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (modelData.type === "back") return "arrow_back";
                                        if (modelData.type === "search_action") return "search";
                                        if (modelData.type === "dir") return "folder";
                                        return "vpn_key";
                                    }
                                    color: {
                                        if (modelData.type === "back") return Style.overlay1;
                                        if (modelData.type === "search_action") return Style.mauve;
                                        if (modelData.type === "dir") return Style.blue;
                                        return index === passWindow.selectedIndex ? Style.lavender : Style.subtext0;
                                    }
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20
                                }
                            }

                            // Text Label
                            Text {
                                text: modelData.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Normal
                                anchors.left: iconContainer.right
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: passWindow.selectedIndex = index
                            onClicked: {
                                if (modelData.type === "back") {
                                    passWindow.currentPath = passWindow.currentPath.substring(0, passWindow.currentPath.lastIndexOf('/'));
                                    searchText.text = "";
                                    passWindow.listFetcher.running = true;
                                } else if (modelData.type === "search_action") {
                                    passWindow.searchMode = true;
                                    searchText.text = "";
                                    passWindow.filter("");
                                } else if (modelData.type === "dir") {
                                    passWindow.currentPath = modelData.path;
                                    searchText.text = "";
                                    passWindow.listFetcher.running = true;
                                } else if (modelData.type === "file") {
                                    passWindow.visible = false;
                                    var username = modelData.path.substring(modelData.path.lastIndexOf('/') + 1);
                                    Quickshell.execDetached(["sh", "-c", "printf '%s' \"" + username + "\" | wl-copy"]);
                                    Quickshell.execDetached(["sh", "-c", "printf '%s' \"" + modelData.path + "\" > /tmp/pass-rofi-pending"]);
                                    Quickshell.execDetached(["notify-send", "--expire-time=10000", "-a", "Pass", "Username Copied", "Run shortcut again for password"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
