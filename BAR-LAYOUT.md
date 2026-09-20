# Bar layout

Bar widgets are no longer placed by hand in `modules/Bar.qml`. Which widgets
appear, in which section, and in what order all come from `bar.json`, and they
can be rearranged by dragging them on the bar itself.

The design is ported from Omarchy's `shell/plugins/bar` (MIT), scaled down to
this shell: one monitor, two sections, no plugin system.

## Files

| File | Role |
|---|---|
| `services/BarModel.js` | Pure layout maths — entry parsing, `moveModule`, `nearestDropTarget`. Runnable under `node` for testing. |
| `services/BarConfig.qml` | Singleton owning `bar.json`: loads it, watches it, writes it back after a drag. |
| `services/BarWidgetRegistry.qml` | `id -> Component` map. An id has to be listed here to be placeable. |
| `components/BarDragController.qml` | One per bar. Tracks the in-flight drag and commits the drop. |
| `components/BarSection.qml` | A `Row` + `Repeater` over one section of the layout. |
| `components/BarSlot.qml` | One widget's place: loads it, forwards its signals, handles the drag. |

## bar.json

Lives next to `shell.qml` at `~/.config/quickshell/bar.json`. It is written on
first run from `BarConfig.defaultLayout` and rewritten after every drag.

```json
{
  "version": 1,
  "bar": {
    "layout": {
      "left": ["cpu", "memory", "separator:1", "network"],
      "center": [],
      "right": ["player", "separator:2", "wallpaper", "volume", "wifi", "battery"]
    }
  }
}
```

`left` is the hamburger-revealed module group; `right` is the always-visible
cluster. `center` is parsed and stored but nothing renders it yet.

An entry is either a bare id or an object carrying settings:

```json
{ "id": "spacer", "size": 24 }
```

Everything on the object except `id` reaches the widget as a `settings`
property, for the widgets that declare one.

Ids must be unique within the bar so a drag can address one entry
unambiguously. Several entries can still share a widget by suffixing the id
with a colon: `separator:1` and `separator:2` both load the separator.

Editing the file by hand works — `BarConfig` watches it and the sections
rebuild without restarting the shell.

## Rearranging

`SUPER + CTRL + B` toggles edit mode (`quickshell ipc -p ~/.config/quickshell
call bar editMode`). Edit mode expands the bar, outlines every widget, and
turns each into a drag handle; a caret shows which edge the carried widget
would land on, including across into the other section. Releasing writes the
new order to `bar.json`.

Edit mode exists because the widgets own their own click handling. A drag
handler layered over them permanently would swallow every click, so the two
modes are kept apart rather than trying to disambiguate a press.

Other IPC calls on the `bar` target:

```
quickshell ipc -p ~/.config/quickshell call bar editModeOff
quickshell ipc -p ~/.config/quickshell call bar resetLayout
```

## Adding a widget

1. Write the component in `components/`, give it an implicit size, and add it
   to `components/qmldir`.
2. Add it to `components` and `labels` in `services/BarWidgetRegistry.qml`.
3. Put its id in a section in `bar.json`.

If it should drive a popup, emit `hovered(bool)` and add a case for its id in
`Bar.qml`'s `routeWidgetHover()`.

## Reaching a widget from elsewhere

Widgets live inside a `Repeater`, so they have no `id` to reference. They are
resolved by layout id instead:

```qml
readonly property var volumeWidget: barDrag.itemFor("volume")
```

These are null whenever the widget is not on the bar, so every use of them has
to be null-guarded — `shell.qml` binds its OSD `Connections` straight to them,
which simply goes idle when a widget is absent.

## Imported Omarchy panels

The popup panels from Omarchy's shell — the ones that drop out of its bar —
are vendored here unmodified under `panels/`, together with the UI kit they
are built on:

| Path | Contents |
|---|---|
| `Commons/` | `qs.Commons` — `Color`, `Style`, `Util`, `Border` |
| `Ui/` | `qs.Ui` — `Panel`, `KeyboardPanel`, `PopupCard`, `PanelSlider`, `Dropdown`, `Toggle`, `BarIconButton`, … |
| `panels/<name>/` | One panel each: `network`, `monitor`, `audio`, `power`, `bluetooth`, `clock`, `weather` |

Nothing in those three directories is edited. Omarchy's `import qs.Ui` /
`import qs.Commons` resolve here because Quickshell exposes the config root as
the `qs` module root, exactly as they do in Omarchy's own tree — so these
directories can be replaced wholesale from a newer Omarchy checkout.

### How they attach

Each panel's `Panel.qml` is both the bar button and its popup, with an
implicit size taken from the button, so it drops into a `BarSlot` like any
other widget. They are registered in `BarWidgetRegistry` under
`network-panel`, `monitor-panel`, `audio-panel`, `power-panel`,
`bluetooth-panel`, `clock-panel` and `weather-panel`, which means they are
placed and dragged from `bar.json` the same as everything else. The popup
anchors to the button through `anchorItem.QsWindow.window`, so it follows the
widget wherever a drag puts it.

`components/OmarchyBarApi.qml` is the one piece of glue. The panels read
colours, font, and bar geometry off a host object they call `bar`; this shell
has no such object, so the shim presents that surface and backs it with
`Style`. It also repaints the five roles in `Commons/Color` — foreground,
background, accent, urgent, muted — in Catppuccin at startup, which is what
keeps the imported panels from rendering in Omarchy's default grey.

### What they need

The panels shell out to Omarchy's helper scripts (`omarchy-network-status`,
`omarchy-monitor-state`, `omarchy-brightness-display`, `omarchy-audio-*`,
`omarchy-powerprofiles-*`, and others). Those come from the checkout at
`~/omarchy`, which `hypr/modules/env.lua` puts on `PATH`. A panel whose helper
cannot be found still opens — it just shows no data.

### IPC

Each panel registers its own target, so they can be opened from a keybind
without going through the bar:

```
quickshell ipc -p ~/.config/quickshell call omarchy.network toggle
quickshell ipc -p ~/.config/quickshell call omarchy.audio toggle
quickshell ipc -p ~/.config/quickshell call omarchy.monitor brightness 50
quickshell ipc -p ~/.config/quickshell call omarchy.network speedTest
```

### What the panels replaced

The Omarchy panels took over audio, backlight, Wi-Fi and battery, so this
shell's own widgets and popups for those are gone: `components/WifiIcon.qml`,
`components/popout/WifiPopup.qml`, `components/popout/QsPopup.qml` (volume and
brightness) and the orphaned `components/popout/BattPopup.qml` were deleted,
along with their loaders and hover timers in `Bar.qml`.

`components/Volume.qml` and `components/Brightness.qml` survive as **headless
sources**. They are instantiated in `Bar.qml` with `visible: false` and carry
no bar icon, because `shell.qml`'s volume and brightness OSDs — and the
collapsed pill's inline OSD — bind to their values. Their polling timers run
regardless of visibility. `barWindow.volumeWidget` / `brightnessWidget` point
at these instances rather than at a layout slot.

`components/Battery.qml` also survives: the collapsed pill's hover state still
shows a battery percentage through it.

The popups kept are CPU, memory, network speed and media.

### A benign warning

On startup each panel logs:

```
QML IpcHandler at @Ui/Panel.qml: Handler was registered but will not be used
because another handler is registered for target omarchy.<name>
```

Every panel sets `manageIpc: false` so it can own its target and add its own
methods, but the base handler in `Ui/Panel.qml` registers before that property
is applied. The panel's own handler is the one that stays live — `open`,
`close` and `toggle` all work on every target.

## Panel styling

The imported panels are not edited; their look is driven entirely from
`components/OmarchyBarApi.qml`, which overrides the kit's own theming
singletons. Three knobs cover everything:

| Property | Effect |
|---|---|
| `iconColor` | Colour of every imported panel's bar glyph. Currently `Style.lavender`. |
| `popupRadius` | Popup corner radius. `24`, matching `components/popout`. |
| `popupGap` | Distance from the bar. `0`, so popups sit flush against it. |
| `popupEdgeMargin` | Clearance between a popup and the screen edge. Tracks `popupRadius`. |
| `popupFuseWithBar` | Square off the popup corners that meet the bar. `true`. |
| `popupCollapsedWidth` / `popupCollapsedHeight` | Size the popup springs open from. `40` x `20`. |
| `popupGrowDuration` / `popupGrowCurve` | Open/close grow. Slow *effects* curve — no spring. |
| `popupFadeDuration` / `popupFadeCurve` | Opacity fade. `Style.durationExpressiveSlowEffects` + curve. |

`foreground` stays `Style.text` and is deliberately separate from `iconColor`:
Omarchy ties bar glyphs and panel body text to the same colour, and the split
is what lets the icons take an accent without tinting the text inside every
popup.

The 2px accent outline the kit draws around each popup is removed by setting
`Color.popups.border` transparent.

`popupEdgeMargin` exists because `KeyboardPanel` — the base every panel's
popup is built on — took both its bar gap and its screen-edge clamp from
`Style.gapsOut`. Driving that to 0 for the flush-to-bar look also zeroed the
clamp, so a popup belonging to a widget near the right of the bar sat hard
against the screen edge. `KeyboardPanel.margin` now reads `bar.popupEdgeMargin`
and falls back to `Style.gapsOut`, which keeps `gap` free to stay at 0.

`popupFuseWithBar` squares the two card corners on the bar's edge, so a flush
popup reads as an extension of the bar instead of a rounded card that happens
to touch it. The popups in `components/popout` get the same effect by clipping
a rounded rect that overhangs upward by its own radius; the kit's card is a
`Rectangle`, so it can use Qt's per-corner radii directly:

```qml
topLeftRadius: fusedToBar && (barPos === "top" || barPos === "left") ? 0 : radius
```

It applies only while `gap` is 0 — with a gap the popup is detached and the
rounded corners are correct — and it follows `bar.position`, so a bottom, left
or right bar squares the corners on its own edge.

Squared corners alone still meet the bar as a butt joint, so `KeyboardPanel`
also draws two **inverted corner fillets**: concave quarter-circle wedges just
outside the card on the bar's edge, filled with the card colour, so the bar
appears to flow into the popup. This is the same shape `components/popout`
draws beside its own popups (`netLeftFillet` / `netRightFillet` in
`NetPopup.qml`). Each is a square of one corner radius with an arc swept out
of it:

```qml
PathLine { x: size; y: 0 }
PathLine { x: size; y: size }
PathArc  { x: 0; y: 0; radiusX: size; radiusY: size
           direction: PathArc.Counterclockwise }
```

The fillet is sized `min(radius, card height)`, not a fixed radius. The card
spends the first frames of its open animation shorter than the radius, and a
fixed-size fillet hangs below it with its arc meeting nothing — the popup reads
as a floating pill flanked by two stray wedges, and only appears to attach to
the bar once the card has grown past them. Shrinking the fillet with the card
keeps the joint whole for every frame.

One `CornerFillet` component covers all four cases — `mirrored` flips it for
the trailing side, and a `Scale` transform flips it vertically for a bottom
bar. They render only while the card is fused and faded in, and are skipped
entirely for a left or right bar, where the joint is a different shape.

`popupEdgeMargin` tracks `popupRadius` for this reason: at a smaller value the
fillet beside a right-clamped popup runs past the screen edge and is cut in
half. At `popupRadius` it ends exactly on the edge.

Together with the icon swap in `OpticalGlyph.qml`, that makes three
`LOCAL CHANGE` edits in the vendored `Ui/` tree: `OpticalGlyph.qml` and
`KeyboardPanel.qml` (twice, `margin` and the corner radii).

### Why these are re-asserted rather than assigned once

`Style` re-reads `cornerRadius` from `hyprctl getoption decoration:rounding`
and `gapsOut` from `general:gaps_out` shortly after startup, and `Color` parses
its theme files asynchronously — both write imperatively, so a plain assignment
in `Component.onCompleted`, and a `Binding` element too, are overwritten a
moment later. `applyChrome()` is therefore re-run from `Style`'s and `Color`'s
own change signals, guarded so an assignment that changes nothing ends the
cycle. Zeroing the border through `shellValues` fails for the same reason,
which is why the border is killed by colour instead of by width.

### Icons

Omarchy draws its bar glyphs as Nerd Font code points in the private use area,
rendered in the bar's mono font. This shell uses Material Symbols Rounded
ligature names, so the imported panels looked foreign next to everything else.

`services/MaterialIcons.js` maps the 48 Nerd Font code points the panels use
onto Material names, and `Ui/OpticalGlyph.qml` — the only thing that draws a
bar glyph, used by `BarIconButton` and the clock widget — consults it: a
mapped glyph is swapped for its ligature and drawn in Material Symbols;
anything unmapped renders exactly as before, in the bar's own font. `panels/`
stays untouched.

Every Material name in the map was checked against the `post` table of
`MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf`, so none of them render as a
blank box.

The map is keyed by **code point**, not by string escape:

```js
[0xF0922, "network_wifi_2_bar"],
```

`"2"` would be wrong — `\u` consumes exactly four hex digits, so it means
U+F092 followed by the character `2` and matches nothing. Most of these glyphs
live above U+FFFF, so `String.fromCodePoint` is the only safe spelling.

This is the one edit inside the vendored `Ui/` tree; it is marked `LOCAL
CHANGE` in `OpticalGlyph.qml` and has to be re-applied if that directory is
replaced from a newer Omarchy checkout.

### Open animation

Upstream Omarchy only cross-fades a panel's opacity. The popups in
`components/popout` instead start as a small pill under the bar and spring out
to full size with their content clipped, so they read as unfolding out of the
bar. `KeyboardPanel`'s card now does the same:

```qml
property real growth: shown ? 1 : 0          // the only animated value
width:  collapsedWidth  + (root.contentWidth  - collapsedWidth)  * growth
height: collapsedHeight + (root.contentHeight - collapsedHeight) * growth
clip: true
```

The animation is on `growth`, never on `width`/`height` directly. A panel's
`contentHeight` is derived from its content — `fittedContentHeight` over a
column's `implicitHeight` — and it keeps moving after the popup is up: a
network scan fills in, a section expands, a list settles shorter than it first
laid out. With a `Behavior` on the sizes themselves, every one of those
re-animated the card and the bottom edge sailed past its target and came back.
Interpolating from a single driver means content changes reach the card
immediately, at whatever progress the open animation has reached.

Gating the size `Behavior`s behind a flag set in `onOpenChanged` does *not*
work: the size binding and the handler both react to `open`, the binding runs
first, and the card snaps to full size with the animation disabled.

The card is laid out at full size, so `clip` is what hides the content until
the card has grown to meet it. `x` compensates for the animated width so the
card stays centred on its bar widget while growing, and `y` stays pinned to the
bar edge — for a bottom bar the compensation moves to `y` instead. The corner
fillets bind to the card's live edges, so they track it through the whole
animation.

Size uses an **effects** curve, never a spatial one. `components/popout` uses
`expressiveSlowSpatialCurve` on its own popups, but that curve has a control
point above 1, so size sails past its target and settles back — a visible
bounce at the bottom edge of an opening popup. Do not "match
components/popout" by putting the spatial curve back; that has been tried and
reverted once already.

Both animations are disabled during a popout switch, where one panel hands over
to another and an animation would read as a glitch.

**The wobble that easing curves could not fix.** Before `contentHolder` was
pinned, the bottom edge kept sailing past where it belonged regardless of the
curve, because the target itself was moving: the holder filled the animating
card, the content column re-wrapped at every intermediate size, and
`contentHeight` — the value the card was animating toward — followed it. No
curve can settle against a target that reacts to the animation. Measured with
the holder pinned, the target now moves exactly once during an open, when the
Wi-Fi scan results actually arrive.

Measured on open (network panel):

```
t=25ms   g=0.243 h=74  target=244
t=125ms  g=0.867 h=331 target=379   <- scan results arrive; absorbed, no re-animation
t=275ms  g=0.999 h=379 target=379
t=300ms  g=1.000 h=379 target=379   <- settled
                                       peakGrowth=1.000  framesPastTarget=0
```
