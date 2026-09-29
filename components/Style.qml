import QtQuick
pragma Singleton

QtObject {
    // Text color on active workspace

    // Font Properties
    readonly property string fontFamily: "Iosevka"
    readonly property int fontSize: 13
    readonly property int fontWeight: 500
    // Theme Colors
    readonly property string rosewater: "#f5e0dc"
    readonly property string flamingo: "#f2cdcd"
    readonly property string pink: "#f5c2e7"
    readonly property string mauve: "#cba6f7"
    readonly property string red: "#f38ba8"
    readonly property string maroon: "#eba0ac"
    readonly property string peach: "#fab387"
    readonly property string yellow: "#f9e2af"
    readonly property string green: "#a6e3a1"
    readonly property string teal: "#94e2d5"
    readonly property string sky: "#89dceb"
    readonly property string sapphire: "#74c7ec"
    readonly property string blue: "#89b4fa"
    readonly property string lavender: "#b4befe"
    readonly property string text: "#cdd6f4"
    readonly property string subtext1: "#bac2de"
    readonly property string subtext0: "#a6adc8"
    readonly property string overlay2: "#9399b2"
    readonly property string overlay1: "#7f849c"
    readonly property string overlay0: "#6c7086"
    readonly property string surface2: "#585b70"
    readonly property string surface1: "#45475a"
    readonly property string surface0: "#313244"
    readonly property string base: "#1e1e2e"
    readonly property string mantle: "#181825"
    readonly property string crust: "#11111b"

    // Caelestia Expressive Animation Curves (Bezier Control Points)
    readonly property var expressiveDefaultSpatialCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var expressiveFastSpatialCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var expressiveSlowSpatialCurve: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var expressiveDefaultEffectsCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var expressiveFastEffectsCurve: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var expressiveSlowEffectsCurve: [0.34, 0.88, 0.34, 1, 1, 1]

    // Caelestia Easing Durations (in ms)
    readonly property int durationNormal: 400
    readonly property int durationExpressiveDefaultSpatial: 500
    readonly property int durationExpressiveFastSpatial: 350
    readonly property int durationExpressiveSlowSpatial: 650
    readonly property int durationExpressiveDefaultEffects: 200
    readonly property int durationExpressiveFastEffects: 150
    readonly property int durationExpressiveSlowEffects: 300
}
