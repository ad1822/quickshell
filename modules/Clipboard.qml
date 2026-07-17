import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io as QsIo

PanelWindow {
    id: clipboardWindow

    property var allClipboardItems: []
    property var filteredItems: []
    property int selectedIndex: 0

    function toggle() {
        visible = !visible;
        if (visible) {
            searchText.text = "";
            searchText.forceActiveFocus();
            allClipboardItems = [];
            filteredItems = [];
            selectedIndex = 0;
            cliphistFetcher.running = true;
        } else {
            cliphistFetcher.running = false;
        }
    }

    function filter(text) {
        var query = text.trim().toLowerCase();
        var items = [];

        // Add Wipe Clipboard option at the top if search is empty or matches "wipe"
        if (query === "" || "wipe clipboard history".indexOf(query) !== -1) {
            items.push({
                id: "wipe",
                text: "Wipe Clipboard History",
                isWipe: true,
                isImage: false,
                imageType: ""
            });
        }

        var matches = [];
        for (var i = 0; i < allClipboardItems.length; i++) {
            var item = allClipboardItems[i];
            if (item.text.toLowerCase().indexOf(query) !== -1) {
                matches.push({
                    id: item.id,
                    text: item.text,
                    isWipe: false,
                    isImage: item.isImage,
                    imageType: item.imageType
                });
            }
        }
        
        items = items.concat(matches);
        filteredItems = items;
        selectedIndex = 0;
    }

    // Window Setup
    anchors.top: true
    anchors.left: false
    anchors.right: false
    implicitWidth: 520
    implicitHeight: mainLayout.height

    margins.top: screen ? (screen.height - 100) / 3.5 : 150

    color: "transparent"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: false

    QsIo.Process {
        id: cliphistFetcher
        command: ["python3", "-c", "import subprocess, json\ntry:\n    out = subprocess.check_output(['cliphist', 'list'], text=True)\n    lines = []\n    for line in out.splitlines():\n        parts = line.split('\\t', 1)\n        if len(parts) == 2:\n            text = parts[1].strip()\n            is_img = text.startswith('[[ binary data') and any(ext in text.lower() for ext in ['png', 'jpg', 'jpeg', 'bmp'])\n            img_type = 'image'\n            if is_img:\n                for ext in ['png', 'jpg', 'jpeg', 'bmp']:\n                    if ext in text.lower():\n                        img_type = ext.upper()\n                        break\n            lines.append({'id': parts[0].strip(), 'text': text, 'isImage': is_img, 'imageType': img_type})\n    print(json.dumps(lines))\nexcept:\n    print('[]')"]
        running: false
        stdout: QsIo.SplitParser {
            onRead: (data) => {
                if (!data) return;
                try {
                    allClipboardItems = JSON.parse(data.trim());
                    filter(searchText.text);
                } catch(e) {}
            }
        }
    }

    // Outer Container
    Rectangle {
        id: mainLayout
        width: parent.width
        height: searchRow.height + (clipboardWindow.filteredItems.length > 0 ? (divider.height + listContainer.height) : 0)
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
                    text: "content_paste"
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
                        if (!activeFocus && clipboardWindow.visible) {
                            clipboardWindow.visible = false;
                        }
                    }

                    Text {
                        text: "Search Clipboard History..."
                        color: Style.overlay0
                        font.family: parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        visible: parent.text.length === 0
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                    }

                    onTextChanged: {
                        clipboardWindow.filter(text);
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            if (clipboardWindow.filteredItems.length > 0) {
                                if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                                    clipboardWindow.selectedIndex = (clipboardWindow.selectedIndex - 1 + clipboardWindow.filteredItems.length) % clipboardWindow.filteredItems.length;
                                } else {
                                    clipboardWindow.selectedIndex = (clipboardWindow.selectedIndex + 1) % clipboardWindow.filteredItems.length;
                                }
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (clipboardWindow.filteredItems.length > 0) {
                                clipboardWindow.selectedIndex = (clipboardWindow.selectedIndex + 1) % clipboardWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (clipboardWindow.filteredItems.length > 0) {
                                clipboardWindow.selectedIndex = (clipboardWindow.selectedIndex - 1 + clipboardWindow.filteredItems.length) % clipboardWindow.filteredItems.length;
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            if (clipboardWindow.filteredItems.length > 0 && clipboardWindow.selectedIndex >= 0 && clipboardWindow.selectedIndex < clipboardWindow.filteredItems.length) {
                                var item = clipboardWindow.filteredItems[clipboardWindow.selectedIndex];
                                clipboardWindow.visible = false;
                                try {
                                    if (item.isWipe) {
                                        Quickshell.execDetached(["sh", "-c", "cliphist wipe && wl-copy -c"]);
                                    } else {
                                        Quickshell.execDetached(["sh", "-c", "cliphist decode " + item.id + " | wl-copy"]);
                                    }
                                } catch (e) {
                                    console.log("Error running clipboard item:", e);
                                }
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            clipboardWindow.visible = false;
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
                visible: clipboardWindow.filteredItems.length > 0
            }

            // Results List Container
            Item {
                id: listContainer
                width: parent.width
                height: resultsList.height + 16
                visible: clipboardWindow.filteredItems.length > 0

                ListView {
                    id: resultsList
                    width: parent.width
                    y: 8
                    spacing: 6
                    model: clipboardWindow.filteredItems
                    interactive: true
                    clip: true
                    currentIndex: clipboardWindow.selectedIndex
                    
                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    height: {
                        var count = Math.min(clipboardWindow.filteredItems.length, 5);
                        if (count <= 0) return 0;
                        var totalHeight = 0;
                        for (var i = 0; i < count; i++) {
                            var item = clipboardWindow.filteredItems[i];
                            totalHeight += (item && item.isImage) ? 80 : 48;
                        }
                        return totalHeight + (count - 1) * spacing;
                    }

                    delegate: Rectangle {
                        id: delegateBg
                        height: modelData.isImage ? 80 : 48
                        color: index === clipboardWindow.selectedIndex ? Style.surface1 : "transparent"
                        radius: 8
                        border.color: index === clipboardWindow.selectedIndex ? Style.surface2 : "transparent"
                        border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        property int horizontalPadding: 8
                        x: horizontalPadding
                        width: parent.width - (horizontalPadding * 2)

                        property string imagePath: ""

                        QsIo.Process {
                            id: decoder
                            command: ["sh", "-c", "mkdir -p /tmp/quickshell_clip && cliphist decode " + modelData.id + " > /tmp/quickshell_clip/" + modelData.id + ".png"]
                            running: modelData.isImage && delegateBg.imagePath === ""
                            onExited: (exitCode) => {
                                delegateBg.imagePath = "file:///tmp/quickshell_clip/" + modelData.id + ".png"
                            }
                        }

                        Item {
                            anchors.fill: parent

                            // Icon (Only for Wipe)
                            Text {
                                id: wipeIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: "delete_sweep"
                                color: Style.red
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                visible: modelData.isWipe
                            }

                            // Thumbnail Image (Only for images)
                            Image {
                                id: thumbImg
                                source: delegateBg.imagePath
                                height: 64
                                width: 100
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.isImage && delegateBg.imagePath !== ""
                            }

                            // Clipboard text / Label
                            Text {
                                text: modelData.isImage ? "Image (" + modelData.imageType + ")" : modelData.text
                                color: modelData.isWipe ? Style.red : Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Normal
                                anchors.left: modelData.isWipe ? wipeIcon.right : (thumbImg.visible ? thumbImg.right : parent.left)
                                anchors.leftMargin: (modelData.isWipe || thumbImg.visible) ? 12 : 14
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: clipboardWindow.selectedIndex = index
                            onClicked: {
                                clipboardWindow.visible = false;
                                try {
                                    if (modelData.isWipe) {
                                        Quickshell.execDetached(["sh", "-c", "cliphist wipe && wl-copy -c"]);
                                    } else {
                                        Quickshell.execDetached(["sh", "-c", "cliphist decode " + modelData.id + " | wl-copy"]);
                                    }
                                } catch (e) {
                                    console.log("Error clicking clipboard item:", e);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
