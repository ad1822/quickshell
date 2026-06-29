import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: playerWidget

    // Active player selection: prioritize currently playing player, then fall back to the first available
    readonly property MprisPlayer activePlayer: {
        var players = Mpris.players.values;
        if (players.length === 0)
            return null;

        var playingPlayer = players.find((p) => {
            return p.isPlaying;
        });
        if (playingPlayer)
            return playingPlayer;

        return players[0];
    }
    // Exposed properties mapped to the native MPRIS player
    readonly property string status: activePlayer ? (activePlayer.isPlaying ? "Playing" : "Paused") : "Stopped"
    readonly property string title: activePlayer ? activePlayer.trackTitle : ""
    readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
    readonly property string playerName: activePlayer ? activePlayer.identity : ""
    // Counter to generate unique cache-bypassing filenames for curl
    property int artCounter: 0
    // Exposed local art URL that is safe from caching issues
    property string localArtUrl: ""
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    // Position and Length (in seconds)
    readonly property double position: activePlayer ? activePlayer.position : 0
    readonly property double length: activePlayer ? activePlayer.length : 0
    // Track metadata caching
    property string lastTitle: ""
    property string lastArtist: ""
    // Pure declarative raw artwork source URL
    readonly property string rawArtUrl: {
        if (!activePlayer)
            return "";

        var art = activePlayer.trackArtUrl;
        if (art && art.toString() !== "")
            return art.toString();

        var xesamUrl = activePlayer.metadata["xesam:url"];
        if (xesamUrl)
            return getYoutubeThumbnail(xesamUrl);

        return "";
    }
    property bool forceVisible: false

    signal hovered(bool isHovered)

    // Playback control functions
    function togglePlay() {
        if (activePlayer && activePlayer.canTogglePlaying)
            activePlayer.togglePlaying();

    }

    // Seek control functions
    function seekTo(seconds) {
        if (activePlayer && activePlayer.canSeek)
            activePlayer.position = seconds;

    }

    function nextTrack() {
        if (activePlayer && activePlayer.canGoNext)
            activePlayer.next();

    }

    function prevTrack() {
        if (activePlayer && activePlayer.canGoPrevious)
            activePlayer.previous();

    }

    // Extract YouTube video thumbnail URL
    function getYoutubeThumbnail(url) {
        if (!url)
            return "";

        var str = url.toString();
        var match = str.match(/[?&]v=([\w-]{11})/);
        if (match)
            return "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg";

        var shortMatch = str.match(/youtu\.be\/([\w-]{11})/);
        if (shortMatch)
            return "https://img.youtube.com/vi/" + shortMatch[1] + "/hqdefault.jpg";

        return "";
    }

    // Upgrade image sizes to high-resolution
    function upgradeArtUrlQuality(url) {
        if (!url)
            return "";

        url = url.trim();
        if (url === "")
            return "";

        if (url.indexOf("googleusercontent.com") !== -1 || url.indexOf("ggpht.com") !== -1) {
            url = url.replace(/=w\d+-h\d+/, "=w544-h544");
            url = url.replace(/=s\d+/, "=s512");
        }
        if (url.indexOf("img.youtube.com/vi/") !== -1)
            url = url.replace(/\/[^\/]+\.jpg$/, "/maxresdefault.jpg");

        return url;
    }

    // Handle track changes and protect against partial updates blanking the artwork
    function handleTrackChange() {
        var currentTitle = title.trim();
        var currentArtist = artist.trim();
        var currentRawArt = rawArtUrl.trim();
        if (currentTitle !== lastTitle || currentArtist !== lastArtist) {
            lastTitle = currentTitle;
            lastArtist = currentArtist;
            localArtUrl = "";
        }
        if (currentRawArt === "")
            return ;

        var highResUrl = upgradeArtUrlQuality(currentRawArt);
        if (highResUrl.indexOf("http://") === 0 || highResUrl.indexOf("https://") === 0) {
            artCounter++;
            downloadArtProc.command = ["curl", "-L", "-s", "-o", "/tmp/quickshell_art_" + artCounter + ".jpg", highResUrl];
            downloadArtProc.running = true;
        } else {
            localArtUrl = highResUrl;
        }
    }

    onTitleChanged: handleTrackChange()
    onArtistChanged: handleTrackChange()
    onRawArtUrlChanged: handleTrackChange()
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight
    width: implicitWidth
    height: implicitHeight
    visible: activePlayer !== null

    // Process helper to run curl in the background
    Process {
        id: downloadArtProc

        onExited: (exitCode) => {
            if (exitCode === 0)
                playerWidget.localArtUrl = "file:///tmp/quickshell_art_" + artCounter + ".jpg";
            else
                playerWidget.localArtUrl = "";
        }
    }

    // Timer to poll elapsed playback position when player is playing
    Timer {
        id: progressTimer

        interval: 500
        running: playerWidget.isPlaying && activePlayer !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (activePlayer)
                activePlayer.positionChanged();

        }
    }

    Row {
        id: rowLayout

        anchors.fill: parent
        spacing: 8

        // Premium Animated Music Visualizer (Bounces when playing, freezes when paused)
        Row {
            id: miniVisualizer

            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            height: 12
            width: 10

            Rectangle {
                id: bar1

                width: 2
                height: 4
                radius: 1
                color: Style.mauve
                anchors.bottom: parent.bottom

                SequentialAnimation {
                    running: playerWidget.isPlaying
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: bar1
                        property: "height"
                        from: 3
                        to: 12
                        duration: 400
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: bar1
                        property: "height"
                        from: 12
                        to: 3
                        duration: 350
                        easing.type: Easing.InOutSine
                    }

                }

            }

            Rectangle {
                id: bar2

                width: 2
                height: 6
                radius: 1
                color: Style.pink
                anchors.bottom: parent.bottom

                SequentialAnimation {
                    running: playerWidget.isPlaying
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: bar2
                        property: "height"
                        from: 4
                        to: 11
                        duration: 300
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: bar2
                        property: "height"
                        from: 11
                        to: 4
                        duration: 450
                        easing.type: Easing.InOutSine
                    }

                }

            }

            Rectangle {
                id: bar3

                width: 2
                height: 3
                radius: 1
                color: Style.blue
                anchors.bottom: parent.bottom

                SequentialAnimation {
                    running: playerWidget.isPlaying
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: bar3
                        property: "height"
                        from: 2
                        to: 10
                        duration: 500
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        target: bar3
                        property: "height"
                        from: 10
                        to: 2
                        duration: 300
                        easing.type: Easing.InOutSine
                    }

                }

            }

        }

        // Song Title & Artist text
        Text {
            text: playerWidget.artist !== "" ? (playerWidget.title + " - " + playerWidget.artist) : playerWidget.title
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 180)
        }

    }

    // Media interaction controls
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: playerWidget.togglePlay()
        onEntered: playerWidget.hovered(true)
        onExited: playerWidget.hovered(false)
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                playerWidget.nextTrack();
            else if (wheel.angleDelta.y < 0)
                playerWidget.prevTrack();
        }
    }

}
