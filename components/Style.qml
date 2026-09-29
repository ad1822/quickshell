import QtQuick
pragma Singleton

QtObject {
    // Text color on active workspace

    // Font Properties
    readonly property string fontFamily: "Iosevka"
    readonly property int fontSize: 13
    readonly property int fontWeight: 500
    // Theme Colors -- Graphite.
    //
    // Names are kept from the previous Catppuccin palette so every call site
    // still resolves; only the values changed. The scale runs crust (darkest
    // surface) through text (primary), and is deliberately neutral: the
    // saturated entries below are for errors, warnings, success and links,
    // not decoration. lavender/rosewater are neutral on purpose -- lavender
    // is what OmarchyBarApi paints bar glyphs with.
    readonly property string rosewater: "#F5F5F7"
    readonly property string flamingo: "#FF9F0A"
    readonly property string pink: "#BF5AF2"
    readonly property string mauve: "#BF5AF2"
    readonly property string red: "#FF453A"
    readonly property string maroon: "#FF453A"
    readonly property string peach: "#FF9F0A"
    readonly property string yellow: "#FFD60A"
    readonly property string green: "#30D158"
    readonly property string teal: "#64D2FF"
    readonly property string sky: "#64D2FF"
    readonly property string sapphire: "#64D2FF"
    readonly property string blue: "#0A84FF"
    readonly property string lavender: "#F5F5F7"
    readonly property string text: "#F5F5F7"
    readonly property string subtext1: "#A1A1A6"
    readonly property string subtext0: "#8E8E93"
    readonly property string overlay2: "#6E6E73"
    readonly property string overlay1: "#48484A"
    readonly property string overlay0: "#2C2C2E"
    readonly property string surface2: "#242426"
    readonly property string surface1: "#1C1C1E"
    readonly property string surface0: "#151517"
    readonly property string base: "#0D0D0F"
    readonly property string mantle: "#0A0A0B"
    readonly property string crust: "#060607"

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
