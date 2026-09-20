import QtQuick
import Quickshell.Io as QsIo
// Namespaced: qs.Commons also exports a Style singleton, which would collide
// with this shell's own Style from components/.
import qs.Commons as Omarchy

// The host object Omarchy's panel kit expects as `bar`.
//
// The panels under panels/ are imported from Omarchy unmodified, so rather
// than editing ~9k lines of QML to match this shell, this object presents the
// small surface they actually read — colours, font, bar geometry, and a few
// coordination hooks — backed by this shell's own Style.
//
// It also repaints Commons/Color, the palette the whole panel kit derives its
// surfaces from, in Catppuccin. Those five roles are all the kit needs; every
// other surface in Color falls back to them when a theme file is absent, and
// there is no Omarchy theme state on this machine.
QtObject {
    id: api

    property Item window: null
    // One popup at a time: a panel asks before opening and the previous owner
    // is told to close.
    property var activePopout: null

    // Panel *content* colour. Kept as plain text so popup bodies stay readable.
    property color foreground: Style.text
    property color background: Style.crust
    property color urgent: Style.red

    // Bar *icon* colour. WidgetButton paints every bar glyph with
    // `bar.barForeground`, which Omarchy ties to the content colour; splitting
    // them is what lets the icons take an accent without tinting panel text.
    // Change this one line to recolour every imported panel's bar icon.
    property color iconColor: Style.lavender
    readonly property color barForeground: api.iconColor

    property string fontFamily: Style.fontFamily

    // This shell's bar is a fixed top strip. The panels support all four
    // edges, so these stay properties rather than constants.
    property string position: "top"
    readonly property bool vertical: position === "left" || position === "right"
    property int barSize: 30

    // Omarchy cross-fades bar text on theme changes; nothing here drives that,
    // and leaving it undefined makes WidgetButton's Behavior warn.
    property bool foregroundAnimationEnabled: false

    signal tooltipRequested(var target, string text)
    signal tooltipHidden(var target)

    function run(command) {
        runner.command = ["bash", "-lc", command];
        runner.running = true;
    }

    function showTooltip(target, text) {
        api.tooltipRequested(target, text);
    }

    function hideTooltip(target) {
        api.tooltipHidden(target);
    }

    function requestPopout(owner) {
        if (api.activePopout && api.activePopout !== owner && typeof api.activePopout.close === "function")
            api.activePopout.close();

        api.activePopout = owner;
    }

    function releasePopout(owner) {
        if (api.activePopout === owner)
            api.activePopout = null;
    }

    // Omarchy uses these to walk between adjacent panels with the keyboard and
    // to decide whether a click landed on its own bar. Neither is wired up
    // here; answering honestly is better than answering wrong.
    function switchPanelFrom(panel, direction) {
        return false;
    }

    function targetBelongsToWindow(target, window) {
        return true;
    }

    property QsIo.Process runner: QsIo.Process {
        running: false
    }

    // ------------------------------------------------------------ chrome
    //
    // Style and Color both finish loading *after* this object completes:
    // Style re-reads cornerRadius/gapsOut from `hyprctl getoption`, and Color
    // parses its theme files asynchronously. Both write imperatively, so a
    // plain assignment here — or a Binding element — is simply overwritten a
    // moment later. The overrides are therefore re-asserted from the change
    // signals, guarded so an assignment that changes nothing stops the cycle.

    // Matches the popups in components/popout: same corner radius, and flush
    // against the bar instead of Omarchy's gap, so the imported panels read as
    // part of this shell rather than as something floating near it.
    property int popupRadius: 24
    property int popupGap: 0

    // Clearance between a popup and the screen edge. Read by KeyboardPanel,
    // which clamps its card into the screen; without it a popup anchored to a
    // widget near the right of the bar sits flush against the screen edge.
    //
    // Kept at popupRadius so the corner fillet beside a right-clamped popup
    // has room for its full quarter-circle instead of being cut in half.
    property int popupEdgeMargin: api.popupRadius

    // Square off the popup corners that meet the bar, so a flush popup reads
    // as part of the bar. Set false to get plain rounded cards back.
    property bool popupFuseWithBar: true

    // Open animation. Omarchy only cross-fades its popups; the popups in
    // components/popout spring open from a small pill under the bar, so these
    // hand KeyboardPanel the same collapsed size and the same curves this
    // shell uses everywhere else.
    property int popupCollapsedWidth: 40
    property int popupCollapsedHeight: 20
    // NO SPRING. components/popout uses expressiveSlowSpatialCurve here, but
    // that curve has a control point above 1, so size sails past its target
    // and settles back — the bounce at the bottom edge of an opening popup.
    // The effects curve eases to the target without ever passing it.
    // Do not "match components/popout" by putting the spatial curve back.
    property int popupGrowDuration: Style.durationExpressiveSlowEffects
    property var popupGrowCurve: Style.expressiveSlowEffectsCurve

    property int popupFadeDuration: Style.durationExpressiveSlowEffects
    property var popupFadeCurve: Style.expressiveSlowEffectsCurve

    function applyChrome() {
        if (Omarchy.Style.cornerRadius !== api.popupRadius)
            Omarchy.Style.cornerRadius = api.popupRadius;

        if (Omarchy.Style.gapsOut !== api.popupGap)
            Omarchy.Style.gapsOut = api.popupGap;

        Omarchy.Color.foreground = Style.text;
        Omarchy.Color.background = Style.crust;
        Omarchy.Color.accent = Style.mauve;
        Omarchy.Color.urgent = Style.red;
        Omarchy.Color.muted = Style.overlay1;

        // The kit draws a 2px accent outline around every popup. Zeroing the
        // width through shellValues loses to Color's own file load, but the
        // border colour is a plain property: assigning it kills its binding
        // for good, and a transparent border paints nothing.
        Omarchy.Color.popups.border = "transparent";
        Omarchy.Color.popups.background = Style.crust;
    }

    property Connections styleWatch: Connections {
        target: Omarchy.Style

        function onCornerRadiusChanged() {
            api.applyChrome();
        }

        function onGapsOutChanged() {
            api.applyChrome();
        }
    }

    property Connections colorWatch: Connections {
        target: Omarchy.Color

        // Fires when a theme or user shell.toml finishes parsing, which is
        // exactly when the defaults would otherwise come back.
        function onShellValuesChanged() {
            api.applyChrome();
        }
    }

    Component.onCompleted: api.applyChrome()
}
