import Quickshell
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Minimal quickshell shell — entry point
//  Docs: ~/docs/system/07-quickshell.md
//
//  One bar + an app launcher (Mod+R in niri) + a full
//  swaync replacement: floating notification popups and a
//  control center (Mod+N in niri).
// ─────────────────────────────────────────────────────────────

ShellRoot {
    id: root

    // Pin both bars to the laptop panel (eDP-2). Quickshell's
    // default screen choice can land on the TV (HDMI-A-1), leaving
    // the laptop screen without a bar.
    readonly property var primaryScreen: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === "eDP-2") return screens[i];
        }
        return null;
    }

    // Shared helpers (auto-imported component types).
    AppIcons { id: appIcons }
    Notifs { id: notifs }

    Bar {
        id: bar
        screen: root.primaryScreen
        notifs: notifs
        onLauncherRequested: launcher.toggle()
    }

    // Bottom bar: launcher button + window taskbar (waybar port).
    Taskbar {
        id: taskbar
        screen: root.primaryScreen
        onLauncherRequested: launcher.toggle()
    }

    // Launcher popup, anchored to the bar window.
    // Toggled by niri (Mod+R → append to /tmp/qs-launcher-toggle).
    Launcher {
        id: launcher
        barWindow: bar
        screen: root.primaryScreen
    }

    // Notifications: floating popups + control center.
    // Toggled by niri (Mod+N → append to /tmp/qs-center-toggle).
    // NOTE: PopupWindow never maps in this quickshell build; all
    // popups are PanelWindows (layer-shell) positioned via anchors +
    // margins. Pass the raw Screen object as `screen`.
    NotifPopup {
        id: notifPopup
        notifs: notifs
        icons: appIcons
        barWindow: bar
        screen: root.primaryScreen
    }

    NotifCenter {
        id: notifCenter
        notifs: notifs
        icons: appIcons
        barWindow: bar
        screen: root.primaryScreen
    }
}
