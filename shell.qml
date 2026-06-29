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
    }

}
