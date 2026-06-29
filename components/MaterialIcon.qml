import QtQuick

Text {
    id: root

    property int size: 20

    font.family: materialFont.name
    font.pixelSize: size
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    FontLoader {
        id: materialFont

        source: "/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    }

}
