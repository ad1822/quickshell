import "../components"
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io as QsIo
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: barWindow

    property bool modulesExpanded: false
    property bool barExpanded: false
    property bool isHovered: false
    property alias volumeWidget: barVolumeWidget
    property alias brightnessWidget: barBrightnessWidget

    // Close all popups except the one matching the given loader ID
    function closeAllPopupsExcept(exceptLoader) {
        var loaders = [wifiPopupLoader, playerPopupLoader, qsPopupLoader, popupLoader, memPopupLoader, netPopupLoader, wallpaperPopupLoader];
        for (var i = 0; i < loaders.length; i++) {
            var loader = loaders[i];
            if (loader && loader !== exceptLoader && loader.active)
                loader.active = false;

        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: barWindow.barExpanded ? 30 : (barWindow.isHovered ? 64 : 30)
    margins.top: barWindow.barExpanded ? 0 : 4
    color: "transparent"
    WlrLayershell.exclusiveZone: 30

    Rectangle {
        id: barBg

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: barWindow.barExpanded ? 30 : (barWindow.isHovered ? 64 : 30)
        color: "#11111b"
        width: barWindow.barExpanded ? parent.width : (barWindow.isHovered ? 360 : (barClock.width + 10))
        radius: barWindow.barExpanded ? 0 : (barWindow.isHovered ? 12 : 6)

        MouseArea {
            id: barMouseArea

            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (!barWindow.barExpanded)
                    hoverTimer.start();

            }
            onExited: {
                hoverTimer.stop();
                barWindow.isHovered = false;
            }
            onClicked: {
                hoverTimer.stop();
                barWindow.barExpanded = !barWindow.barExpanded;
                barWindow.isHovered = false;
            }

            Timer {
                id: hoverTimer

                interval: 150
                repeat: false
                onTriggered: {
                    if (barMouseArea.containsMouse && !barWindow.barExpanded)
                        barWindow.isHovered = true;

                }
            }

            Clock {
                id: barClock

                anchors.centerIn: parent
                height: parent.height
                barExpanded: barWindow.barExpanded
                opacity: (barWindow.barExpanded || (!barWindow.isHovered && barBg.width < 150)) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

            // --- Hover State Expanded Content ---
            Item {
                id: hoverContent

                anchors.fill: parent
                opacity: (barWindow.isHovered && !barWindow.barExpanded && barBg.width > 220) ? 1 : 0
                visible: opacity > 0

                // Left Section: Active Window Icon Only
                Item {
                    id: activeWindowIconOnly

                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24

                    // Application Icon
                    Image {
                        id: activeAppIcon

                        property var activeToplevel: null
                        property string appClass: (activeToplevel && activeToplevel.lastIpcObject) ? activeToplevel.lastIpcObject.class : ""

                        function getAppIconFromDesktop(appClass) {
                            function getBinary(execStr) {
                                if (!execStr)
                                    return "";

                                var trimmed = execStr.trim();
                                var firstWord = trimmed.split(" ")[0];
                                var lastSlash = firstWord.lastIndexOf("/");
                                if (lastSlash !== -1)
                                    return firstWord.substring(lastSlash + 1);

                                return firstWord;
                            }

                            function isGenericLauncher(execStr) {
                                if (!execStr)
                                    return false;

                                var cleaned = execStr.trim().replace(/%[fFuUiIdDnNoNvkU]/g, "").trim();
                                var parts = cleaned.split(/\s+/);
                                return parts.length === 1;
                            }

                            if (!appClass || !spotlightWindow || !spotlightWindow.allApps)
                                return "";

                            var query = appClass.toLowerCase();
                            // 1. Try exact binary name match (preferring generic launchers)
                            for (var i = 0; i < spotlightWindow.allApps.length; i++) {
                                var app = spotlightWindow.allApps[i];
                                if (!isGenericLauncher(app.exec))
                                    continue;

                                var binary = getBinary(app.exec).toLowerCase();
                                if (binary === query)
                                    return app.icon;

                            }
                            // 2. Try name match (case-insensitive)
                            for (var i = 0; i < spotlightWindow.allApps.length; i++) {
                                var app = spotlightWindow.allApps[i];
                                if (app.name.toLowerCase() === query)
                                    return app.icon;

                            }
                            // 3. Try loose binary prefix/substring match (preferring generic launchers)
                            for (var i = 0; i < spotlightWindow.allApps.length; i++) {
                                var app = spotlightWindow.allApps[i];
                                if (!isGenericLauncher(app.exec))
                                    continue;

                                var binary = getBinary(app.exec).toLowerCase();
                                if (binary.indexOf(query) !== -1 || query.indexOf(binary) !== -1)
                                    return app.icon;

                            }
                            // 4. Fallback: If no generic launcher matched, try any matching binary
                            for (var i = 0; i < spotlightWindow.allApps.length; i++) {
                                var app = spotlightWindow.allApps[i];
                                var binary = getBinary(app.exec).toLowerCase();
                                if (binary === query || binary.indexOf(query) !== -1 || query.indexOf(binary) !== -1)
                                    return app.icon;

                            }
                            return "";
                        }

                        function updateActiveToplevel() {
                            for (var i = 0; i < toplevelTracker.count; i++) {
                                var obj = toplevelTracker.objectAt(i);
                                if (obj && obj.isActivated) {
                                    activeToplevel = obj.toplevel;
                                    return ;
                                }
                            }
                            activeToplevel = null;
                        }

                        anchors.fill: parent
                        source: {
                            if (!appClass)
                                return "";

                            var cleanClass = appClass;
                            if (cleanClass.indexOf(".") !== -1) {
                                var parts = cleanClass.split(".");
                                cleanClass = parts[parts.length - 1];
                            }
                            // Try finding the icon from desktop database first
                            var desktopIcon = getAppIconFromDesktop(cleanClass);
                            var icon = "";
                            if (desktopIcon) {
                                if (desktopIcon.indexOf("/") === 0)
                                    icon = "file://" + desktopIcon;
                                else
                                    icon = Quickshell.iconPath(desktopIcon);
                            }
                            // Fallback to direct class lookup in the icon theme
                            if (!icon) {
                                var themeIcon = Quickshell.iconPath(appClass.toLowerCase());
                                if (!themeIcon)
                                    themeIcon = Quickshell.iconPath(cleanClass.toLowerCase());

                                if (!themeIcon)
                                    themeIcon = Quickshell.iconPath(appClass);

                                if (!themeIcon)
                                    themeIcon = Quickshell.iconPath(cleanClass);

                                if (themeIcon)
                                    icon = (themeIcon.toString().indexOf("/") === 0) ? "file://" + themeIcon : themeIcon;

                            }
                            return icon;
                        }
                        visible: source !== "" && status === Image.Ready
                    }

                    // Fallback Text Icon
                    Text {
                        text: "widgets"
                        color: Style.subtext0
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        anchors.centerIn: parent
                        visible: !activeAppIcon.visible
                    }

                    // Instantiator to track focus changes dynamically
                    Instantiator {
                        id: toplevelTracker

                        model: Hyprland.toplevels

                        delegate: QtObject {
                            property bool isActivated: modelData ? modelData.activated : false
                            property var toplevel: modelData

                            Component.onCompleted: {
                                if (isActivated)
                                    activeAppIcon.activeToplevel = modelData;

                            }
                            onIsActivatedChanged: {
                                if (isActivated)
                                    activeAppIcon.activeToplevel = modelData;
                                else
                                    activeAppIcon.updateActiveToplevel();
                            }
                            Component.onDestruction: {
                                if (activeAppIcon.activeToplevel === modelData)
                                    activeAppIcon.updateActiveToplevel();

                            }
                        }

                    }

                }

                // Middle Section: Large Time & Date
                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: Qt.formatDateTime(barClock.currentTime, "HH:mm")
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Qt.formatDateTime(barClock.currentTime, "dddd, MMMM d")
                        color: Style.subtext0
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                }

                // Right Section: Battery Percentage
                Battery {
                    id: hoverBatteryWidget

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    transparentBg: true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 400
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
        anchors.leftMargin: barWindow.barExpanded ? 0 : -300
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

    // --- Hamburger Button Card ---
    Rectangle {
        id: hamburgerButton

        anchors.left: workspacesWidget.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 6
        color: "transparent"
        // color: hamburgerMouse.containsMouse ? Style.surface0 : Style.base
        border.color: Style.surface1
        border.width: 0
        opacity: barWindow.barExpanded ? 1 : 0

        // Centered morphing vector lines
        Item {
            anchors.centerIn: parent
            width: 12
            height: 12

            // Top Line
            Rectangle {
                id: topLine

                width: 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: barWindow.modulesExpanded ? 6 : 3
                transformOrigin: Item.Center
                rotation: barWindow.modulesExpanded ? 45 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1
                    }

                }

            }

            // Middle Line
            Rectangle {
                id: middleLine

                width: barWindow.modulesExpanded ? 0 : 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: 6
                opacity: barWindow.modulesExpanded ? 0 : 1

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }

                }

            }

            // Bottom Line
            Rectangle {
                id: bottomLine

                width: 12
                height: 1.5
                radius: 0.75
                color: Style.text
                x: 0
                y: barWindow.modulesExpanded ? 6 : 9
                transformOrigin: Item.Center
                rotation: barWindow.modulesExpanded ? -45 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                    }

                }

                Behavior on rotation {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1
                    }

                }

            }

        }

        MouseArea {
            id: hamburgerMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: barWindow.modulesExpanded = !barWindow.modulesExpanded
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

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
            if (popupLoader.active && popupLoader.item)
                popupLoader.item.cancelClose();
            else
                popupLoader.active = true;
        }
    }

    Timer {
        id: closeTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (popupLoader.item)
                popupLoader.item.closePopup();
            else
                popupLoader.active = false;
        }
    }

    // --- Memory Popup Timers ---
    Timer {
        id: memOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            memCloseTimer.stop();
            if (memPopupLoader.active && memPopupLoader.item)
                memPopupLoader.item.cancelClose();
            else
                memPopupLoader.active = true;
        }
    }

    Timer {
        id: memCloseTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (memPopupLoader.item)
                memPopupLoader.item.closePopup();
            else
                memPopupLoader.active = false;
        }
    }

    // --- Network Popup Timers ---
    Timer {
        id: netOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            netCloseTimer.stop();
            if (netPopupLoader.active && netPopupLoader.item)
                netPopupLoader.item.cancelClose();
            else
                netPopupLoader.active = true;
        }
    }

    Timer {
        id: netCloseTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (netPopupLoader.item)
                netPopupLoader.item.closePopup();
            else
                netPopupLoader.active = false;
        }
    }

    // --- Wifi Popup Timers & Loader ---
    Timer {
        id: wifiOpenTimer

        interval: 300
        repeat: false
        onTriggered: {
            wifiCloseTimer.stop();
            if (wifiPopupLoader.active && wifiPopupLoader.item)
                wifiPopupLoader.item.cancelClose();
            else
                wifiPopupLoader.active = true;
        }
    }

    Timer {
        id: wifiCloseTimer

        interval: 200
        repeat: false
        onTriggered: {
            if (wifiPopupLoader.item)
                wifiPopupLoader.item.closePopup();
            else
                wifiPopupLoader.active = false;
        }
    }

    Loader {
        id: wifiPopupLoader

        active: false
        source: "../components/popout/WifiPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(wifiPopupLoader);

        }
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

        interval: 1000
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
        source: "../components/popout/PlayerPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(playerPopupLoader);

        }
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
        source: "../components/popout/QsPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(qsPopupLoader);

        }
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

    // --- CPU Popup Loader ---
    Loader {
        id: popupLoader

        active: false
        source: "../components/popout/CpuPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(popupLoader);

        }
    }

    // --- Memory Popup Loader ---
    Loader {
        id: memPopupLoader

        active: false
        source: "../components/popout/MemPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(memPopupLoader);

        }
    }

    // --- Network Popup Loader ---
    Loader {
        id: netPopupLoader

        active: false
        source: "../components/popout/NetPopup.qml"
        onActiveChanged: {
            if (active)
                barWindow.closeAllPopupsExcept(netPopupLoader);

        }
    }

    mask: Region {
        item: barBg
    }

}
