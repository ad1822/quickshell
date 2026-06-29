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
    // Exposed local art URL that is 100% safe from Qt SSL bugs and caching issues
    property string localArtUrl: ""
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    // Position and Length (in seconds)
    readonly property double position: activePlayer ? activePlayer.position : 0
    readonly property double length: activePlayer ? activePlayer.length : 0
    // Track metadata caching to handle partial browser MPRIS updates
    property string lastTitle: ""
    property string lastArtist: ""
    // Pure declarative raw artwork source URL (monitored by QML binding engine)
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

    // Upgrade image sizes to high-resolution (bypasses low-res defaults from YT Music/YouTube)
    function upgradeArtUrlQuality(url) {
        if (!url)
            return "";

        url = url.trim();
        if (url === "")
            return "";

        // Upgrade Google User Content / Ggpht cover art sizes (used by YT Music)
        if (url.indexOf("googleusercontent.com") !== -1 || url.indexOf("ggpht.com") !== -1) {
            // Replace =w120-h120 size parameters with high-res =w544-h544
            url = url.replace(/=w\d+-h\d+/, "=w544-h544");
            // Replace =s120 square parameters with high-res =s512
            url = url.replace(/=s\d+/, "=s512");
        }
        // Upgrade YouTube watch thumbnails to maxresdefault (HD)
        if (url.indexOf("img.youtube.com/vi/") !== -1)
            url = url.replace(/\/[^\/]+\.jpg$/, "/maxresdefault.jpg");

        return url;
    }

    // Handle track changes and protect against partial updates blanking the artwork
    function handleTrackChange() {
        var currentTitle = title.trim();
        var currentArtist = artist.trim();
        var currentRawArt = rawArtUrl.trim();
        // If the song has changed, reset the artwork
        if (currentTitle !== lastTitle || currentArtist !== lastArtist) {
            lastTitle = currentTitle;
            lastArtist = currentArtist;
            localArtUrl = "";
        }
        // If the new rawArtUrl is empty but we already have a loaded artwork for this song,
        // preserve it rather than overwriting with empty
        if (currentRawArt === "")
            return ;

        // Upgrade artwork quality parameter before downloading
        var highResUrl = upgradeArtUrlQuality(currentRawArt);
        if (highResUrl.indexOf("http://") === 0 || highResUrl.indexOf("https://") === 0) {
            artCounter++;
            downloadArtProc.command = ["curl", "-L", "-s", "-o", "/tmp/quickshell_art_" + artCounter + ".jpg", highResUrl];
            downloadArtProc.running = true;
        } else {
            // Already a local path or file:// URL
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
    visible: true

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
        spacing: 6

        // Icon indicating status
        Text {
            text: {
                if (playerWidget.activePlayer === null)
                    return "music_off";

                return playerWidget.isPlaying ? "music_note" : "music_off";
            }
            color: Style.mauve
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
            verticalAlignment: Text.AlignVCenter
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
            width: Math.min(implicitWidth, 200)
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
