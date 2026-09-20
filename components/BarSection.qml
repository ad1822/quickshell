import QtQuick
import "../services"
import "../services/BarModel.js" as BarModel

// One region of the bar, rendered from BarConfig rather than from hand-placed
// anchors. Rebuilds whenever the layout changes, which is what makes a drag
// (or a hand edit of bar.json) show up without restarting the shell.
Row {
    id: section

    property string region: ""
    property BarDragController controller: null

    signal widgetHovered(string id, bool isHovered)
    signal widgetClicked(string id)

    // entriesFor() reads BarConfig.layout, so this binding re-evaluates — and
    // the Repeater rebuilds — whenever a drag or a hand edit of bar.json
    // replaces the layout.
    readonly property var entries: BarConfig.entriesFor(region)

    spacing: 6

    Repeater {
        model: section.entries

        delegate: BarSlot {
            required property var modelData

            region: section.region
            moduleName: BarModel.entryId(modelData)
            settings: BarModel.entrySettings(modelData)
            widget: BarWidgetRegistry.componentFor(moduleName)
            controller: section.controller
            anchors.verticalCenter: parent.verticalCenter

            onWidgetHovered: (id, isHovered) => section.widgetHovered(id, isHovered)
            onWidgetClicked: (id) => section.widgetClicked(id)
        }
    }
}
