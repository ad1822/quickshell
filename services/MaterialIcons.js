// Nerd Font -> Material Symbols translation for the imported Omarchy panels.
//
// Omarchy's bar glyphs are Nerd Font codepoints in the private use area,
// rendered with the bar's mono font. This shell's own bar uses Material
// Symbols Rounded ligature names ("developer_board", "volume_off"), so the
// imported panels stood out against everything beside them.
//
// Ui/OpticalGlyph consults this map: a glyph listed here is swapped for its
// Material name and drawn in the Material family, and anything not listed
// falls through untouched, still rendered in the bar's own font. That keeps
// panels/ unedited - only the glyph renderer knows about this.
//
// Every Material name below was checked against the `post` table of
// MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf, so none render blank.
//
// Sources are code points, not string escapes, on purpose: most of these live
// above U+FFFF, and a "\uF0922" escape consumes only four hex digits - it
// would silently mean U+F092 followed by "2" and never match a thing.

var family = "Material Symbols Rounded";

var codePoints = [
    // --------------------------------------------------- network
    [0xF092F, "signal_wifi_0_bar"],          // wifi-strength-outline
    [0xF091F, "network_wifi_1_bar"],
    [0xF0922, "network_wifi_2_bar"],
    [0xF0925, "network_wifi_3_bar"],
    [0xF0928, "wifi"],                       // full strength
    [0xF0929, "signal_wifi_bad"],            // captive portal / limited
    [0xF092E, "wifi_off"],
    [0xF0200, "lan"],                        // ethernet
    [0xF0202, "link_off"],                   // ethernet, limited

    // ------------------------------------------------- bluetooth
    [0xF00AF, "bluetooth"],
    [0xF00B1, "bluetooth_connected"],
    [0xF00B2, "bluetooth_disabled"],

    // ----------------------------------------------------- audio
    [0xF02CB, "headphones"],
    [0xF04C3, "speaker"],
    [0xF036C, "mic"],
    [0xF036D, "mic_off"],
    [0xF057E, "volume_up"],
    [0xF075F, "volume_off"],
    [0x0F026, "volume_off"],                 // the fa-* glyphs the audio panel uses
    [0x0F027, "volume_down"],
    [0x0F028, "volume_up"],

    // --------------------------------------------------- display
    [0xF0379, "monitor"],
    [0xF037A, "desktop_windows"],            // more than one screen

    // --------------------------------------------- battery, idle
    [0xF007A, "battery_1_bar"],
    [0xF007B, "battery_1_bar"],
    [0xF007C, "battery_2_bar"],
    [0xF007D, "battery_3_bar"],
    [0xF007E, "battery_3_bar"],
    [0xF007F, "battery_4_bar"],
    [0xF0080, "battery_5_bar"],
    [0xF0081, "battery_5_bar"],
    [0xF0082, "battery_6_bar"],
    [0xF0079, "battery_full"],
    [0xF0084, "battery_alert"],

    // ----------------------------------------- battery, charging
    [0xF089C, "battery_charging_20"],
    [0xF0086, "battery_charging_20"],
    [0xF0087, "battery_charging_30"],
    [0xF0088, "battery_charging_30"],
    [0xF089D, "battery_charging_50"],
    [0xF0089, "battery_charging_60"],
    [0xF089E, "battery_charging_60"],
    [0xF008A, "battery_charging_80"],
    [0xF008B, "battery_charging_90"],
    [0xF0085, "battery_charging_full"],

    // ---------------------------------------------------- chrome
    [0xF0140, "expand_more"],
    [0xF0141, "chevron_left"],
    [0xF0142, "chevron_right"],
    [0xF00ED, "calendar_month"],
];

var map = (function () {
    var built = {};
    for (var i = 0; i < codePoints.length; i++)
        built[String.fromCodePoint(codePoints[i][0])] = codePoints[i][1];

    return built;
})();

// The Material name for a glyph, or "" when it should be left alone.
function name(text) {
    var value = String(text || "");
    if (value.length === 0)
        return "";

    return map[value] || "";
}

if (typeof module !== "undefined") {
    module.exports = { family: family, map: map, name: name };
}
