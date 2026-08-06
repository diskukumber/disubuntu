import Quickshell
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Floating notification popups — top-right, below the bar
//  (swaync floating-notifications replacement).
//  One window holds the stack; newest on top. Visible only when
//  there is something to show and the center is closed.
// ─────────────────────────────────────────────────────────────

PanelWindow {
    id: popup

    required property var notifs          // Notifs service
    required property var icons           // AppIcons instance
    required property var barWindow       // top bar (geometry reference)

    color: "#00000000"
    implicitWidth: 400
    implicitHeight: Math.max(96, Math.min(col.implicitHeight, (barWindow.screen ? barWindow.screen.height : 1080) * 0.7))

    // PopupWindow is unusable in this quickshell build (0.3.0ppa8):
    // it never maps. PanelWindow (layer-shell) maps reliably. Position
    // via edge anchors + margins; the top bar is full-width so the
    // popup lands at its top-right corner.
    // NOTE: niri pushes top-layer surfaces below the bar's exclusive
    // zone, hence the -16 top margin (36 = bar height + 10 gap).
    anchors.top: true
    anchors.right: true
    margins.top: -16
    margins.right: 10
    exclusiveZone: 0

    // PanelWindow `visible` behaves when toggled from a signal, but
    // keep it imperative — mirrors the notifs state exactly.
    visible: false
    function refresh() {
        const want = notifs && notifs.list.length > 0 && !notifs.dnd && !notifs.centerOpen;
        if (popup.visible !== want) popup.visible = want;
    }
    Connections {
        target: popup.notifs
        function onListChanged() { popup.refresh(); }
        function onDndChanged() { popup.refresh(); }
        function onCenterOpenChanged() { popup.refresh(); }
    }

    Component.onCompleted: refresh()

    Column {
        id: col
        width: popup.width
        spacing: 8

        Repeater {
            model: notifs ? notifs.list : []

            NotifToast {
                required property var modelData

                notif: modelData
                icons: popup.icons
                popupMode: true
                width: popup.width
                onDismiss: id => popup.notifs.dismiss(id)
            }
        }
    }
}
