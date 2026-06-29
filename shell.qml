import QtQuick
import Quickshell
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
                volumeOsd.trigger(barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted);
            }
        }

        function onIsMutedChanged() {
            if (!initialized) {
                initialized = true;
                return;
            }
            if (!barWindow.volumeWidget.isAdjusting) {
                volumeOsd.trigger(barWindow.volumeWidget.volume, barWindow.volumeWidget.isMuted);
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
                brightnessOsd.trigger(barWindow.brightnessWidget.brightness);
            }
        }
    }
}
