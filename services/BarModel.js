// Layout helpers for the config-driven bar.
//
// Ported from Omarchy's shell/plugins/bar/BarModel.js (MIT). Kept as plain JS
// so the reordering rules can be reasoned about — and unit-tested with node —
// without standing up a QML engine.

function isPlainObject(value) {
    return !!value && typeof value === "object" && !Array.isArray(value);
}

// An entry is either a bare id ("clock") or an object ({ id: "clock", ... }).
// Both spellings are accepted everywhere so hand-edited bar.json stays terse.
function entryId(entry) {
    if (typeof entry === "string")
        return entry;

    if (isPlainObject(entry)) {
        var id = entry["id"];
        if (id !== undefined && id !== null && String(id) !== "")
            return String(id);
    }
    return "";
}

// Everything on the entry except its id, handed to the widget as `settings`.
function entrySettings(entry) {
    if (!isPlainObject(entry))
        return {};

    var copy = {};
    for (var key in entry) {
        if (key === "id")
            continue;

        copy[key] = entry[key];
    }
    return copy;
}

function entryIndex(entries, name) {
    if (!Array.isArray(entries))
        return -1;

    for (var i = 0; i < entries.length; i++) {
        if (entryId(entries[i]) === name)
            return i;
    }
    return -1;
}

function section(layout, name) {
    if (!isPlainObject(layout))
        return [];

    return Array.isArray(layout[name]) ? layout[name] : [];
}

function normalizeLayout(layout) {
    return {
        "left": section(layout, "left").slice(),
        "center": section(layout, "center").slice(),
        "right": section(layout, "right").slice()
    };
}

// Move `fromName` out of `fromRegion` and insert it immediately before
// `beforeName` in `toRegion`. An empty `beforeName` appends. Returns a new
// layout, or null when the move is a no-op — the caller uses null to skip a
// pointless rebuild and file write.
function moveModule(layout, fromRegion, fromName, toRegion, beforeName) {
    var next = normalizeLayout(layout);
    var fromEntries = next[fromRegion];
    var toEntries = next[toRegion];
    if (!fromEntries || !toEntries)
        return null;

    var fromIndex = entryIndex(fromEntries, fromName);
    if (fromIndex < 0)
        return null;

    var toIndex = beforeName ? entryIndex(toEntries, beforeName) : toEntries.length;
    if (toIndex < 0)
        toIndex = toEntries.length;

    if (fromRegion === toRegion && fromIndex === toIndex)
        return null;

    var moved = fromEntries[fromIndex];
    fromEntries.splice(fromIndex, 1);

    // Removing the entry shifts every later index down by one, so a move to
    // the right within one section has to compensate.
    if (fromRegion === toRegion && fromIndex < toIndex)
        toIndex -= 1;

    if (toIndex < 0)
        toIndex = 0;

    if (toIndex > toEntries.length)
        toIndex = toEntries.length;

    if (fromRegion === toRegion && fromIndex === toIndex)
        return null;

    toEntries.splice(toIndex, 0, moved);
    return next;
}

// Resolve a pointer anywhere along the bar to the closest insertion edge.
// Requiring the pointer to sit inside another widget would make the gap
// between sections a dead zone, even though it reads as the most natural
// place to drop. Candidates are { slot, x, y, width, height }.
function nearestDropTarget(candidates, point, vertical) {
    var rows = Array.isArray(candidates) ? candidates : [];
    var axis = vertical ? Number(point && point.y) : Number(point && point.x);
    if (!isFinite(axis))
        return null;

    var best = null;
    var bestDistance = Infinity;
    for (var i = 0; i < rows.length; i++) {
        var row = rows[i];
        if (!row || !row.slot)
            continue;

        var start = Number(vertical ? row.y : row.x);
        var size = Number(vertical ? row.height : row.width);
        if (!isFinite(start) || !isFinite(size) || size <= 0)
            continue;

        var beforeDistance = Math.abs(axis - start);
        var afterDistance = Math.abs(axis - (start + size));
        var after = afterDistance < beforeDistance;
        var distance = after ? afterDistance : beforeDistance;
        if (distance < bestDistance) {
            best = {
                "slot": row.slot,
                "after": after
            };
            bestDistance = distance;
        }
    }
    return best;
}

// The id that `moved` must land in front of to sit after `targetName`.
// Empty means "append to the end of the section".
function idAfter(entries, targetName) {
    var index = entryIndex(entries, targetName);
    if (index < 0 || index + 1 >= entries.length)
        return "";

    return entryId(entries[index + 1]);
}

if (typeof module !== "undefined") {
    module.exports = {
        entryId: entryId,
        entrySettings: entrySettings,
        entryIndex: entryIndex,
        section: section,
        normalizeLayout: normalizeLayout,
        moveModule: moveModule,
        nearestDropTarget: nearestDropTarget,
        idAfter: idAfter
    };
}
