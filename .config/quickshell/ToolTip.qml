import Quickshell
import QtQuick

// ─────────────────────────────────────────────────────────────
//  Floating hover tooltip — a PopupWindow (QtQuick.Controls
//  is not installed on this system). Waybar-tooltip styling:
//  #3c3836 background, #98971a border, #ebdbb2 bold text.
//  Usage:
//      Tip { id: tip }
//      ... tip.showAt(win, Qt.rect(x, y, w, h));  tip.hide()
// ─────────────────────────────────────────────────────────────

PopupWindow {
    id: tip

    // Visibility follows the text: an empty tooltip is invisible.
    visible: tip.text !== ""
    grabFocus: false
    implicitWidth: Math.max(48, label.implicitWidth + 16)
    implicitHeight: label.implicitHeight + 8
    color: "#00000000"

    property alias text: label.text

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#3c3836"
        border.color: "#98971a"
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            color: "#ebdbb2"
            font.pixelSize: 10
            font.bold: true
        }
    }

    // Anchor to a window and a rect in its coordinates; the popup
    // appears with its top-left at that rect (clamped on-screen).
    // y is clamped against the screen, not the anchor window, so
    // tooltips can hang below a top bar or above a bottom bar.
    function showAt(win, rect) {
        tip.anchor.window = win;
        const w = tip.implicitWidth, h = tip.implicitHeight;
        const sh = win.screen ? win.screen.height : win.height;
        const x = Math.min(Math.max(rect.x, 8), win.width - w - 8);
        const y = Math.min(Math.max(rect.y, 8), sh - h - 8);
        tip.anchor.rect.x = x;
        tip.anchor.rect.y = y;
    }

    function hide() {
        tip.text = "";
    }
}
