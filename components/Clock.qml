import QtQuick

Rectangle {
    id: clockRoot

    property var currentTime: new Date()
    property bool barExpanded: true

    implicitWidth: clockRow.implicitWidth + 16
    implicitHeight: 22
    color: "transparent"
    radius: 6

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "calendar_month"
            visible: !clockRoot.barExpanded
            color: Style.text
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: clockText
            text: Qt.formatDateTime(clockRoot.currentTime, "HH:mm / MMM dd")
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Style.fontWeight
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockRoot.currentTime = new Date()
    }
}
