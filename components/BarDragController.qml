import QtQuick
import "../services"
import "../services/BarModel.js" as BarModel

// One per bar. Owns the in-flight drag: which slot is being carried, where it
// would land, and committing that to BarConfig on release.
//
// Every slot registers here rather than with its own section, because a drag
// has to be able to cross from one section into another — the drop candidates
// are all slots on the bar, not the ones next to the source.
Item {
    id: controller

    // Widgets keep their normal click behaviour until edit mode is on. Their
    // own MouseAreas fill them and already consume presses, so a drag handler
    // layered on top would eat every click if it were always live.
    property bool editMode: false
    property bool vertical: false

    // The host object the imported Omarchy panels expect as `bar`. Threaded
    // through the controller because it already reaches every slot.
    property var barApi: null

    property var slots: []
    // moduleName -> live widget instance, so the rest of the bar can reach a
    // widget it no longer declares by id (shell.qml watches the volume and
    // brightness widgets to drive the OSDs).
    property var items: ({})
    property var dragSlot: null
    // { slot, after } — the widget the carried one drops next to, and which
    // side of it. Null when the pointer is nowhere useful.
    property var dropTarget: null

    readonly property bool dragging: dragSlot !== null

    signal layoutCommitted()

    function register(slot) {
        var next = controller.slots.slice();
        next.push(slot);
        controller.slots = next;
    }

    function unregister(slot) {
        controller.slots = controller.slots.filter(function(other) {
            return other !== slot;
        });
        if (controller.dragSlot === slot)
            clearDrag();
    }

    function bind(moduleName, item) {
        if (!moduleName)
            return;

        var next = {};
        for (var key in controller.items)
            next[key] = controller.items[key];

        if (item)
            next[moduleName] = item;
        else
            delete next[moduleName];

        controller.items = next;
    }

    // Only clears the binding when it still points at this instance. A
    // Repeater rebuild can construct the replacement slot before tearing the
    // old one down, and an unconditional clear there would drop the widget
    // that the OSDs are watching.
    function unbind(moduleName, item) {
        if (!moduleName || controller.items[moduleName] !== item)
            return;

        bind(moduleName, null);
    }

    function itemFor(moduleName) {
        return controller.items[moduleName] || null;
    }

    // The BarSlot carrying a widget, rather than the widget itself. Popups
    // anchor to a slot's position because a slot's x is a real property on a
    // chain of real properties up to the window, so a binding on it re-runs
    // when the layout moves. The widget inside is centred in its slot.
    function slotFor(moduleName) {
        for (var i = 0; i < controller.slots.length; i++) {
            var slot = controller.slots[i];
            if (slot && slot.moduleName === moduleName)
                return slot;
        }
        return null;
    }

    function beginDrag(slot) {
        controller.dragSlot = slot;
        controller.dropTarget = null;
    }

    function updateDrag(scenePoint) {
        if (!controller.dragSlot)
            return;

        var candidates = [];
        for (var i = 0; i < controller.slots.length; i++) {
            var slot = controller.slots[i];
            if (!slot || slot === controller.dragSlot)
                continue;

            if (!slot.visible || slot.width <= 0 || slot.height <= 0)
                continue;

            var point = slot.mapToItem(null, 0, 0);
            candidates.push({
                "slot": slot,
                "x": point.x,
                "y": point.y,
                "width": slot.width,
                "height": slot.height
            });
        }

        controller.dropTarget = BarModel.nearestDropTarget(candidates, scenePoint, controller.vertical);
    }

    function finishDrag() {
        var source = controller.dragSlot;
        var target = controller.dropTarget;
        clearDrag();

        if (!source || !target || !target.slot)
            return;

        // Dropping "after" a widget means landing in front of whatever
        // currently follows it; nothing following means append.
        var beforeName = target.after ? BarModel.idAfter(BarConfig.entriesFor(target.slot.region), target.slot.moduleName) : target.slot.moduleName;

        if (BarConfig.moveModule(source.region, source.moduleName, target.slot.region, beforeName))
            controller.layoutCommitted();
    }

    function clearDrag() {
        controller.dragSlot = null;
        controller.dropTarget = null;
    }

    onEditModeChanged: {
        if (!editMode)
            clearDrag();
    }
}
