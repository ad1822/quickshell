import QtQuick
import "../components"

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

        // 1. Calendar Icon (Only visible when wrapped)
        Text {
            id: calendarIcon
            text: "calendar_month"
            color: Style.overlay1
            font.family: "Material Symbols Rounded"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            
            opacity: clockRoot.barExpanded ? 0.0 : 1.0
            width: clockRoot.barExpanded ? 0 : 14
            clip: true

            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        }

        // 2. Pulse Time (Hours & Minutes)
        Row {
            spacing: 1

            Text {
                text: Qt.formatDateTime(clockRoot.currentTime, "HH")
                color: Style.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.weight: Font.Bold
            }

            // Pulsing Colon separator
            Text {
                text: ":"
                color: Style.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.weight: Font.Bold
                
                opacity: 1.0
                NumberAnimation on opacity {
                    from: 0.3
                    to: 1.0
                    duration: 1000
                    loops: Animation.Infinite
                    easing.type: Easing.InOutQuad
                }
            }

            Text {
                text: Qt.formatDateTime(clockRoot.currentTime, "mm")
                color: Style.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.weight: Font.Bold
            }
        }

        // 3. Dot Separator (Only visible when unwrapped)
        Text {
            text: "•"
            color: Style.mauve
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            verticalAlignment: Text.AlignVCenter
            
            opacity: clockRoot.barExpanded ? 1.0 : 0.0
            width: clockRoot.barExpanded ? 8 : 0
            clip: true

            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        }

        // 4. Detailed Date (Expands and fades in when unwrapped)
        Item {
            id: dateContainer
            height: parent.height
            
            width: clockRoot.barExpanded ? dateText.implicitWidth : 0
            opacity: clockRoot.barExpanded ? 1.0 : 0.0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }

            Text {
                id: dateText
                text: Qt.formatDateTime(clockRoot.currentTime, "ddd, MMM dd")
                color: Style.text
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize
                font.weight: Style.fontWeight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockRoot.currentTime = new Date()
    }
}
