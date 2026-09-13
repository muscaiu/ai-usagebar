import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Quattro bar entry point. The popup is loaded separately so the object in
// the bar slot owns shell routing while Panel.qml remains focused on report
// collection and presentation.
BarWidget {
  id: root
  moduleName: "muscaiu.ai-usagebar"

  readonly property var panelItem: panelLoader.item
  readonly property bool opened: panelItem ? panelItem.opened === true : false
  readonly property bool popoutSwitchClosing: panelItem
    ? panelItem.popoutSwitchClosing === true
    : false

  function open() {
    if (panelItem) panelItem.open()
  }

  function close() {
    if (panelItem) panelItem.close()
  }

  function toggle() {
    if (panelItem) panelItem.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelItem) panelItem.closeForPopoutSwitch()
  }

  function refresh() {
    if (panelItem) panelItem.refresh()
  }

  function nextEntry() {
    if (panelItem) panelItem.selectEntry(panelItem.entryIndex + 1)
  }

  function launchDashboard() {
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation ai-usagebar-tui")
    root.close()
  }

  function injectPanel() {
    var target = panelItem
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    hasVisualContent: true
    fontSize: Style.font.bodySmall
    active: root.panelItem ? root.panelItem.alarming : false
    tooltipText: root.panelItem ? root.panelItem.tooltipText() : "AI usage"
    horizontalMargin: 8.5
    fixedWidth: root.bar && root.bar.vertical ? -1 : chipRow.implicitWidth + Style.spaceReal(17)

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.launchDashboard()
      else if (buttonCode === Qt.MiddleButton) root.nextEntry()
      else root.toggle()
    }

    onWheelMoved: function(delta) {
      if (delta !== 0 && root.panelItem)
        root.panelItem.selectEntry(root.panelItem.entryIndex + (delta < 0 ? 1 : -1))
    }

    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: Style.space(10)
      visible: !(root.bar && root.bar.vertical)

      Repeater {
        model: root.panelItem ? root.panelItem.barChips : []

        Row {
          id: chipItem
          spacing: Style.space(4)
          property var chip: modelData

          BrandMark {
            anchors.verticalCenter: parent.verticalCenter
            brand: chipItem.chip.brand || ""
            fallback: chipItem.chip.icon || "󰚩"
            // Provider mark stays neutral; the value segments already carry
            // the red/yellow signal, so the icon no longer doubles it.
            foreground: button.foreground
            fontFamily: button.fontFamily
            fontSize: button.fontSize
          }

          // Provider code (if shown) plus one colored segment per value the
          // chip displays - independently graded, so with barWindow "both"
          // only the side that's actually low turns yellow/red rather than
          // tinting the whole "69%/92%" pair by its worse side.
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            visible: chipItem.chip.providerLabel !== "" || valueRepeater.count > 0

            Text {
              visible: chipItem.chip.providerLabel !== ""
              textFormat: Text.PlainText
              text: chipItem.chip.providerLabel + (valueRepeater.count > 0 ? " " : "")
              color: button.foreground
              font.family: button.fontFamily
              font.pixelSize: button.fontSize
            }

            // Each value's own headroom decides its color - never the
            // chip-wide `alarming` flag, which is one report-level severity
            // for the whole entry and would otherwise tint every segment
            // the same regardless of which window is actually low.
            Repeater {
              id: valueRepeater
              model: chipItem.chip.valueSegments || []

              Text {
                textFormat: Text.PlainText
                text: modelData.text
                color: modelData.severity === "critical" ? Color.urgent
                  : modelData.severity === "warning" ? Model.warningColor()
                  : button.foreground
                font.family: button.fontFamily
                font.pixelSize: button.fontSize
              }
            }
          }
        }
      }
    }

    Text {
      visible: root.bar && root.bar.vertical
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: root.panelItem && root.panelItem.alarming ? "󰅙" : "󰚩"
      color: button.active && button.useActiveColor ? button.activeColor : button.foreground
      font.family: button.fontFamily
      font.pixelSize: button.fontSize
      rotation: button.textRotation
    }
  }
}
