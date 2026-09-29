import "../components"
import "../services"
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
    property bool powermenuActive: false
    property var activeToastNotification: null
    readonly property bool toastHasBody: activeToastNotification !== null && activeToastNotification.body && activeToastNotification.body !== ""
    // Widgets live in BarSection repeaters now, so they cannot be reached by
    // id. They are resolved by layout id instead, and are null whenever the
    // user has dragged one off the bar entirely.
    // Audio and backlight are handled by the imported Omarchy panels on the
    // bar, but the OSDs and the collapsed pill still need the values. These
    // two keep polling with no icon of their own.
    readonly property var volumeWidget: volumeSource
    readonly property var brightnessWidget: brightnessSource
    readonly property var playerWidget: barDrag.itemFor("player")
    readonly property var cpuWidget: barDrag.itemFor("cpu")
    readonly property var memWidget: barDrag.itemFor("memory")
    readonly property var netWidget: barDrag.itemFor("network")
    readonly property bool hasMedia: playerWidget !== null && playerWidget.activePlayer !== null && playerWidget.title !== ""

    // Drag-to-rearrange. Off by default so widgets keep their normal clicks;
    // toggled from Hyprland via the "bar" IPC target.
    property bool editMode: false
    property string osdMode: "" // "", "volume", "brightness"
    property int osdVolume: 0
    property bool osdMuted: false
    property int osdBrightness: 0

    onOsdModeChanged: {
        if (osdMode !== "" && !barExpanded) {
            isHovered = false;
            activeToastNotification = null;
            barNotifToastTimer.stop();
            powermenuActive = false;
        }
    }

    onActiveToastNotificationChanged: {
        if (activeToastNotification !== null && !barExpanded) {
            isHovered = false;
            osdMode = "";
            barOsdTimer.stop();
            powermenuActive = false;
        }
    }

    onPowermenuActiveChanged: {
        if (powermenuActive) {
            if (!barExpanded) {
                isHovered = false;
                activeToastNotification = null;
                barNotifToastTimer.stop();
                osdMode = "";
                barOsdTimer.stop();
                wrappedPowermenuDismissTimer.restart();
            }
        } else {
            wrappedPowermenuDismissTimer.stop();
        }
    }

    function restartToastTimer() {
        barNotifToastTimer.restart();
    }

    function triggerBarOsd(type, val, extra) {
        if (type === "volume") {
            osdVolume = val;
            osdMuted = extra;
            osdMode = "volume";
        } else if (type === "brightness") {
            osdBrightness = val;
            osdMode = "brightness";
        }
        barOsdTimer.restart();
    }

    // Close all popups except the one matching the given loader ID
    function closeAllPopupsExcept(exceptLoader) {
        if (exceptLoader !== powermenuPopupLoader) {
            powermenuActive = false;
        }
        var loaders = [playerPopupLoader, popupLoader, memPopupLoader, netPopupLoader, powermenuPopupLoader];
        for (var i = 0; i < loaders.length; i++) {
            var loader = loaders[i];
            if (loader && loader !== exceptLoader && loader.active)
                loader.active = false;

        }
    }

    function togglePowermenu() {
        if (barExpanded) {
            if (powermenuPopupLoader.active) {
                if (powermenuPopupLoader.item) {
                    powermenuPopupLoader.item.closePopup();
                } else {
                    powermenuPopupLoader.active = false;
                }
                powermenuActive = false;
            } else {
                powermenuPopupLoader.active = true;
                powermenuActive = true;
            }
        } else {
            powermenuActive = !powermenuActive;
            if (powermenuActive) {
                var loaders = [playerPopupLoader, popupLoader, memPopupLoader, netPopupLoader, powermenuPopupLoader];
                for (var i = 0; i < loaders.length; i++) {
                    var loader = loaders[i];
                    if (loader && loader.active)
                        loader.active = false;
                }
            }
        }
    }


    // Horizontal centre of a widget, in this window's coordinates, for the
    // popups that anchor under it. Walking the parent chain reads a real x
    // off every ancestor, so the binding re-runs when a drag moves the widget
    // or resizes anything before it.
    function slotCenterX(id) {
        var slot = barDrag.slotFor(id);
        if (!slot)
            return barWindow.width / 2;

        var x = slot.x + slot.width / 2;
        var node = slot.parent;
        while (node && node !== barWindow.contentItem) {
            x += node.x;
            node = node.parent;
        }
        return x;
    }

    // Hover routing for the section widgets. Bar.qml used to wire each popup
    // timer to a widget it declared by id; with widgets coming from a layout
    // file the wiring has to key off the layout id instead.
    function routeWidgetHover(id, isHovered) {
        switch (id) {
        case "cpu":
            if (isHovered) {
                closeTimer.stop();
                openTimer.start();
            } else {
                openTimer.stop();
                closeTimer.start();
            }
            break;
        case "memory":
            if (isHovered) {
                memCloseTimer.stop();
                memOpenTimer.start();
            } else {
                memOpenTimer.stop();
                memCloseTimer.start();
            }
            break;
        case "network":
            if (isHovered) {
                netCloseTimer.stop();
                netOpenTimer.start();
            } else {
                netOpenTimer.stop();
                netCloseTimer.start();
            }
            break;
        case "player":
            if (isHovered && barWindow.playerWidget && barWindow.playerWidget.activePlayer !== null) {
                playerCloseTimer.stop();
                playerOpenTimer.start();
            } else {
                playerOpenTimer.stop();
                playerCloseTimer.start();
            }
            break;
        }
    }

    function toggleEditMode(force) {
        barWindow.editMode = force === undefined ? !barWindow.editMode : !!force;
        // Rearranging is only meaningful on the full-width bar, where the
        // sections are actually on screen.
        if (barWindow.editMode)
            barWindow.barExpanded = true;
    }

    // Headless audio/backlight sources. They carry no icon — the Omarchy
    // audio and monitor panels own that on the bar now — but the OSDs in
    // shell.qml and the collapsed pill still bind to their values, and their
    // polling timers run regardless of visibility.
    Volume {
        id: volumeSource

        visible: false
    }

    Brightness {
        id: brightnessSource

        visible: false
    }

    // Host object for the Omarchy panels imported under panels/.
    OmarchyBarApi {
        id: barApi

        window: barWindow.contentItem
        barSize: 30
        position: "top"
    }

    BarDragController {
        id: barDrag

        editMode: barWindow.editMode
        vertical: false
        barApi: barApi
    }

    // The media widget dims itself unless something is playing; keeping its
    // popup open has to override that, and it can no longer be set as a
    // property on a widget the bar does not declare.
    Binding {
        target: barWindow.playerWidget
        property: "forceVisible"
        value: playerPopupLoader.active
        when: barWindow.playerWidget !== null
    }

    QsIo.IpcHandler {
        target: "bar"

        function editMode(): void {
            barWindow.toggleEditMode();
        }

        function editModeOff(): void {
            barWindow.toggleEditMode(false);
        }

        function resetLayout(): void {
            BarConfig.resetLayout();
        }
    }


    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: barWindow.barExpanded ? 30 : ((barWindow.isHovered || barWindow.powermenuActive || (barWindow.activeToastNotification !== null && barWindow.toastHasBody)) ? 64 : 30)
    margins.top: barWindow.barExpanded ? 0 : 4
    color: "transparent"
    WlrLayershell.exclusiveZone: 30
    WlrLayershell.keyboardFocus: powermenuActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: barNotifToastTimer

        interval: 3000
        repeat: false
        onTriggered: {
            barWindow.activeToastNotification = null;
        }
    }

    Timer {
        id: barOsdTimer

        interval: 1800
        repeat: false
        onTriggered: {
            barWindow.osdMode = "";
        }
    }

    Timer {
        id: wrappedPowermenuDismissTimer

        interval: 3000
        repeat: false
        onTriggered: {
            barWindow.powermenuActive = false;
        }
    }


    Rectangle {
        id: barBg

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: barWindow.barExpanded ? 30 : ((barWindow.isHovered || barWindow.powermenuActive || (barWindow.activeToastNotification !== null && barWindow.toastHasBody)) ? 64 : 30)
        color: "#11111b"
        width: barWindow.barExpanded ? parent.width : (barWindow.powermenuActive ? 260 : ((barWindow.isHovered || (barWindow.activeToastNotification !== null && barWindow.toastHasBody)) ? 360 : (barWindow.activeToastNotification !== null ? 220 : (barWindow.osdMode !== "" ? 170 : (barClock.width + 10)))))
        radius: barWindow.barExpanded ? 0 : ((barWindow.isHovered || barWindow.powermenuActive || (barWindow.activeToastNotification !== null && barWindow.toastHasBody)) ? 24 : 15)
        clip: true

        MouseArea {
            id: barMouseArea

            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (barWindow.powermenuActive && !barWindow.barExpanded) {
                    wrappedPowermenuDismissTimer.stop();
                }
                if (!barWindow.barExpanded && !barWindow.powermenuActive)
                    hoverTimer.start();

            }
            onExited: {
                hoverTimer.stop();
                barWindow.isHovered = false;
                if (barWindow.powermenuActive && !barWindow.barExpanded) {
                    wrappedPowermenuDismissTimer.restart();
                }
            }


            Timer {
                id: hoverTimer

                interval: 750
                repeat: false
                onTriggered: {
                    if (barMouseArea.containsMouse && !barWindow.barExpanded && !barWindow.powermenuActive && barWindow.osdMode === "" && barWindow.activeToastNotification === null)
                        barWindow.isHovered = true;

                }
            }

            Clock {
                id: barClock

                anchors.centerIn: parent
                height: parent.height
                barExpanded: barWindow.barExpanded
                isMusicPlaying: barWindow.playerWidget ? barWindow.playerWidget.isPlaying : false
                states: [
                    State {
                        name: "visible"
                        when: barWindow.barExpanded || (!barWindow.isHovered && !barWindow.powermenuActive && barWindow.osdMode === "" && barWindow.activeToastNotification === null)

                        PropertyChanges {
                            target: barClock
                            opacity: 1
                        }

                    },
                    State {
                        name: "hidden"
                        when: !barWindow.barExpanded && (barWindow.isHovered || barWindow.powermenuActive || barWindow.osdMode !== "" || barWindow.activeToastNotification !== null)

                        PropertyChanges {
                            target: barClock
                            opacity: 0
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 0
                        }

                    },
                    Transition {
                        from: "hidden"
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: 250
                            }

                            NumberAnimation {
                                properties: "opacity"
                                duration: 200
                                easing.type: Easing.OutQuad
                            }

                        }

                    }
                ]
            }

            MouseArea {
                id: clockClickArea

                anchors.fill: barClock
                cursorShape: Qt.PointingHandCursor
                enabled: barClock.opacity > 0.9
                onClicked: {
                    hoverTimer.stop();
                    barWindow.barExpanded = !barWindow.barExpanded;
                    barWindow.isHovered = false;
                    barWindow.powermenuActive = false;
                }
            }

            // Morphing OSD Toast Content inside Bar Capsule
            Item {
                id: barOsdContent

                anchors.fill: parent
                states: [
                    State {
                        name: "visible"
                        when: !barWindow.barExpanded && !barWindow.isHovered && !barWindow.powermenuActive && barWindow.osdMode !== ""

                        PropertyChanges {
                            target: barOsdContent
                            opacity: 1
                        }

                    },
                    State {
                        name: "hidden"
                        when: barWindow.barExpanded || barWindow.isHovered || barWindow.powermenuActive || barWindow.osdMode === ""


                        PropertyChanges {
                            target: barOsdContent
                            opacity: 0
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: 150
                            }

                            NumberAnimation {
                                properties: "opacity"
                                duration: 150
                                easing.type: Easing.OutQuad
                            }

                        }

                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 0
                        }

                    }
                ]

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: {
                            if (barWindow.osdMode === "volume") {
                                if (barWindow.osdMuted || barWindow.osdVolume <= 0)
                                    return "volume_off";

                                if (barWindow.volumeWidget && barWindow.volumeWidget.isHeadphones)
                                    return "headphones";

                                if (barWindow.osdVolume < 33)
                                    return "volume_down";

                                if (barWindow.osdVolume < 66)
                                    return "volume_down";

                                return "volume_up";
                            } else if (barWindow.osdMode === "brightness") {
                                if (barWindow.osdBrightness <= 0)
                                    return "brightness_low";

                                if (barWindow.osdBrightness < 33)
                                    return "brightness_low";

                                if (barWindow.osdBrightness < 66)
                                    return "brightness_medium";

                                return "brightness_high";
                            }
                            return "";
                        }
                        color: {
                            if (barWindow.osdMode === "volume")
                                return barWindow.osdMuted ? Style.red : Style.mauve;
                            else
                                return Style.lavender;
                        }
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: 120
                        height: 4
                        radius: 2
                        color: Style.surface0
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            height: parent.height
                            radius: 2
                            color: {
                                if (barWindow.osdMode === "volume")
                                    return barWindow.osdMuted ? Style.overlay1 : Style.mauve;
                                else
                                    return Style.lavender;
                            }
                            width: parent.width * ((barWindow.osdMode === "volume" ? barWindow.osdVolume : barWindow.osdBrightness) / 100)

                            Behavior on width {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }

                            }

                        }

                    }

                }

            }

            // --- Hover State Expanded Content ---
            Item {
                id: hoverContent

                anchors.fill: parent
                visible: opacity > 0
                states: [
                    State {
                        name: "visible"
                        when: barWindow.isHovered && !barWindow.powermenuActive && !barWindow.barExpanded && barBg.width > 220 && !barWindow.hasMedia

                        PropertyChanges {
                            target: hoverContent
                            opacity: 1
                        }

                    },
                    State {
                        name: "hidden"
                        when: !barWindow.isHovered || barWindow.powermenuActive || barWindow.barExpanded || barBg.width <= 220 || barWindow.hasMedia


                        PropertyChanges {
                            target: hoverContent
                            opacity: 0
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 100
                            easing.type: Easing.OutQuad
                        }

                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 0
                        }

                    }
                ]

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

            }

            // --- Hover State Player Content (When Music is Playing) ---
            Item {
                id: hoverPlayerContent

                anchors.fill: parent
                visible: opacity > 0
                states: [
                    State {
                        name: "visible"
                        when: barWindow.isHovered && !barWindow.powermenuActive && !barWindow.barExpanded && barBg.width > 220 && barWindow.hasMedia

                        PropertyChanges {
                            target: hoverPlayerContent
                            opacity: 1
                        }

                    },
                    State {
                        name: "hidden"
                        when: !barWindow.isHovered || barWindow.powermenuActive || barWindow.barExpanded || barBg.width <= 220 || !barWindow.hasMedia


                        PropertyChanges {
                            target: hoverPlayerContent
                            opacity: 0
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 100
                            easing.type: Easing.OutQuad
                        }

                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 0
                        }

                    }
                ]

                // Album Art on Left
                Rectangle {
                    id: hoverPlayerArt

                    width: 44
                    height: 44
                    radius: 8
                    color: Style.surface1
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: (barWindow.playerWidget && barWindow.playerWidget.localArtUrl !== "") ? barWindow.playerWidget.localArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: source !== "" && status === Image.Ready
                        asynchronous: true
                    }

                    Text {
                        text: "music_note"
                        color: Style.subtext1
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        anchors.centerIn: parent
                        visible: !barWindow.playerWidget || barWindow.playerWidget.localArtUrl === ""
                    }

                }

                // Controls on Right
                Row {
                    id: hoverPlayerControls

                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // Previous Track
                    MouseArea {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (barWindow.playerWidget) barWindow.playerWidget.prevTrack()

                        Text {
                            text: "skip_previous"
                            color: parent.containsMouse ? Style.mauve : Style.text
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }

                    }

                    // Play/Pause Circle
                    Rectangle {
                        id: hoverPlayButton

                        width: 32
                        height: 32
                        radius: 16
                        color: hoverPlayMouse.containsMouse ? "#f5e0dc" : "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        scale: hoverPlayMouse.containsMouse ? 1.08 : 1

                        Text {
                            text: barWindow.playerWidget && barWindow.playerWidget.isPlaying ? "pause" : "play_arrow"
                            color: "#11111b"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: hoverPlayMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (barWindow.playerWidget) barWindow.playerWidget.togglePlay()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }

                        }

                    }

                    // Next Track
                    MouseArea {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (barWindow.playerWidget) barWindow.playerWidget.nextTrack()

                        Text {
                            text: "skip_next"
                            color: parent.containsMouse ? Style.mauve : Style.text
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }

                    }

                }

                // Middle Text Details
                Column {
                    anchors.left: hoverPlayerArt.right
                    anchors.right: hoverPlayerControls.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: barWindow.playerWidget ? barWindow.playerWidget.title : ""
                        color: Style.text
                        font.family: Style.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: barWindow.playerWidget ? barWindow.playerWidget.artist : ""
                        color: Style.subtext0
                        font.family: Style.fontFamily
                        font.pixelSize: 10
                        width: parent.width
                        elide: Text.ElideRight
                        visible: barWindow.playerWidget !== null && barWindow.playerWidget.artist !== ""
                    }

                }

            }

            // --- Hover State Notification Toast Content (When Notification arrives) ---
            Item {
                id: hoverNotifContent

                anchors.fill: parent
                visible: opacity > 0
                states: [
                    State {
                        name: "visible"
                        when: !barWindow.barExpanded && barBg.width > 160 && barWindow.activeToastNotification !== null && !barWindow.isHovered && !barWindow.powermenuActive

                        PropertyChanges {
                            target: hoverNotifContent
                            opacity: 1
                        }

                    },
                    State {
                        name: "hidden"
                        when: barWindow.barExpanded || barBg.width <= 160 || barWindow.activeToastNotification === null || barWindow.isHovered || barWindow.powermenuActive


                        PropertyChanges {
                            target: hoverNotifContent
                            opacity: 0
                        }

                    }
                ]
                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 100
                            easing.type: Easing.OutQuad
                        }

                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 100
                        }

                    }
                ]

                // Icon on Left
                Item {
                    id: notifIcon

                    width: barWindow.toastHasBody ? 20 : 12
                    height: barWindow.toastHasBody ? 20 : 12
                    anchors.left: parent.left
                    anchors.leftMargin: barWindow.toastHasBody ? 16 : 10
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: notifAppIcon

                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: source != ""
                        source: {
                            if (barWindow.activeToastNotification && barWindow.activeToastNotification.icon) {
                                var iconName = barWindow.activeToastNotification.icon;
                                if (iconName.indexOf("/") === 0)
                                    return "file://" + iconName;

                                var resolved = Quickshell.iconPath(iconName);
                                if (resolved)
                                    return (resolved.toString().indexOf("/") === 0) ? "file://" + resolved : resolved;

                            }
                            return "";
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: "notifications"
                        color: barWindow.toastHasBody ? Style.mauve : "#ffffff"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: barWindow.toastHasBody ? 20 : 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        visible: !notifAppIcon.visible
                    }

                }

                // Styled Close Button on Right (only visible when notification has a body)
                Rectangle {
                    id: notifCloseBtn

                    width: barWindow.toastHasBody ? 24 : 18
                    height: barWindow.toastHasBody ? 24 : 18
                    radius: barWindow.toastHasBody ? 12 : 9
                    color: closeMouseArea.containsMouse ? Qt.rgba(243 / 255, 139 / 255, 168 / 255, 0.15) : "transparent"
                    anchors.right: parent.right
                    anchors.rightMargin: barWindow.toastHasBody ? 16 : 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: barWindow.toastHasBody

                    Text {
                        text: "close"
                        color: closeMouseArea.containsMouse ? Style.red : Style.overlay1
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: barWindow.toastHasBody ? 16 : 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: closeMouseArea

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            barWindow.activeToastNotification = null;
                        }
                    }

                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: barWindow.toastHasBody ? notifCloseBtn.left : parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    cursorShape: {
                        if (barWindow.activeToastNotification) {
                            var appName = (barWindow.activeToastNotification.appName || "").toLowerCase();
                            var isBrowser = (appName.indexOf("firefox") !== -1 ||
                                             appName.indexOf("chrome") !== -1 ||
                                             appName.indexOf("chromium") !== -1 ||
                                             appName.indexOf("zen") !== -1 ||
                                             appName.indexOf("web") !== -1);
                            return isBrowser ? Qt.PointingHandCursor : Qt.ArrowCursor;
                        }
                        return Qt.ArrowCursor;
                    }
                    onClicked: {
                        if (barWindow.activeToastNotification) {
                            var appName = (barWindow.activeToastNotification.appName || "").toLowerCase();
                            var isBrowser = (appName.indexOf("firefox") !== -1 ||
                                             appName.indexOf("chrome") !== -1 ||
                                             appName.indexOf("chromium") !== -1 ||
                                             appName.indexOf("zen") !== -1 ||
                                             appName.indexOf("web") !== -1);
                            if (isBrowser) {
                                barWindow.activeToastNotification.invokeAction("default");
                                barWindow.activeToastNotification = null;
                            }
                        }
                    }
                }

                // Notification Content Column
                Column {
                    anchors.left: notifIcon.right
                    anchors.right: barWindow.toastHasBody ? notifCloseBtn.left : parent.right
                    anchors.leftMargin: barWindow.toastHasBody ? 12 : 8
                    anchors.rightMargin: barWindow.toastHasBody ? 12 : 12
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (barWindow.activeToastNotification !== null && barWindow.toastHasBody) ? 0 : 1
                    spacing: 1

                    // Summary (Title)
                    Text {
                        text: (barWindow.activeToastNotification !== null && barWindow.activeToastNotification.summary) ? barWindow.activeToastNotification.summary : ""
                        color: barWindow.toastHasBody ? Style.text : "#ffffff"
                        font.family: Style.fontFamily
                        font.pixelSize: barWindow.toastHasBody ? 13 : 10
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    // Body
                    Text {
                        text: (barWindow.activeToastNotification !== null && barWindow.activeToastNotification.body) ? barWindow.activeToastNotification.body : ""
                        color: Style.subtext1
                        font.family: Style.fontFamily
                        font.pixelSize: 11
                        width: parent.width
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                }

            }

            // --- Hover State Powermenu Content ---
            Item {
                id: hoverPowermenuContent

                anchors.fill: parent
                visible: opacity > 0
                focus: visible

                property int activeIndex: 0

                onVisibleChanged: {
                    if (visible) {
                        forceActiveFocus();
                        activeIndex = 0;
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                            activeIndex = (activeIndex - 1 + 3) % 3;
                        } else {
                            activeIndex = (activeIndex + 1) % 3;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        if (activeIndex === 0) {
                            barLogoutProc.running = true;
                        } else if (activeIndex === 1) {
                            barRebootProc.running = true;
                        } else if (activeIndex === 2) {
                            barShutdownProc.running = true;
                        }
                        barWindow.powermenuActive = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        barWindow.powermenuActive = false;
                        event.accepted = true;
                    }
                }

                states: [
                    State {
                        name: "visible"
                        when: !barWindow.barExpanded && barWindow.powermenuActive && barBg.width > 220

                        PropertyChanges {
                            target: hoverPowermenuContent
                            opacity: 1
                        }
                    },
                    State {
                        name: "hidden"
                        when: barWindow.barExpanded || !barWindow.powermenuActive || barBg.width <= 220

                        PropertyChanges {
                            target: hoverPowermenuContent
                            opacity: 0
                        }
                    }
                ]
                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        NumberAnimation {
                            properties: "opacity"
                            duration: 0
                        }
                    }
                ]

                Row {
                    anchors.centerIn: parent
                    spacing: 24

                    // Logout
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: (barLogoutMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 0)) ? Style.surface1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            text: "logout"
                            color: (barLogoutMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 0)) ? Style.red : Style.lavender
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: barLogoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                barLogoutProc.running = true;
                                barWindow.powermenuActive = false;
                            }
                            onEntered: wrappedPowermenuDismissTimer.stop()
                            onExited: wrappedPowermenuDismissTimer.restart()
                        }
                    }

                    // Reboot
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: (barRebootMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 1)) ? Style.surface1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            text: "restart_alt"
                            color: (barRebootMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 1)) ? Style.red : Style.lavender
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: barRebootMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                barRebootProc.running = true;
                                barWindow.powermenuActive = false;
                            }
                            onEntered: wrappedPowermenuDismissTimer.stop()
                            onExited: wrappedPowermenuDismissTimer.restart()
                        }
                    }

                    // Shutdown
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: (barShutdownMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 2)) ? Style.surface1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            text: "power_settings_new"
                            color: (barShutdownMouse.containsMouse || (hoverPowermenuContent.focus && hoverPowermenuContent.activeIndex === 2)) ? Style.red : Style.lavender
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: barShutdownMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                barShutdownProc.running = true;
                                barWindow.powermenuActive = false;
                            }
                            onEntered: wrappedPowermenuDismissTimer.stop()
                            onExited: wrappedPowermenuDismissTimer.restart()
                        }
                    }
                }

                QsIo.Process {
                    id: barLogoutProc
                    command: ["sh", "-c", "hyprshutdown -t 'Loging Out... ' --post-cmd 'logout -P 0'"]
                }

                QsIo.Process {
                    id: barRebootProc
                    command: ["sh", "-c", "reboot"]
                }

                QsIo.Process {
                    id: barShutdownProc
                    command: ["sh", "-c", "hyprshutdown -t 'Shutting Down...' --post-cmd 'shutdown -P 0'"]
                }
            }

        }

        Behavior on width {
            SequentialAnimation {
                PauseAnimation {
                    duration: (!barWindow.barExpanded) ? 100 : 0
                }

                NumberAnimation {
                    duration: 450
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.6
                }

            }

        }

        Behavior on height {
            enabled: !barWindow.isHovered && !barWindow.powermenuActive

            NumberAnimation {
                duration: 450
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }

        }

        Behavior on radius {
            enabled: !barWindow.isHovered && !barWindow.powermenuActive


            SequentialAnimation {
                PauseAnimation {
                    duration: barWindow.barExpanded ? 300 : 0
                }

                NumberAnimation {
                    duration: barWindow.barExpanded ? 100 : 450
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.6
                }

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
        opacity: barWindow.barExpanded ? 1 : 0

        // Widget order comes from bar.json's right section. The separators
        // that used to sit between these by hand are layout entries now, so
        // they move with whatever they were separating.
        BarSection {
            region: "right"
            controller: barDrag
            anchors.verticalCenter: parent.verticalCenter

            onWidgetHovered: (id, isHovered) => barWindow.routeWidgetHover(id, isHovered)
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1
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

    }

    // --- Hamburger Button Card ---
    Rectangle {
        id: hamburgerButton

        anchors.left: workspacesWidget.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 8
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

    // --- Smoothly Collapsible Modules Container ---
    Item {
        id: modulesContainer

        property int marginVal: barWindow.modulesExpanded ? 10 : 0

        anchors.left: hamburgerButton.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        clip: true
        anchors.leftMargin: marginVal
        width: barWindow.modulesExpanded ? leftSection.width : 0
        opacity: (barWindow.barExpanded && barWindow.modulesExpanded) ? 1 : 0

        // Widget order comes from bar.json's left section.
        BarSection {
            id: leftSection

            region: "left"
            controller: barDrag
            spacing: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            onWidgetHovered: (id, isHovered) => barWindow.routeWidgetHover(id, isHovered)
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

    Behavior on margins.top {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }

    }

    mask: Region {
        item: barBg
    }

}
