import QtQuick
pragma Singleton

QtObject {
    // Text color on active workspace

    // Font Properties
    // UI font. The spec asks for SF Pro, falling back to Inter; neither is
    // installed, and Qt silently substitutes a generic sans for a family it
    // cannot find, which is what made the bar look wrong. Adwaita Sans is
    // GNOME's cut of Inter and is already on the system, so it gives the
    // intended look with nothing to install. Swap this to "SF Pro Text" or
    // "Inter" once either is present.
    //
    // The terminal, nvim, tmux and the CLI are untouched by this and stay on
    // Iosevka Nerd Font Mono.
    readonly property string fontFamily: "Adwaita Sans"
    // Drives the clock and most bar text (Clock, Network, Volume, Brightness,
    // WallpaperButton all bind to it), so it is the one lever for bar type.
    readonly property int fontSize: 14
    readonly property int fontWeight: 500
    // Theme Colors: macOS dark. The Catppuccin names are kept so nothing that
    // reads them has to change. Neutrals are Apple's system greys over true
    // black; mauve is the accent and maps to system green, red stays for mute
    // and errors, peach/yellow for warnings. lavender and the rose tones are
    // neutral whites so the UI stays mostly monochrome.
    readonly property string rosewater: "#f2f2f7"
    readonly property string flamingo: "#e5e5ea"
    readonly property string pink: "#ff6482"
    readonly property string mauve: "#30d158"
    readonly property string red: "#ff453a"
    readonly property string maroon: "#ff6961"
    readonly property string peach: "#ff9f0a"
    readonly property string yellow: "#ffd60a"
    readonly property string green: "#30d158"
    readonly property string teal: "#40c8e0"
    readonly property string sky: "#64d2ff"
    readonly property string sapphire: "#409cff"
    readonly property string blue: "#409cff"
    readonly property string lavender: "#e5e5ea"
    readonly property string text: "#f5f5f7"
    readonly property string subtext1: "#d1d1d6"
    readonly property string subtext0: "#aeaeb2"
    readonly property string overlay2: "#98989d"
    readonly property string overlay1: "#8e8e93"
    readonly property string overlay0: "#636366"
    readonly property string surface2: "#48484a"
    readonly property string surface1: "#3a3a3c"
    readonly property string surface0: "#2c2c2e"
    readonly property string base: "#1c1c1e"
    readonly property string mantle: "#0e0e10"
    readonly property string crust: "#000000"

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
