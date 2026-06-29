import QtQuick
import Quickshell.Hyprland

Rectangle {
  id: root
  width: row.width + 16
  height: row.height + 16
  color: Style.base
  radius: 6

  Row {
    id: row
    spacing: 8
    anchors.centerIn: parent

    Repeater {
      model: 4

      Rectangle {
        width: 25
        height: 20
        radius: 2

        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
        property bool hasWindows: ws !== undefined

        color: {
          // if (isActive) return Style.mauve;
          // if (mouseArea.containsMouse) return Style.maroon;
          return "transparent";
        }

        Behavior on color {
          ColorAnimation { duration: 150 }
        }

        border.color: {
          if (isActive) return "transparent";
          return Style.text;
        }

        border.width: 0
        Rectangle {
          width: 30
          height: 24
          color: "transparent"

          Rectangle {
            anchors {
              left: parent.left
              right: parent.right
              bottom: parent.bottom
            }

            height: 1.5
            color: {
              if (isActive) return Style.mauve;
              if (mouseArea.containsMouse) return Style.maroon;
              return "transparent";
            }
            radius: 0
          }
        }


        Text {
          anchors.centerIn: parent
          text: index
          color: {
            if (isActive) return Style.text;
            if (mouseArea.containsMouse) return Style.text;
            if (hasWindows) return Style.text;
            return Style.overlay1;
          }

          font {
            family: Style.fontFamily
            pixelSize: 12
            bold: isActive || hasWindows
          }

          Behavior on color {
            ColorAnimation { duration: 150 }
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Hyprland.dispatch("workspace " + (index + 1))
        }
      }
    }
  }
}
