pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "BarModel.js" as BarModel

// Owns ~/.config/quickshell/bar.json: which widgets sit in which bar section
// and in what order. The bar renders from `layout`, and every drag commits
// back through moveModule(), so the file is the single source of truth rather
// than a snapshot of it.
QtObject {
    id: config

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/bar.json"

    // Mirrors the widget order Bar.qml used to hardcode, so a first run with
    // no bar.json looks exactly like the bar did before.
    readonly property var defaultLayout: ({
        "left": ["cpu", "memory", "separator:1", "network"],
        "center": [],
        "right": ["audio-panel", "bluetooth-panel", "power-panel", "monitor-panel", "network-panel", "separator:2", "player", "separator:3", "wallpaper"]
    })

    property var layout: defaultLayout
    property bool loaded: false

    // Set while we write, so the watch that fires on our own save does not
    // bounce the file straight back and clobber a drag that lands mid-write.
    property bool saving: false

    // `layout` is a property, so QML already emits layoutChanged() whenever it
    // is reassigned — BarSection listens on that rather than a hand-rolled
    // signal, which would collide with the generated one.

    function entriesFor(region) {
        return BarModel.section(config.layout, region);
    }

    function idsFor(region) {
        return entriesFor(region).map(BarModel.entryId);
    }

    // Insert `fromName` immediately before `beforeName` in `toRegion`, or at
    // the end of it when `beforeName` is empty. Returns true when the layout
    // actually changed.
    function moveModule(fromRegion, fromName, toRegion, beforeName) {
        var next = BarModel.moveModule(config.layout, fromRegion, fromName, toRegion, beforeName);
        if (!next)
            return false;

        config.layout = next;
        save();
        return true;
    }

    function resetLayout() {
        config.layout = BarModel.normalizeLayout(config.defaultLayout);
        save();
    }

    function save() {
        config.saving = true;
        file.setText(JSON.stringify({
            "version": 1,
            "bar": {
                "layout": BarModel.normalizeLayout(config.layout)
            }
        }, null, 2) + "\n");
    }

    function applyText(text) {
        var parsed = null;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            console.warn("bar.json is not valid JSON, keeping the layout in memory:", e);
            return;
        }

        var bar = parsed && parsed.bar ? parsed.bar : {};
        config.layout = BarModel.normalizeLayout(bar.layout || config.defaultLayout);
    }

    property FileView file: FileView {
        path: config.path
        watchChanges: true
        // A half-written file read back by the watch would drop widgets off
        // the bar until the next save.
        atomicWrites: true
        printErrors: false

        onLoaded: {
            config.applyText(text());
            config.loaded = true;
        }

        onLoadFailed: (error) => {
            // No file yet on a first run: seed one from the defaults so the
            // user has something to hand-edit.
            config.layout = BarModel.normalizeLayout(config.defaultLayout);
            config.loaded = true;
            config.save();
        }

        onSaved: config.saving = false

        onSaveFailed: (error) => {
            config.saving = false;
            console.warn("could not write", config.path, "- layout change is in memory only");
        }

        onFileChanged: {
            if (config.saving)
                return;

            reload();
        }
    }
}
