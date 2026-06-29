import "../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io as QsIo
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: barWindow

    property bool modulesExpanded: true
    property bool barExpanded: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    margins.top: barWindow.barExpanded ? 0 : 4
    color: "transparent"

    Rectangle {
        id: barBg

        anchors.centerIn: parent
        height: 30
        color: "#11111b"
        width: barWindow.barExpanded ? parent.width : (barClock.width + 10)
        radius: barWindow.barExpanded ? 0 : 6

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on radius {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

    }

    Clock {
        id: barClock

        anchors.centerIn: barBg
        height: barBg.height
        barExpanded: barWindow.barExpanded

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: barWindow.barExpanded = !barWindow.barExpanded
        }

    }

    Row {
        id: rightContainer

        anchors.right: parent.right
        anchors.rightMargin: barWindow.barExpanded ? 0 : -500
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 6
        layoutDirection: Qt.RightToLeft
        opacity: barWindow.barExpanded ? 1 : 0

        Battery {
            id: barBatteryWidget

            height: parent.height
            onHovered: (isHovered) => {
                if (isHovered) {
                    battCloseTimer.stop();
                    battOpenTimer.start();
                } else {
                    battOpenTimer.stop();
                    battCloseTimer.start();
                }
            }
        }

        WifiIcon {
            id: wifiIconWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    wifiCloseTimer.stop();
                    wifiOpenTimer.start();
                } else {
                    wifiOpenTimer.stop();
                    wifiCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Volume {
            id: barVolumeWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    qsCloseTimer.stop();
                    qsOpenTimer.start();
                } else {
                    qsOpenTimer.stop();
                    qsCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Brightness {
            id: barBrightnessWidget

            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    qsCloseTimer.stop();
                    qsOpenTimer.start();
                } else {
                    qsOpenTimer.stop();
                    qsCloseTimer.start();
                }
            }
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        WallpaperButton {
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1
            height: 12
            color: Style.surface1
            anchors.verticalCenter: parent.verticalCenter
        }

        Player {
            id: playerWidget

            forceVisible: playerPopupLoader.active
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered && playerWidget.activePlayer !== null) {
                    playerCloseTimer.stop();
                    playerOpenTimer.start();
                } else {
                    playerOpenTimer.stop();
                    playerCloseTimer.start();
                }
            }
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    Workspaces {
        id: workspacesWidget

        anchors.left: parent.left
        anchors.leftMargin: barWindow.barExpanded ? 8 : -300
        anchors.verticalCenter: parent.verticalCenter
        opacity: barWindow.barExpanded ? 1 : 0

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    // --- Hamburger Button ---
    Text {
        id: hamburgerButton

        anchors.left: workspacesWidget.right
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: barWindow.modulesExpanded ? "menu_open" : "menu"
        color: hamburgerMouse.containsMouse ? Style.text : (barWindow.modulesExpanded ? Style.overlay2 : Style.overlay1)
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.bold: true
        opacity: barWindow.barExpanded ? 1 : 0

        MouseArea {
            id: hamburgerMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: barWindow.modulesExpanded = !barWindow.modulesExpanded
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }

        }

    }

    // --- CPU Popup Timers & Loader ---
    Timer {
        id: openTimer

        interval: 300 // Mouse must stay 300ms to open
        repeat: false
        onTriggered: {
            closeTimer.stop();
            popupLoader.active = true;
        }
    }

    Timer {
        id: closeTimer

        interval: 200
        repeat: false
        onTriggered: popupLoader.active = false
    }

    // --- Memory Popup Timers ---
    Timer {
        id: memOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            memCloseTimer.stop();
            memPopupLoader.active = true;
        }
    }

    Timer {
        id: memCloseTimer

        interval: 200
        repeat: false
        onTriggered: memPopupLoader.active = false
    }

    // --- Network Popup Timers ---
    Timer {
        id: netOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            netCloseTimer.stop();
            netPopupLoader.active = true;
        }
    }

    Timer {
        id: netCloseTimer

        interval: 200
        repeat: false
        onTriggered: netPopupLoader.active = false
    }

    // --- Wifi Popup Timers & Loader ---
    Timer {
        id: wifiOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            wifiCloseTimer.stop();
            wifiPopupLoader.active = true;
        }
    }

    Timer {
        id: wifiCloseTimer

        interval: 200
        repeat: false
        onTriggered: wifiPopupLoader.active = false
    }

    Loader {
        id: wifiPopupLoader

        active: false
        sourceComponent: wifiPopupComponent
    }

    // --- Battery Popup Timers & Loader ---
    Timer {
        id: battOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            battCloseTimer.stop();
            if (battPopupLoader.active && battPopupLoader.item)
                battPopupLoader.item.cancelClose();
            else
                battPopupLoader.active = true;
        }
    }

    Timer {
        id: battCloseTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (battPopupLoader.item)
                battPopupLoader.item.closePopup();
            else
                battPopupLoader.active = false;
        }
    }

    Loader {
        id: battPopupLoader

        active: false
        sourceComponent: battPopupComponent
    }

    // --- Player Popup Timers & Loader ---
    Timer {
        id: playerOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            playerCloseTimer.stop();
            if (playerPopupLoader.active && playerPopupLoader.item)
                playerPopupLoader.item.cancelClose();
            else
                playerPopupLoader.active = true;
        }
    }

    Timer {
        id: playerCloseTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (playerPopupLoader.item)
                playerPopupLoader.item.closePopup();
            else
                playerPopupLoader.active = false;
        }
    }

    Loader {
        id: playerPopupLoader

        active: false
        sourceComponent: playerPopupComponent
    }

    // --- Quick Settings (Volume/Brightness) Popup Timers & Loader ---
    Timer {
        id: qsOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            qsCloseTimer.stop();
            if (qsPopupLoader.active && qsPopupLoader.item)
                qsPopupLoader.item.cancelClose();
            else
                qsPopupLoader.active = true;
        }
    }

    Timer {
        id: qsCloseTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (qsPopupLoader.item)
                qsPopupLoader.item.closePopup();
            else
                qsPopupLoader.active = false;
        }
    }

    Loader {
        id: qsPopupLoader

        active: false
        sourceComponent: qsPopupComponent
    }

    // --- Smoothly Collapsible Modules Container ---
    Item {
        id: modulesContainer

        property int marginVal: barWindow.modulesExpanded ? 10 : 0

        anchors.left: hamburgerButton.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        clip: true
        anchors.leftMargin: marginVal
        width: barWindow.modulesExpanded ? (netWidget.x + netWidget.width) : 0
        opacity: (barWindow.barExpanded && barWindow.modulesExpanded) ? 1 : 0

        Process {
            id: cpuWidget

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    closeTimer.stop();
                    openTimer.start();
                } else {
                    openTimer.stop();
                    closeTimer.start();
                }
            }
        }

        Memory {
            id: memWidget

            anchors.left: cpuWidget.right
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    memCloseTimer.stop();
                    memOpenTimer.start();
                } else {
                    memOpenTimer.stop();
                    memCloseTimer.start();
                }
            }
        }

        Rectangle {
            id: memNetSeparator

            width: 1
            height: 12
            color: Style.surface1
            anchors.left: memWidget.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Network {
            id: netWidget

            anchors.left: memNetSeparator.right
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            onHovered: (isHovered) => {
                if (isHovered) {
                    netCloseTimer.stop();
                    netOpenTimer.start();
                } else {
                    netOpenTimer.stop();
                    netCloseTimer.start();
                }
            }
        }

        Behavior on marginVal {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }

        }

    }

    // --- CPU Popup Loader & Component ---
    Loader {
        id: popupLoader

        active: false
        sourceComponent: cpuPopupComponent
    }

    Component {
        id: cpuPopupComponent

        PopupWindow {
            id: cpuPopup

            function getProcessInfo(name, cpuStr) {
                var cpu = parseFloat(cpuStr) || 0;
                var nameLower = name.toLowerCase();
                var icon = "developer_board"; // default CPU chip icon
                var iconColor = Style.blue;
                if (nameLower.indexOf("firefox") !== -1 || nameLower.indexOf("chrome") !== -1 || nameLower.indexOf("chromium") !== -1 || nameLower.indexOf("zen") !== -1 || nameLower.indexOf("web") !== -1) {
                    icon = "language";
                    iconColor = Style.green;
                } else if (nameLower.indexOf("nvim") !== -1 || nameLower.indexOf("vim") !== -1 || nameLower.indexOf("code") !== -1 || nameLower.indexOf("emacs") !== -1) {
                    icon = "terminal";
                    iconColor = Style.mauve;
                } else if (nameLower.indexOf("kitty") !== -1 || nameLower.indexOf("foot") !== -1 || nameLower.indexOf("alacritty") !== -1 || nameLower.indexOf("terminal") !== -1 || nameLower.indexOf("fish") !== -1 || nameLower.indexOf("bash") !== -1 || nameLower.indexOf("zsh") !== -1) {
                    icon = "terminal";
                    iconColor = Style.peach;
                } else if (nameLower.indexOf("hyprland") !== -1 || nameLower.indexOf("quickshell") !== -1 || nameLower.indexOf("qs") !== -1) {
                    icon = "widgets";
                    iconColor = Style.lavender;
                } else if (nameLower.indexOf("discord") !== -1 || nameLower.indexOf("vesktop") !== -1) {
                    icon = "forum";
                    iconColor = Style.blue;
                } else if (nameLower.indexOf("spotify") !== -1) {
                    icon = "music_note";
                    iconColor = Style.green;
                } else if (nameLower.indexOf("steam") !== -1) {
                    icon = "sports_esports";
                    iconColor = Style.sky;
                } else if (nameLower.indexOf("systemd") !== -1 || nameLower.indexOf("dbus") !== -1 || nameLower.indexOf("pipewire") !== -1 || nameLower.indexOf("wireplumber") !== -1) {
                    icon = "settings";
                    iconColor = Style.overlay2;
                }
                if (cpu > 20)
                    iconColor = Style.red;
                else if (cpu > 5 && iconColor === Style.blue)
                    iconColor = Style.yellow;
                return {
                    "icon": icon,
                    "color": iconColor
                };
            }

            anchor.window: barWindow
            // Align the popup's center to the CPU widget's center (globally mapped)
            anchor.rect.x: modulesContainer.x + cpuWidget.x + (cpuWidget.width / 2) - 110
            anchor.rect.y: barWindow.height
            implicitWidth: 220
            implicitHeight: 230
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    popupLoader.active = false;

            }
            Component.onCompleted: {
                topProcessesProc.running = true;
            }

            ListModel {
                id: topProcessesModel
            }

            QsIo.Process {
                id: topProcessesProc

                command: ["sh", "-c", "ps -eo pcpu,comm --sort=-pcpu | tail -n +2 | head -13"]

                stdout: QsIo.StdioCollector {
                    onStreamFinished: {
                        topProcessesModel.clear();
                        var lines = this.text.trim().split("\n");
                        var count = 0;
                        for (var i = 0; i < lines.length && count < 10; i++) {
                            var line = lines[i].trim();
                            if (line === "")
                                continue;

                            var parts = line.split(/\s+/);
                            var cpu = parts[0];
                            var name = parts.slice(1).join(" ");
                            if (name === "ps" || name === "sh" || name === "bash")
                                continue;

                            topProcessesModel.append({
                                "name": name,
                                "cpu": cpu
                            });
                            count++;
                        }
                    }
                }

            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: topProcessesProc.running = true
            }

            Item {
                anchors.fill: parent

                // Left Fillet (Inverted Border Corner)
                Shape {
                    id: leftFillet

                    width: 24
                    height: 24
                    anchors.right: popupContent.left
                    anchors.top: popupContent.top
                    opacity: popupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 24
                        startY: 24

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet (Inverted Border Corner)
                Shape {
                    id: rightFillet

                    width: 24
                    height: 24
                    anchors.left: popupContent.right
                    anchors.top: popupContent.top
                    opacity: popupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 0
                        startY: 24

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: popupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: popupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    // Left border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    // Right border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: {
                            openTimer.stop();
                            closeTimer.stop();
                        }
                        onExited: closeTimer.start()
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            popupContent.width = 150;
                            popupContent.height = 230;
                            popupContent.opacity = 1;
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 10
                        model: topProcessesModel
                        spacing: 6
                        clip: true

                        delegate: Row {
                            property var info: getProcessInfo(model.name, model.cpu)

                            width: ListView.view.width
                            spacing: 8
                            height: 18

                            Text {
                                text: info.icon
                                color: info.color
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                width: 14
                                horizontalAlignment: Text.AlignHCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width - 22
                                text: model.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    // --- Memory Popup Loader & Component ---
    Loader {
        id: memPopupLoader

        active: false
        sourceComponent: memPopupComponent
    }

    Component {
        id: memPopupComponent

        PopupWindow {
            id: memPopup

            function getProcessInfo(name, memStr) {
                var mem = parseFloat(memStr) || 0;
                var nameLower = name.toLowerCase();
                var icon = "developer_board"; // default CPU/RAM chip icon
                var iconColor = Style.blue;
                if (nameLower.indexOf("firefox") !== -1 || nameLower.indexOf("chrome") !== -1 || nameLower.indexOf("chromium") !== -1 || nameLower.indexOf("zen") !== -1 || nameLower.indexOf("web") !== -1) {
                    icon = "language";
                    iconColor = Style.green;
                } else if (nameLower.indexOf("nvim") !== -1 || nameLower.indexOf("vim") !== -1 || nameLower.indexOf("code") !== -1 || nameLower.indexOf("emacs") !== -1) {
                    icon = "terminal";
                    iconColor = Style.mauve;
                } else if (nameLower.indexOf("kitty") !== -1 || nameLower.indexOf("foot") !== -1 || nameLower.indexOf("alacritty") !== -1 || nameLower.indexOf("terminal") !== -1 || nameLower.indexOf("fish") !== -1 || nameLower.indexOf("bash") !== -1 || nameLower.indexOf("zsh") !== -1) {
                    icon = "terminal";
                    iconColor = Style.peach;
                } else if (nameLower.indexOf("hyprland") !== -1 || nameLower.indexOf("quickshell") !== -1 || nameLower.indexOf("qs") !== -1) {
                    icon = "widgets";
                    iconColor = Style.lavender;
                } else if (nameLower.indexOf("discord") !== -1 || nameLower.indexOf("vesktop") !== -1) {
                    icon = "forum";
                    iconColor = Style.blue;
                } else if (nameLower.indexOf("spotify") !== -1) {
                    icon = "music_note";
                    iconColor = Style.green;
                } else if (nameLower.indexOf("steam") !== -1) {
                    icon = "sports_esports";
                    iconColor = Style.sky;
                } else if (nameLower.indexOf("systemd") !== -1 || nameLower.indexOf("dbus") !== -1 || nameLower.indexOf("pipewire") !== -1 || nameLower.indexOf("wireplumber") !== -1) {
                    icon = "settings";
                    iconColor = Style.overlay2;
                }
                if (mem > 5)
                    iconColor = Style.red;
                else if (mem > 2 && iconColor === Style.blue)
                    iconColor = Style.yellow;
                return {
                    "icon": icon,
                    "color": iconColor
                };
            }

            anchor.window: barWindow
            // Align the popup's center to the Memory widget's center (globally mapped)
            anchor.rect.x: modulesContainer.x + memWidget.x + (memWidget.width / 2) - 110
            anchor.rect.y: barWindow.height
            implicitWidth: 220
            implicitHeight: 220
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    memPopupLoader.active = false;

            }
            Component.onCompleted: {
                topMemProcessesProc.running = true;
            }

            ListModel {
                id: topMemProcessesModel
            }

            QsIo.Process {
                id: topMemProcessesProc

                command: ["sh", "-c", "ps -eo pmem,comm --sort=-pmem | tail -n +2 | head -13"]

                stdout: QsIo.StdioCollector {
                    onStreamFinished: {
                        topMemProcessesModel.clear();
                        var lines = this.text.trim().split("\n");
                        var count = 0;
                        for (var i = 0; i < lines.length && count < 10; i++) {
                            var line = lines[i].trim();
                            if (line === "")
                                continue;

                            var parts = line.split(/\s+/);
                            var mem = parts[0];
                            var name = parts.slice(1).join(" ");
                            if (name === "ps" || name === "sh" || name === "bash")
                                continue;

                            topMemProcessesModel.append({
                                "name": name,
                                "cpu": mem
                            });
                            count++;
                        }
                    }
                }

            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: topMemProcessesProc.running = true
            }

            Item {
                anchors.fill: parent

                // Left Fillet (Inverted Border Corner)
                Shape {
                    id: memLeftFillet

                    width: 24
                    height: 24
                    anchors.right: memPopupContent.left
                    anchors.top: memPopupContent.top
                    opacity: memPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 24
                        startY: 24

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet (Inverted Border Corner)
                Shape {
                    id: memRightFillet

                    width: 24
                    height: 24
                    anchors.left: memPopupContent.right
                    anchors.top: memPopupContent.top
                    opacity: memPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 0
                        startY: 24

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: memPopupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: memPopupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    // Left border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    // Right border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: {
                            memOpenTimer.stop();
                            memCloseTimer.stop();
                        }
                        onExited: memCloseTimer.start()
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            memPopupContent.width = 150;
                            memPopupContent.height = 220;
                            memPopupContent.opacity = 1;
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 10
                        model: topMemProcessesModel
                        spacing: 6
                        clip: true

                        delegate: Row {
                            property var info: getProcessInfo(model.name, model.cpu)

                            width: ListView.view.width
                            spacing: 8
                            height: 18

                            Text {
                                text: info.icon
                                color: info.color
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                width: 14
                                horizontalAlignment: Text.AlignHCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width - 22
                                text: model.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    // --- Network Popup Loader & Component ---
    Loader {
        id: netPopupLoader

        active: false
        sourceComponent: netPopupComponent
    }

    Component {
        id: netPopupComponent

        PopupWindow {
            id: netPopup

            anchor.window: barWindow
            // Align the popup's center to the Network widget's center (globally mapped)
            anchor.rect.x: modulesContainer.x + netWidget.x + (netWidget.width / 2) - 140
            anchor.rect.y: barWindow.height
            implicitWidth: 280
            implicitHeight: 160
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    netPopupLoader.active = false;

            }
            Component.onCompleted: {
                topNetProcessesProc.running = true;
            }

            ListModel {
                id: topNetProcessesModel
            }

            QsIo.Process {
                id: topNetProcessesProc

                command: ["nethogs", "-t"]

                stdout: QsIo.SplitParser {
                    property var tempProcesses: []

                    onRead: (data) => {
                        if (!data)
                            return ;

                        var line = data.trim();
                        if (line.indexOf("Refreshing:") === 0) {
                            if (tempProcesses.length > 0) {
                                var totalTx = 0;
                                var totalRx = 0;
                                var validProcesses = [];
                                for (var i = 0; i < tempProcesses.length; i++) {
                                    var p = tempProcesses[i];
                                    var nameLower = p.name.toLowerCase();
                                    if (nameLower === "unknown" || nameLower === "nethogs" || nameLower === "sh" || nameLower === "bash")
                                        continue;

                                    totalTx += p.tx;
                                    totalRx += p.rx;
                                    validProcesses.push(p);
                                }
                                if (validProcesses.length > 0) {
                                    var uploadSorted = totalTx > totalRx;
                                    if (uploadSorted)
                                        validProcesses.sort((a, b) => {
                                        return b.tx - a.tx;
                                    });
                                    else
                                        validProcesses.sort((a, b) => {
                                        return b.rx - a.rx;
                                    });
                                    topNetProcessesModel.clear();
                                    for (var j = 0; j < validProcesses.length && j < 5; j++) {
                                        var item = validProcesses[j];
                                        topNetProcessesModel.append({
                                            "name": item.name,
                                            "tx": item.tx,
                                            "rx": item.rx,
                                            "isUploadSorted": uploadSorted
                                        });
                                    }
                                }
                            }
                            tempProcesses = [];
                        } else {
                            var parts = line.split(/\s+/);
                            if (parts.length >= 3) {
                                var progInfo = parts[0];
                                var tx = parseFloat(parts[1]) || 0;
                                var rx = parseFloat(parts[2]) || 0;
                                if (tx > 0 || rx > 0) {
                                    var fullPath = progInfo.split("/")[0];
                                    var progName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
                                    if (progName === "")
                                        progName = fullPath;

                                    tempProcesses.push({
                                        "name": progName,
                                        "tx": tx,
                                        "rx": rx
                                    });
                                }
                            }
                        }
                    }
                }

            }

            Item {
                anchors.fill: parent

                // Left Fillet (Inverted Border Corner)
                Shape {
                    id: netLeftFillet

                    width: 24
                    height: 24
                    anchors.right: netPopupContent.left
                    anchors.top: netPopupContent.top
                    opacity: netPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 24
                        startY: 24

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet (Inverted Border Corner)
                Shape {
                    id: netRightFillet

                    width: 24
                    height: 24
                    anchors.left: netPopupContent.right
                    anchors.top: netPopupContent.top
                    opacity: netPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 0
                        startY: 24

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: netPopupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: netPopupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    // Left border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    // Right border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: {
                            netOpenTimer.stop();
                            netCloseTimer.stop();
                        }
                        onExited: netCloseTimer.start()
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            netPopupContent.width = 220;
                            netPopupContent.height = 160;
                            netPopupContent.opacity = 1;
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 10
                        model: topNetProcessesModel
                        spacing: 6
                        clip: true

                        delegate: Item {
                            width: ListView.view.width
                            height: 18

                            Text {
                                id: dirIcon

                                text: model.isUploadSorted ? "arrow_upward" : "arrow_downward"
                                color: model.isUploadSorted ? Style.peach : Style.green
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 11
                                width: 12
                                horizontalAlignment: Text.AlignHCenter
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: speedText

                                width: 45
                                horizontalAlignment: Text.AlignRight
                                text: {
                                    var speed = model.isUploadSorted ? model.tx : model.rx;
                                    if (speed <= 0)
                                        return "-";

                                    if (speed < 1) {
                                        var bytes = speed * 1024;
                                        if (bytes < 10)
                                            return "-";

                                        return Math.round(bytes) + "B";
                                    }
                                    if (speed < 1024)
                                        return speed.toFixed(1) + "K";

                                    return (speed / 1024).toFixed(1) + "M";
                                }
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.left: dirIcon.right
                                anchors.leftMargin: 6
                                anchors.right: speedText.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    Component {
        id: battPopupComponent

        PopupWindow {
            // Handled by closePopup/destroyTimer

            id: battPopup

            readonly property bool isMouseOver: {
                var p = false;
                try {
                    p = p || battParentMouseArea.containsMouse;
                } catch (e) {
                }
                return p;
            }

            function closePopup() {
                battPopupContent.width = 40;
                battPopupContent.height = 20;
                battPopupContent.opacity = 0;
                destroyTimer.start();
            }

            function cancelClose() {
                destroyTimer.stop();
                battPopupContent.width = 240;
                battPopupContent.height = 90;
                battPopupContent.opacity = 1;
            }

            anchor.window: barWindow
            // Align the popup's center to the Battery widget's center (globally mapped)
            anchor.rect.x: rightContainer.x + barBatteryWidget.x + (barBatteryWidget.width / 2) - 144
            anchor.rect.y: barWindow.height
            implicitWidth: 288
            implicitHeight: 90
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible) {
                }
            }
            onIsMouseOverChanged: {
                if (isMouseOver) {
                    battOpenTimer.stop();
                    battCloseTimer.stop();
                    if (destroyTimer.running)
                        battPopup.cancelClose();

                } else {
                    battCloseTimer.start();
                }
            }

            Timer {
                id: destroyTimer

                interval: 300
                repeat: false
                onTriggered: battPopupLoader.active = false
            }

            Item {
                anchors.fill: parent

                // Left Fillet
                Shape {
                    id: battLeftFillet

                    width: 24
                    height: 24
                    anchors.right: battPopupContent.left
                    anchors.top: battPopupContent.top
                    opacity: battPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet
                Shape {
                    id: battRightFillet

                    width: 24
                    height: 24
                    anchors.left: battPopupContent.right
                    anchors.top: battPopupContent.top
                    opacity: battPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: battPopupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: battPopupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        id: battParentMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            battPopupContent.width = 240;
                            battPopupContent.height = 90;
                            battPopupContent.opacity = 1;
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 8

                        Item {
                            width: parent.width
                            height: 20

                            Text {
                                text: "Battery Status"
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: {
                                    if (!barBatteryWidget.isLaptopBattery)
                                        return "No battery";

                                    return Math.round(barBatteryWidget.percentage * 100) + "%";
                                }
                                color: {
                                    var pct = Math.round(barBatteryWidget.percentage * 100);
                                    if (pct <= 20)
                                        return Style.red;

                                    if (pct <= 40)
                                        return Style.yellow;

                                    return Style.green;
                                }
                                font.family: Style.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        Text {
                            function formatSeconds(s) {
                                if (s <= 0)
                                    return "";

                                var hr = Math.floor(s / 3600) % 60;
                                var min = Math.floor(s / 60) % 60;
                                var comps = [];
                                if (hr > 0)
                                    comps.push(hr + "h");

                                if (min > 0)
                                    comps.push(min + "m");

                                return comps.join(" ");
                            }

                            text: {
                                if (!barBatteryWidget.isLaptopBattery)
                                    return "No laptop battery detected";

                                var stateText = barBatteryWidget.isCharging ? "Charging" : "Discharging";
                                var timeVal = UPower.onBattery ? UPower.displayDevice.timeToEmpty : UPower.displayDevice.timeToFull;
                                var timeStr = formatSeconds(timeVal);
                                if (timeStr !== "")
                                    return stateText + " • " + timeStr + (UPower.onBattery ? " remaining" : " until charged");

                                return stateText + (barBatteryWidget.isCharging ? " • Fully charged!" : "");
                            }
                            color: Style.subtext0
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    Component {
        id: wifiPopupComponent

        PopupWindow {
            id: wifiPopup

            readonly property bool isMouseOver: {
                var p = false;
                try {
                    p = p || wifiParentMouseArea.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || wifiPopup.isAnyItemHovered;
                } catch (e) {
                }
                try {
                    p = p || scanMouse.containsMouse;
                } catch (e) {
                }
                return p;
            }
            property bool isAnyItemHovered: false

            function refreshWifi() {
                wifiListModel.clear();
                wifiScanProc.running = true;
            }

            anchor.window: barWindow
            // Align the popup's center to the WifiIcon widget's center (globally mapped)
            anchor.rect.x: rightContainer.x + wifiIconWidget.x + (wifiIconWidget.width / 2) - 164
            anchor.rect.y: barWindow.height
            implicitWidth: 328
            implicitHeight: 280
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    wifiPopupLoader.active = false;

            }
            onIsMouseOverChanged: {
                if (isMouseOver) {
                    wifiOpenTimer.stop();
                    wifiCloseTimer.stop();
                } else {
                    wifiCloseTimer.start();
                }
            }

            ListModel {
                id: wifiListModel
            }

            QsIo.Process {
                id: wifiScanProc

                command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
                running: false

                stdout: QsIo.SplitParser {
                    onRead: (data) => {
                        if (!data)
                            return ;

                        var line = data.trim();
                        var parts = line.split(":");
                        if (parts.length >= 3) {
                            var active = parts[0] === "yes";
                            var ssid = parts[1];
                            if (ssid === "")
                                return ;

                            var signal = parseInt(parts[2]) || 0;
                            var security = parts[3] || "";
                            var found = false;
                            for (var i = 0; i < wifiListModel.count; i++) {
                                if (wifiListModel.get(i).ssid === ssid) {
                                    found = true;
                                    wifiListModel.set(i, {
                                        "active": active || wifiListModel.get(i).active,
                                        "ssid": ssid,
                                        "signal": Math.max(signal, wifiListModel.get(i).signal),
                                        "security": security
                                    });
                                    break;
                                }
                            }
                            if (!found)
                                wifiListModel.append({
                                "active": active,
                                "ssid": ssid,
                                "signal": signal,
                                "security": security
                            });

                        }
                    }
                }

            }

            Timer {
                id: wifiScanTimer

                interval: 10000
                running: wifiPopup.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: wifiPopup.refreshWifi()
            }

            Timer {
                id: refreshTimer

                interval: 1500
                running: false
                repeat: false
                onTriggered: wifiPopup.refreshWifi()
            }

            Item {
                anchors.fill: parent

                // Left Fillet
                Shape {
                    id: wifiLeftFillet

                    width: 24
                    height: 24
                    anchors.right: wifiPopupContent.left
                    anchors.top: wifiPopupContent.top
                    opacity: wifiPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet
                Shape {
                    id: wifiRightFillet

                    width: 24
                    height: 24
                    anchors.left: wifiPopupContent.right
                    anchors.top: wifiPopupContent.top
                    opacity: wifiPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: wifiPopupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: wifiPopupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        id: wifiParentMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            wifiPopupContent.width = 280;
                            wifiPopupContent.height = 280;
                            wifiPopupContent.opacity = 1;
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 12

                        Item {
                            width: parent.width
                            height: 24

                            Text {
                                text: "Wi-Fi Networks"
                                color: Style.text
                                font.family: Style.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "refresh"
                                color: Style.green
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: scanMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
                                        wifiPopup.refreshWifi();
                                    }
                                }

                            }

                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Style.surface1
                        }

                        ListView {
                            width: parent.width
                            height: parent.height - 24 - 1 - 12
                            model: wifiListModel
                            spacing: 4
                            clip: true

                            delegate: Item {
                                width: ListView.view.width
                                height: 32

                                Rectangle {
                                    anchors.fill: parent
                                    color: itemMouseArea.containsMouse ? Style.surface0 : "transparent"
                                    radius: 4
                                }

                                MouseArea {
                                    id: itemMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: wifiPopup.isAnyItemHovered = true
                                    onExited: wifiPopup.isAnyItemHovered = false
                                }

                                Text {
                                    id: sigIcon

                                    text: {
                                        if (model.signal >= 75)
                                            return "network_wifi_3_bar";

                                        if (model.signal >= 50)
                                            return "network_wifi_3_bar";

                                        if (model.signal >= 25)
                                            return "network_wifi_2_bar";

                                        return "signal_wifi_4_bar";
                                    }
                                    color: model.active ? Style.green : Style.text
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 13
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: ssidText

                                    text: model.ssid
                                    color: model.active ? Style.green : Style.text
                                    font.family: Style.fontFamily
                                    font.pixelSize: 12
                                    font.weight: model.active ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    anchors.left: sigIcon.right
                                    anchors.leftMargin: 12
                                    anchors.right: lockIcon.visible ? lockIcon.left : actionIcon.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: lockIcon

                                    text: "lock"
                                    visible: model.security !== "" && model.security !== "--"
                                    color: Style.subtext0
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 11
                                    anchors.right: actionIcon.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: actionIcon

                                    text: model.active ? "link_off" : "link"
                                    color: model.active ? Style.red : Style.green
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 13
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.active)
                                                Quickshell.execDetached(["nmcli", "connection", "down", model.ssid]);
                                            else
                                                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", model.ssid]);
                                            refreshTimer.start();
                                        }
                                    }

                                }

                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    Component {
        id: qsPopupComponent

        PopupWindow {
            id: qsPopup

            readonly property bool isMouseOver: {
                var p = false;
                try {
                    p = p || parentMouseArea.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || volSliderMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || brightSliderMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || volKnobMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || brightKnobMouse.containsMouse;
                } catch (e) {
                }
                return p;
            }

            function closePopup() {
                popupContent.width = 40;
                popupContent.height = 20;
                popupContent.opacity = 0;
                destroyTimer.start();
            }

            function cancelClose() {
                destroyTimer.stop();
                popupContent.width = 280;
                popupContent.height = 110;
                popupContent.opacity = 1;
            }

            onIsMouseOverChanged: {
                if (isMouseOver) {
                    qsOpenTimer.stop();
                    qsCloseTimer.stop();
                    if (destroyTimer.running)
                        qsPopup.cancelClose();

                } else {
                    qsCloseTimer.start();
                }
            }
            anchor.window: barWindow
            anchor.rect.x: rightContainer.x + (barVolumeWidget.x + barBrightnessWidget.x) / 2 + (barVolumeWidget.width / 2) - 164
            anchor.rect.y: barWindow.height
            implicitWidth: 328
            implicitHeight: 110
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    qsPopupLoader.active = false;

            }

            Timer {
                id: destroyTimer

                interval: 300
                repeat: false
                onTriggered: qsPopupLoader.active = false
            }

            Item {
                anchors.fill: parent

                // Left Fillet (Inverted Border Corner)
                Shape {
                    id: leftFillet

                    width: 24
                    height: 24
                    anchors.right: popupContent.left
                    anchors.top: popupContent.top
                    opacity: popupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 24
                        startY: 24

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet (Inverted Border Corner)
                Shape {
                    id: rightFillet

                    width: 24
                    height: 24
                    anchors.left: popupContent.right
                    anchors.top: popupContent.top
                    opacity: popupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 0
                        startY: 24

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: popupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: popupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    // Left border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    // Right border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        id: parentMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                    }

                    // Content layout
                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 16
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 12

                        // VOLUME ROW
                        Row {
                            width: parent.width
                            height: 32
                            spacing: 8

                            Item {
                                id: volSliderContainer

                                width: parent.width
                                height: 32

                                Rectangle {
                                    id: volTrack

                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Style.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        id: volFill

                                        width: parent.width * (barVolumeWidget.volume / 100)
                                        height: parent.height
                                        radius: 3
                                        color: barVolumeWidget.isMuted ? Style.overlay1 : Style.blue
                                    }

                                    // 22px Knob containing the Volume Icon
                                    Rectangle {
                                        id: volKnob

                                        readonly property bool active: volKnobMouse.containsMouse || volSliderMouse.pressed

                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: barVolumeWidget.isMuted ? Style.red : Style.blue
                                        border.color: active ? Style.rosewater : Style.base
                                        border.width: active ? 2.5 : 1.5
                                        x: volFill.width - 11
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            text: {
                                                if (barVolumeWidget.isMuted)
                                                    return "volume_off";

                                                if (barVolumeWidget.volume < 33)
                                                    return "volume_down";

                                                if (barVolumeWidget.volume < 66)
                                                    return "volume_down";

                                                return "volume_up";
                                            }
                                            color: Style.base
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 11
                                            font.weight: Style.fontWeight
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            // Propagate drag/press to volSliderMouse

                                            id: volKnobMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            propagateComposedEvents: true
                                            onPressed: (mouse) => {
                                                if (mouse.button === Qt.LeftButton)
                                                    mouse.accepted = false;

                                            }
                                            onClicked: (mouse) => {
                                                Quickshell.execDetached(["pamixer", "-t"]);
                                            }
                                        }

                                    }

                                }

                                MouseArea {
                                    id: volSliderMouse

                                    function updateVolume(mouse) {
                                        var pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                        Quickshell.execDetached(["pamixer", "--set-volume", pct.toString()]);
                                        barVolumeWidget.volume = pct;
                                    }

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    onPressed: (mouse) => {
                                        return updateVolume(mouse);
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed)
                                            updateVolume(mouse);

                                    }

                                    // Bind the volume adjustment guard to prevent background processes from overriding drags
                                    Binding {
                                        target: barVolumeWidget
                                        property: "isAdjusting"
                                        value: volSliderMouse.pressed
                                    }

                                }

                            }

                        }

                        // BRIGHTNESS ROW
                        Row {
                            width: parent.width
                            height: 32
                            spacing: 8

                            Item {
                                id: brightSliderContainer

                                width: parent.width
                                height: 32

                                Rectangle {
                                    id: brightTrack

                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Style.surface1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        id: brightFill

                                        width: parent.width * (barBrightnessWidget.brightness / 100)
                                        height: parent.height
                                        radius: 3
                                        color: Style.mauve
                                    }

                                    // 22px Knob containing the Brightness Icon
                                    Rectangle {
                                        id: brightKnob

                                        readonly property bool active: brightKnobMouse.containsMouse || brightSliderMouse.pressed

                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: Style.mauve
                                        border.color: active ? Style.rosewater : Style.base
                                        border.width: active ? 2.5 : 1.5
                                        x: brightFill.width - 11
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            text: barBrightnessWidget.brightnessIcon(barBrightnessWidget.brightness)
                                            color: Style.base
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 11
                                            font.weight: Style.fontWeight
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: brightKnobMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            propagateComposedEvents: true
                                            onPressed: (mouse) => {
                                                if (mouse.button === Qt.LeftButton)
                                                    mouse.accepted = false;

                                            }
                                        }

                                    }

                                }

                                MouseArea {
                                    id: brightSliderMouse

                                    function updateBrightness(mouse) {
                                        var pct = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                        var clamped = Math.max(10, Math.min(100, pct));
                                        Quickshell.execDetached(["brightnessctl", "s", clamped + "%"]);
                                        barBrightnessWidget.brightness = clamped;
                                    }

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    onPressed: (mouse) => {
                                        return updateBrightness(mouse);
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed)
                                            updateBrightness(mouse);

                                    }

                                    // Bind the brightness adjustment guard
                                    Binding {
                                        target: barBrightnessWidget
                                        property: "isAdjusting"
                                        value: brightSliderMouse.pressed
                                    }

                                }

                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

            Timer {
                interval: 50
                running: true
                repeat: false
                onTriggered: qsPopup.cancelClose()
            }

        }

    }

    Component {
        id: playerPopupComponent

        PopupWindow {
            id: playerPopup

            readonly property bool isMouseOver: {
                var p = false;
                try {
                    p = p || parentMouseArea.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || prevMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || playMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || nextMouse.containsMouse;
                } catch (e) {
                }
                try {
                    p = p || progressMouse.containsMouse;
                } catch (e) {
                }
                return p;
            }

            function closePopup() {
                playerPopupContent.width = 40;
                playerPopupContent.height = 20;
                playerPopupContent.opacity = 0;
                destroyTimer.start();
            }

            function cancelClose() {
                destroyTimer.stop();
                playerPopupContent.width = 400;
                playerPopupContent.height = 120;
                playerPopupContent.opacity = 1;
            }

            // Function to format seconds into MM:SS format
            function formatTime(secs) {
                if (isNaN(secs) || secs <= 0)
                    return "0:00";

                var m = Math.floor(secs / 60);
                var s = Math.floor(secs % 60);
                return m + ":" + (s < 10 ? "0" : "") + s;
            }

            // Function to sanitize local and remote art URLs
            function sanitizeArtUrl(url) {
                if (!url)
                    return "";

                url = url.trim();
                if (url === "")
                    return "";

                // If it starts with file:// but has only 2 slashes after colon (file://home/...), fix to file:///
                if (url.indexOf("file://") === 0 && url.indexOf("file:///") !== 0)
                    return "file:///" + url.substring(7);

                // If it's already a URL (http, https, file), return it
                if (url.indexOf("http://") === 0 || url.indexOf("https://") === 0 || url.indexOf("file://") === 0)
                    return url;

                // If it starts with /, it's a local absolute path, so prepend file://
                if (url.indexOf("/") === 0)
                    return "file://" + url;

                return url;
            }

            onIsMouseOverChanged: {
                if (isMouseOver) {
                    playerOpenTimer.stop();
                    playerCloseTimer.stop();
                    if (destroyTimer.running)
                        playerPopup.cancelClose();

                } else {
                    playerCloseTimer.start();
                }
            }
            anchor.window: barWindow
            // Center the popup in the middle of the screen
            anchor.rect.x: (barWindow.width / 2) - 225
            anchor.rect.y: barWindow.height
            implicitWidth: 450
            implicitHeight: 120
            color: "transparent"
            visible: true
            onVisibleChanged: {
                if (!visible)
                    playerPopupLoader.active = false;

            }

            // Timer to defer loader destruction until close animation ends
            Timer {
                id: destroyTimer

                interval: 300
                repeat: false
                onTriggered: playerPopupLoader.active = false
            }

            Item {
                anchors.fill: parent

                // Left Fillet (Inverted Border Corner)
                Shape {
                    id: playerLeftFillet

                    width: 24
                    height: 24
                    anchors.right: playerPopupContent.left
                    anchors.top: playerPopupContent.top
                    opacity: playerPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0

                        PathLine {
                            x: 24
                            y: 0
                        }

                        PathLine {
                            x: 24
                            y: 24
                        }

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 24
                        startY: 24

                        PathArc {
                            x: 0
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Counterclockwise
                        }

                    }

                }

                // Right Fillet (Inverted Border Corner)
                Shape {
                    id: playerRightFillet

                    width: 24
                    height: 24
                    anchors.left: playerPopupContent.right
                    anchors.top: playerPopupContent.top
                    opacity: playerPopupContent.opacity
                    visible: opacity > 0.01
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        fillColor: Style.crust
                        strokeColor: "transparent"
                        startX: 24
                        startY: 0

                        PathLine {
                            x: 0
                            y: 0
                        }

                        PathLine {
                            x: 0
                            y: 24
                        }

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Style.surface1
                        strokeWidth: 0
                        startX: 0
                        startY: 24

                        PathArc {
                            x: 24
                            y: 0
                            radiusX: 24
                            radiusY: 24
                            direction: PathArc.Clockwise
                        }

                    }

                }

                Item {
                    id: playerPopupContent

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 40
                    height: 20
                    clip: true
                    opacity: 0

                    Rectangle {
                        id: playerPopupBg

                        anchors.top: parent.top
                        anchors.topMargin: -24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        radius: 24
                        color: Style.crust
                        border.color: Style.surface1
                        border.width: 0
                    }

                    // Left border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    // Right border mask (erases the vertical border in the fillet zone)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 2
                        height: 24
                        color: Style.crust
                    }

                    MouseArea {
                        id: parentMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Timer {
                        interval: 50
                        running: true
                        repeat: false
                        onTriggered: {
                            playerPopupContent.width = 400;
                            playerPopupContent.height = 120;
                            playerPopupContent.opacity = 1;
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16

                        // Left Side: Album Art / Image Thumbnail
                        Rectangle {
                            width: 96
                            height: 96
                            radius: 8
                            color: Style.surface0
                            border.color: Style.surface1
                            border.width: 0
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: albumArtImage

                                anchors.fill: parent
                                source: playerPopup.sanitizeArtUrl(playerWidget.localArtUrl)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: albumArtImage.status === Image.Ready
                            }

                            // Placeholder when no album art is loaded
                            Text {
                                text: "music_note"
                                color: Style.subtext1
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 32
                                anchors.centerIn: parent
                                visible: albumArtImage.status !== Image.Ready
                            }

                        }

                        // Right Side: Details, Progress, and Controls
                        Column {
                            width: parent.width - 96 - 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            // Row 1: Track details (Title & Artist)
                            Column {
                                width: parent.width
                                spacing: 2

                                Text {
                                    text: playerWidget.title
                                    color: Style.text
                                    font.family: Style.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: playerWidget.artist
                                    color: Style.subtext0
                                    font.family: Style.fontFamily
                                    font.pixelSize: 11
                                    width: parent.width
                                    elide: Text.ElideRight
                                    visible: playerWidget.artist !== ""
                                }

                            }

                            // Row 2: Progress Bar
                            Column {
                                width: parent.width
                                spacing: 4

                                // Progress Line
                                Rectangle {
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Style.surface1

                                    Rectangle {
                                        height: parent.height
                                        radius: 2
                                        color: Style.maroon
                                        width: Math.min(parent.width * (playerWidget.length > 0 ? (playerWidget.position / playerWidget.length) : 0), parent.width)
                                    }

                                    MouseArea {
                                        id: progressMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                }

                                // Time Label
                                Text {
                                    text: playerPopup.formatTime(playerWidget.position) + " / " + playerPopup.formatTime(playerWidget.length)
                                    color: Style.subtext0
                                    font.family: Style.fontFamily
                                    font.pixelSize: 10
                                }

                            }

                            // Row 3: Control Buttons Wrapper (Item centerer)
                            Item {
                                width: parent.width
                                height: 32

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 20

                                    // Previous Button
                                    Item {
                                        width: 32
                                        height: 32

                                        Text {
                                            text: "skip_previous"
                                            color: prevMouse.containsMouse ? Style.mauve : Style.text
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: prevMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playerWidget.prevTrack()
                                        }

                                    }

                                    // Play/Pause Button
                                    Item {
                                        width: 32
                                        height: 32

                                        Text {
                                            text: playerWidget.isPlaying ? "pause" : "play_arrow"
                                            color: playMouse.containsMouse ? Style.mauve : (playerWidget.isPlaying ? Style.green : Style.text)
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 22
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: playMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playerWidget.togglePlay()
                                        }

                                    }

                                    // Next Button
                                    Item {
                                        width: 32
                                        height: 32

                                        Text {
                                            text: "skip_next"
                                            color: nextMouse.containsMouse ? Style.mauve : Style.text
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: nextMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playerWidget.nextTrack()
                                        }

                                    }

                                }

                            }

                        }

                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultSpatial
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultSpatialCurve
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.durationExpressiveDefaultEffects
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Style.expressiveDefaultEffectsCurve
                        }

                    }

                }

            }

        }

    }

    Behavior on margins.top {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 1
        }

    }

}
