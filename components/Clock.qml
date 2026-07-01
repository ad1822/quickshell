import QtQuick
import "../components"

Rectangle {
    id: clockRoot

    property var currentTime: new Date()
    property bool barExpanded: true
    property bool isMusicPlaying: false

    implicitWidth: clockRow.implicitWidth + 16
    implicitHeight: 22
    color: "transparent"
    radius: 6

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 6

        // 1. Calendar Icon (Only visible when wrapped and music NOT playing)
        Text {
            id: calendarIcon
            text: "calendar_month"
            color: Style.overlay1
            font.family: "Material Symbols Rounded"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            
            opacity: clockRoot.barExpanded ? 0.0 : (clockRoot.isMusicPlaying ? 0.0 : 1.0)
            width: clockRoot.barExpanded ? 0 : (clockRoot.isMusicPlaying ? 0 : 14)
            clip: true

            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        }

        // 1.5 Dynamic Music Visualizer (Only visible when wrapped and music IS playing)
        Item {
            id: miniVisualizerContainer
            anchors.verticalCenter: parent.verticalCenter
            height: 12
            
            opacity: (clockRoot.barExpanded || !clockRoot.isMusicPlaying) ? 0.0 : 1.0
            width: (clockRoot.barExpanded || !clockRoot.isMusicPlaying) ? 0 : 14
            clip: true

            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            Row {
                id: miniVisualizer
                spacing: 2
                anchors.centerIn: parent
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
                        running: clockRoot.isMusicPlaying
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
                        running: clockRoot.isMusicPlaying
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
                            duration: 350
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Rectangle {
                    id: bar3
                    width: 2
                    height: 5
                    radius: 1
                    color: Style.mauve
                    anchors.bottom: parent.bottom

                    SequentialAnimation {
                        running: clockRoot.isMusicPlaying
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: bar3
                            property: "height"
                            from: 2
                            to: 12
                            duration: 450
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            target: bar3
                            property: "height"
                            from: 12
                            to: 2
                            duration: 400
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
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
