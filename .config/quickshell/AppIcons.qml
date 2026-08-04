import Quickshell.Io
import QtQuick

// ─────────────────────────────────────────────────────────────
//  AppIcon resolver — turns an app id / icon name into a real
//  icon file path (file:// URL), falling back to "" when none
//  is found (callers draw a letter instead).
//
//  Scans every icon theme + hicolor + pixmaps once at startup
//  and indexes files by both short and full name. Auto-imported
//  as a component type (uppercase file name).
// ─────────────────────────────────────────────────────────────

Item {
    property var iconPaths: ({})   // "name" -> "file:///path"

    function iconFor(appId) {
        if (!appId) return "";
        const id = String(appId);
        const candidates = [id, id.toLowerCase()];

        // last dotted segments: com.mitchellh.ghostty -> ghostty
        const parts = id.split(".");
        if (parts.length > 1) {
            for (let i = parts.length - 1; i > 0; i--) {
                const s = parts.slice(i).join(".");
                candidates.push(s, s.toLowerCase());
            }
        }
        // whole id as a file name
        for (const ext of ["png", "svg"]) {
            candidates.push(id + "." + ext, id.toLowerCase() + "." + ext);
        }
        for (const c of candidates) {
            if (iconPaths[c]) return iconPaths[c];
        }
        return "";
    }

    function letterFor(appId) {
        if (!appId) return "?";
        const c = String(appId).trim().charAt(0);
        return c ? c.toUpperCase() : "?";
    }

    Process {
        id: scanProc
        command: [
            "sh", "-c",
            "find /usr/share/icons /usr/share/pixmaps " +
            "-type f \\( -name '*.png' -o -name '*.svg' \\) " +
            "-printf '%f %p\\n' 2>/dev/null"
        ]

        stdout: SplitParser {
            onRead: data => {
                const line = String(data).trim();
                const sp = line.indexOf(" ");
                if (sp <= 0) return;
                const name = line.slice(0, sp);                  // file.png
                const path = line.slice(sp + 1);
                const base = name.replace(/\.[a-z0-9]+$/i, "");  // file
                iconPaths[name] = "file://" + path;
                iconPaths[base] = iconPaths[base] || "file://" + path;
            }
        }
    }

    Component.onCompleted: scanProc.running = true
}