import QtQuick
import qs.Commons
// LOCAL CHANGE (not upstream Omarchy): see services/MaterialIcons.js.
import "../services/MaterialIcons.js" as MaterialIcons

Item {
  id: root

  property string text: ""
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property color color: Color.foreground
  property bool debugBounds: false

  // LOCAL CHANGE: this shell's bar is drawn in Material Symbols, so a Nerd
  // Font glyph with a known Material equivalent is swapped for the ligature
  // name and the Material family. Anything unmapped renders exactly as before.
  readonly property string materialName: MaterialIcons.name(root.text)
  readonly property bool usesMaterial: materialName !== ""
  readonly property string renderedText: usesMaterial ? materialName : root.text
  readonly property string renderedFamily: usesMaterial ? MaterialIcons.family : root.fontFamily

  readonly property int renderedFontSize: Math.max(1, Math.round(fontSize))
  readonly property real tightWidth: Math.max(1, glyphMetrics.tightBoundingRect.width)
  readonly property real horizontalCorrection: glyph.implicitWidth / 2 - (glyphMetrics.tightBoundingRect.x + tightWidth / 2)
  readonly property real paintedCenterX: glyph.x + glyphMetrics.tightBoundingRect.x + tightWidth / 2
  readonly property real baselineY: glyph.y + glyph.baselineOffset

  TextMetrics {
    id: glyphMetrics
    font.family: root.renderedFamily
    font.pixelSize: root.renderedFontSize
    text: root.renderedText
  }

  Text {
    id: glyph
    textFormat: Text.PlainText
    // Keep the shared line box and baseline intact. Correcting only the
    // horizontal painted bounds avoids per-glyph vertical drift.
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: root.horizontalCorrection
    text: root.renderedText
    color: root.color
    font.family: root.renderedFamily
    font.pixelSize: root.renderedFontSize
    renderType: Text.NativeRendering
  }

  Rectangle {
    visible: root.debugBounds
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: "#4488ff"
  }

  Rectangle {
    visible: root.debugBounds
    x: 0
    y: Math.round(root.baselineY)
    width: parent.width
    height: 1
    color: "#44ff88"
  }
}
