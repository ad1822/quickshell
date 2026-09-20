pragma Singleton

import QtQuick
import "../components"
import "../panels"

// id -> widget component. Every id that may appear in bar.json's layout has to
// be listed here; an unknown id renders as nothing rather than tearing the bar
// down, so a typo in a hand-edited file is survivable.
//
// Widgets are plain Items with an implicit size. Those that drive a popup
// expose a `hovered(bool)` signal, which BarSlot forwards to the bar by id —
// that is what keeps the components themselves ignorant of where they sit.
QtObject {
    id: registry

    readonly property var components: ({
        "cpu": cpuComponent,
        "memory": memoryComponent,
        "network": networkComponent,
        "player": playerComponent,
        "wallpaper": wallpaperComponent,
        "clock": clockComponent,
        "workspaces": workspacesComponent,
        "network-panel": networkPanelComponent,
        "monitor-panel": monitorPanelComponent,
        "audio-panel": audioPanelComponent,
        "power-panel": powerPanelComponent,
        "bluetooth-panel": bluetoothPanelComponent,
        "clock-panel": clockPanelComponent,
        "weather-panel": weatherPanelComponent,
        "separator": separatorComponent,
        "spacer": spacerComponent
    })

    // Human labels, for a future "add widget" menu and for drag tooltips.
    readonly property var labels: ({
        "cpu": "CPU",
        "memory": "Memory",
        "network": "Network",
        "player": "Media",
        "wallpaper": "Wallpaper",
        "clock": "Clock",
        "workspaces": "Workspaces",
        "network-panel": "Network (Omarchy)",
        "monitor-panel": "Display (Omarchy)",
        "audio-panel": "Audio (Omarchy)",
        "power-panel": "Power (Omarchy)",
        "bluetooth-panel": "Bluetooth (Omarchy)",
        "clock-panel": "Clock (Omarchy)",
        "weather-panel": "Weather (Omarchy)",
        "separator": "Separator",
        "spacer": "Spacer"
    })

    // Ids are unique per bar so a move can address one entry unambiguously,
    // but several entries can share a widget: "separator:1" and "separator:2"
    // both resolve to the separator component. Everything before the colon is
    // the type, everything after is just there to keep the id distinct.
    function typeOf(id) {
        var value = String(id || "");
        var colon = value.indexOf(":");
        return colon === -1 ? value : value.substring(0, colon);
    }

    function has(id) {
        return !!registry.components[typeOf(id)];
    }

    function componentFor(id) {
        return registry.components[typeOf(id)] || null;
    }

    function labelFor(id) {
        return registry.labels[typeOf(id)] || typeOf(id);
    }

    function ids() {
        return Object.keys(registry.components);
    }

    readonly property Component cpuComponent: Component {
        Process {
        }
    }

    readonly property Component memoryComponent: Component {
        Memory {
        }
    }

    readonly property Component networkComponent: Component {
        Network {
        }
    }

    readonly property Component playerComponent: Component {
        Player {
        }
    }

    readonly property Component wallpaperComponent: Component {
        WallpaperButton {
        }
    }

    readonly property Component clockComponent: Component {
        Clock {
        }
    }

    readonly property Component workspacesComponent: Component {
        Workspaces {
        }
    }

    // Imported from Omarchy: each is a bar icon button plus its own popup
    // panel. They anchor their popup to themselves, so they work wherever the
    // layout puts them.
    readonly property Component networkPanelComponent: Component {
        NetworkPanel {
        }
    }

    readonly property Component monitorPanelComponent: Component {
        MonitorPanel {
        }
    }

    readonly property Component audioPanelComponent: Component {
        AudioPanel {
        }
    }

    readonly property Component powerPanelComponent: Component {
        PowerPanel {
        }
    }

    readonly property Component bluetoothPanelComponent: Component {
        BluetoothPanel {
        }
    }

    readonly property Component clockPanelComponent: Component {
        ClockPanel {
        }
    }

    readonly property Component weatherPanelComponent: Component {
        WeatherPanel {
        }
    }

    // The hairlines Bar.qml used to place by hand between widget groups.
    // Now that order is user-controlled they have to be placeable too.
    readonly property Component separatorComponent: Component {
        Item {
            implicitWidth: 9
            implicitHeight: 22

            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 12
                color: Style.surface1
            }
        }
    }

    readonly property Component spacerComponent: Component {
        Item {
            property var settings: ({})

            implicitWidth: settings && settings.size !== undefined ? Number(settings.size) : 12
            implicitHeight: 22
        }
    }
}
