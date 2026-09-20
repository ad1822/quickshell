import QtQuick
import "../services"

// One widget's place on the bar. Holds the widget instance, knows which
// section and id it is, and carries the drag handling so the widgets
// themselves stay unaware they are rearrangeable.
Item {
    id: slot

    property string region: ""
    property string moduleName: ""
    property var settings: ({})
    property Component widget: null
    property BarDragController controller: null

    // Forwarded from the widget so Bar.qml can open the right popup without
    // holding an id for every widget it no longer places by hand.
    signal widgetHovered(string id, bool isHovered)
    signal widgetClicked(string id)

    readonly property var item: loader.item
    readonly property bool carried: controller !== null && controller.dragSlot === slot
    readonly property bool isDropTarget: controller !== null && controller.dropTarget !== null && controller.dropTarget.slot === slot
    readonly property bool dropAfter: isDropTarget && controller.dropTarget.after

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight
    // Carried widgets stay in the flow so the bar does not jump on pick-up;
    // they just read as lifted.
    opacity: carried ? 0.35 : 1

    Component.onCompleted: {
        if (controller)
            controller.register(slot);
    }

    Component.onDestruction: {
        if (controller) {
            controller.unbind(slot.moduleName, loader.item);
            controller.unregister(slot);
        }
    }

    Loader {
        id: loader

        anchors.centerIn: parent
        sourceComponent: slot.widget
        onLoaded: {
            // Only the widgets that declare it — spacer, custom modules —
            // take their entry's extra keys.
            if (item && item.settings !== undefined)
                item.settings = slot.settings;

            // Imported Omarchy panels read colours, font and bar geometry off
            // a `bar` host object rather than a singleton.
            if (item && item.bar !== undefined && slot.controller)
                item.bar = slot.controller.barApi;

            if (slot.controller)
                slot.controller.bind(slot.moduleName, item);
        }
    }

    Connections {
        target: loader.item
        // Most widgets expose neither signal; asking for both on all of them
        // is what lets the registry stay a flat id -> component map.
        ignoreUnknownSignals: true

        function onHovered(isHovered) {
            if (!slot.controller || !slot.controller.editMode)
                slot.widgetHovered(slot.moduleName, isHovered);
        }

        function onClicked() {
            slot.widgetClicked(slot.moduleName);
        }
    }

    // Edit-mode affordance: a dashed-looking outline so it is obvious which
    // things can be picked up.
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: dragArea.containsMouse ? Style.surface0 : "transparent"
        border.color: Style.surface2
        border.width: 1
        opacity: slot.controller && slot.controller.editMode ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    // Insertion caret. Drawn on the edge the widget would be inserted at, so
    // the drop reads the same way it does in a file manager.
    Rectangle {
        width: slot.controller && slot.controller.vertical ? parent.width : 2
        height: slot.controller && slot.controller.vertical ? 2 : parent.height
        radius: 1
        color: Style.mauve
        visible: slot.isDropTarget
        x: slot.controller && slot.controller.vertical ? 0 : (slot.dropAfter ? parent.width - width : 0)
        y: slot.controller && slot.controller.vertical ? (slot.dropAfter ? parent.height - height : 0) : 0
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent
        enabled: slot.controller !== null && slot.controller.editMode
        visible: enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: slot.carried ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real pressedX: 0
        property real pressedY: 0
        // Small moves while clicking should not start a drag.
        readonly property real dragThreshold: 6

        function report(mouse) {
            var scenePoint = dragArea.mapToItem(null, mouse.x, mouse.y);
            slot.controller.updateDrag(scenePoint);
        }

        onPressed: (mouse) => {
            pressedX = mouse.x;
            pressedY = mouse.y;
        }

        onPositionChanged: (mouse) => {
            if (!(mouse.buttons & Qt.LeftButton))
                return;

            if (!slot.carried) {
                var distance = Math.abs(mouse.x - pressedX) + Math.abs(mouse.y - pressedY);
                if (distance < dragThreshold)
                    return;

                slot.controller.beginDrag(slot);
            }
            report(mouse);
        }

        onReleased: {
            if (slot.carried)
                slot.controller.finishDrag();
        }

        // A grab stolen mid-drag (edit mode switched off, the bar collapsing)
        // must not leave a widget stuck at 35% opacity.
        onCanceled: {
            if (slot.carried)
                slot.controller.clearDrag();
        }
    }
}
