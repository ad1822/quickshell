import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "modules"

ShellRoot {
    id: root

    readonly property string fontFamily: "Iosevka"

    FontLoader {
        source: "/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    }

    Bar {
        id: barWindow
    }

    VolumeOsd {
        id: volumeOsd
    }

    BrightnessOsd {
        id: brightnessOsd
    }

    Spotlight {
        id: spotlightWindow
    }

    WallpaperSwitcher {
        id: wallpaperWindow
    }

    Connections {
        target: barWindow.volumeWidget

        // Ignore the initial property bind on startup to prevent boot notifications
        property bool initialized: false

        function onVolumeChanged() {
            if (!initialized) {
                if (barWindow.volumeWidget.volume > 0) {
                    initialized = true;
                }
                return;
            }
            if (!barWindow.volumeWidget.isAdjusting) {
                if (!barWindow.barExpanded && !barWindow.isHovered) {
                    barWindow.triggerBarOsd("volume", barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted);
                } else {
                    volumeOsd.trigger(barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted, barWindow.volumeWidget.isHeadphones);
                }
            }
        }

        function onIsMutedChanged() {
            if (!initialized) {
                initialized = true;
                return;
            }
            if (!barWindow.volumeWidget.isAdjusting) {
                if (!barWindow.barExpanded && !barWindow.isHovered) {
                    barWindow.triggerBarOsd("volume", barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted);
                } else {
                    volumeOsd.trigger(barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted, barWindow.volumeWidget.isHeadphones);
                }
            }
        }

        function onIsHeadphonesChanged() {
            if (!initialized) {
                initialized = true;
                return;
            }
            if (!barWindow.volumeWidget.isAdjusting) {
                if (!barWindow.barExpanded && !barWindow.isHovered) {
                    barWindow.triggerBarOsd("volume", barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted);
                } else {
                    volumeOsd.trigger(barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted, barWindow.volumeWidget.isHeadphones);
                }
            }
        }
    }

    Connections {
        target: barWindow.brightnessWidget

        property bool initialized: false

        function onBrightnessChanged() {
            if (!initialized) {
                if (barWindow.brightnessWidget.brightness > 0) {
                    initialized = true;
                }
                return;
            }
            if (!barWindow.brightnessWidget.isAdjusting) {
                if (!barWindow.barExpanded && !barWindow.isHovered) {
                    barWindow.triggerBarOsd("brightness", barWindow.brightnessWidget.brightness);
                } else {
                    brightnessOsd.trigger(barWindow.brightnessWidget.brightness);
                }
            }
        }
    }

    Notifications {
        id: notificationWindow
    }

    NotificationServer {
        id: globalNotifServer
        onNotification: (n) => {
            console.log("Global received notification! summary:", n.summary);
            n.tracked = true;
            if (!barWindow.barExpanded) {
                barWindow.activeToastNotification = {
                    appName: n.appName,
                    summary: n.summary,
                    body: n.body
                };
                barWindow.restartToastTimer();
            }
            notificationWindow.activeNotificationsCount = globalNotifServer.trackedNotifications.rowCount();
        }
    }

    Connections {
        target: globalNotifServer.trackedNotifications
        function onRowsInserted() {
            notificationWindow.activeNotificationsCount = globalNotifServer.trackedNotifications.rowCount();
        }
        function onRowsRemoved() {
            notificationWindow.activeNotificationsCount = globalNotifServer.trackedNotifications.rowCount();
        }
        function onModelReset() {
            notificationWindow.activeNotificationsCount = globalNotifServer.trackedNotifications.rowCount();
        }
    }
}
