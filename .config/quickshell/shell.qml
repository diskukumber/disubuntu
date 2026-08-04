import Quickshell
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Minimal quickshell shell — entry point
//  Docs: ~/docs/system/07-quickshell.md
//
//  One bar + an app launcher (Mod+R in niri). Notifications
//  are rendered by niri itself.
// ─────────────────────────────────────────────────────────────

ShellRoot {
    id: root

    // The bar appears on every output automatically
    // (PanelWindow without an explicit `output` spans all screens).
    Bar {
        id: bar
        onLauncherRequested: launcher.toggle()
    }

    // Bottom bar: launcher button + window taskbar (waybar port).
    Taskbar {
        id: taskbar
        onLauncherRequested: launcher.toggle()
    }

    // Launcher popup, anchored to the bar window.
    // Toggled by niri (Mod+R → append to /tmp/qs-launcher-toggle).
    Launcher {
        id: launcher
        barWindow: bar
    }
}
