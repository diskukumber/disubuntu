import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// ─────────────────────────────────────────────────────────────
//  Shared notification service (swaync replacement).
//
//  One NotificationServer owns org.freedesktop.Notifications on
//  D-Bus (apps send notifications straight into quickshell — no
//  swaync, no niri daemon, no extra process). NotifCenter and
//  NotifPopup both render `list`.
//
//  Note: this component must be instantiated EXACTLY ONCE (in
//  shell.qml) — two servers would fight for the bus name.
//  Root is an Item (not QtObject): quickshell service objects
//  like NotificationServer need a parent with a `data` default
//  property to attach to.
// ─────────────────────────────────────────────────────────────

Item {
    id: root

    property var list: []          // [{n: NotificationObject, time: ms}] — newest first
    property bool dnd: false       // suppress popups (center still collects)
    property bool centerOpen: false

    function remove(id) {
        root.list = root.list.filter(e => e.n.id !== id);
    }

    function dismiss(id) {
        for (const e of root.list) {
            if (e.n.id === id) {
                if (typeof e.n.dismiss === "function") e.n.dismiss();
                root.remove(id);
                return;
            }
        }
    }

    function dismissAll() {
        for (const e of root.list.slice()) {
            if (typeof e.n.dismiss === "function") e.n.dismiss();
        }
        root.list = [];
    }

    function toggleDnd() { root.dnd = !root.dnd; }
    function toggleCenter() { root.centerOpen = !root.centerOpen; }

    NotificationServer {
        onNotification: n => {
            // Keep the notification object alive (D-Bus releases its
            // reference once the Notify call returns).
            n.tracked = true;
            root.list = [{ n: n, time: Date.now() }, ...root.list];
        }
    }
}
