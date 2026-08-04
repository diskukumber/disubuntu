import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Top bar — a port of the waybar top bar (diskukumber/disnixos):
//    left:  niri workspaces — DYNAMIC (only used + active ones),
//           numbered with arabic digits (name appended if set)
//    right: system stats — NET(↓/↑) · MEM ⏣ · CPU ⏣ · KEYBOARD
//           ⌨ · DATE 🖹 · CLOCK 🕐 + the system tray
//  Icons are Glyphs from the Material Design Icons font (apt
//  package: fonts-materialdesignicons-webfont).
//  Data: `niri msg` IPC + /proc, all inside quickshell.
//  Docked at the top edge; the bottom corners sweep in one full-
//  bar-height curve that just touches the screen edge at the
//  corners (drawn with Canvas).
// ─────────────────────────────────────────────────────────────

PanelWindow {
    id: bar

    Gruvbox { id: gruv }

    anchors { top: true; left: true; right: true }
    exclusiveZone: 26
    implicitHeight: 26
    color: "#00000000"

    // ── State ────────────────────────────────────────────────
    property var workspaces: []            // [{id, label, active, urgent}]
    property string clockText: ""
    property string dateText: ""
    property string kbdShort: ".."
    property string cpuPct: "0"
    property int memPct: 0
    property string netText: "↓0B ↑0B"

    property var prevNet: ({ down: -1, up: -1 })
    property var prevCpu: ({ total: -1, idle: -1 })

    signal launcherRequested()

    // ── niri IPC: workspaces + windows (1 s loop) ────────────
    Process {
        id: workspacesProc
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                try { parseWorkspaces(data); } catch (e) {}
            }
        }
    }

    // Workspace ids that currently hold windows (dynamic filter)
    property var windowIds: []

    Process {
        id: windowsProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                try {
                    const ids = new Set();
                    for (const w of JSON.parse(data)) {
                        if (w.workspace_id) ids.add(w.workspace_id);
                    }
                    windowIds = [...ids];
                } catch (e) {}
            }
        }
    }

    Process { id: actionProc; command: [] }

    function focusWorkspace(id) {
        actionProc.command = ["niri", "msg", "action", "focus-workspace", String(id)];
        actionProc.running = true;
    }

    // Dynamic: only workspaces holding windows + the active one.
    // Labels are plain numbers, with the workspace name appended.
    function parseWorkspaces(json) {
        const list = JSON.parse(json);
        const arr = [];
        for (const ws of list) {
            const hasWindows = windowIds.includes(ws.id) || ws["is_active"] === true;
            if (!hasWindows) continue;
            const name = ws.name ? " " + ws.name : "";
            arr.push({
                id: ws.id,
                label: String(ws.id) + name,
                active: ws["is_active"] === true,
                urgent: ws["is_urgent"] === true,
            });
        }
        arr.sort((a, b) => a.id - b.id);
        workspaces = arr;
    }

    // ── Stats data ───────────────────────────────────────────
    Process {                                   // /proc/net/dev
        id: netProc
        command: ["sh", "-c",
            "awk 'NR>2 { split($1,a,\":\"); if(a[1]!=\"lo\"){print a[1],$2,$10; exit} }' /proc/net/dev"]
        stdout: SplitParser { onRead: data => applyNet(data); }
    }
    function applyNet(line) {
        const m = line.trim().split(/\s+/);
        if (m.length < 3) return;
        const d = parseInt(m[1], 10), u = parseInt(m[2], 10);
        if (bar.prevNet.down >= 0) {
            const ds = fmt(d - bar.prevNet.down);
            const us = fmt(u - bar.prevNet.up);
            bar.netText = "<font color=\"" + gruv.colRed + "\">↓</font>" + ds +
                          " <font color=\"" + gruv.colGreen + "\">↑</font>" + us;
        }
        bar.prevNet = { down: d, up: u };
    }

    Process {                                   // /proc/stat
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu  /{print $2,$5}' /proc/stat"]
        stdout: SplitParser { onRead: data => applyCpu(data); }
    }
    function applyCpu(line) {
        const m = line.trim().split(/\s+/);
        if (m.length < 2) return;
        const total = parseInt(m[0], 10) + parseInt(m[1], 10);
        const idle = parseInt(m[1], 10);
        if (bar.prevCpu.total >= 0) {
            const dt = total - bar.prevCpu.total;
            const di = idle - bar.prevCpu.idle;
            if (dt > 0) bar.cpuPct = (100 * (dt - di) / dt).toFixed(0);
        }
        bar.prevCpu = { total: total, idle: idle };
    }

    Process {                                   // /proc/meminfo
        id: memProc
        command: ["sh", "-c",
            "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf \"%d\",(t-a)/t*100}' /proc/meminfo"]
        stdout: SplitParser { onRead: data => { if (data.trim() !== "") memPct = parseInt(data, 10) || 0; } }
    }

    Process {                                   // niri keyboard layout
        id: kbdProc
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const js = JSON.parse(data);
                    const name = (js.names || [])[js.current_idx || 0] || "";
                    const m = name.match(/\(([^)]+)\)/);
                    kbdShort = m ? m[1] : name.slice(0, 2).toUpperCase();
                } catch (e) {}
            }
        }
    }

    // ── Timers ───────────────────────────────────────────────
    Component.onCompleted: { workspacesProc.running = true; windowsProc.running = true; }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: workspacesProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: windowsProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: netProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuProc.running = true; }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: memProc.running = true; }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: kbdProc.running = true; }
    Timer {
        interval: 1000; running: true; repeat: true;
        onTriggered: {
            const now = new Date();
            clockText = Qt.formatTime(now, "hh:mm");
            dateText = Qt.formatDate(now, "ddd MMM d");
        }
    }

    // ── Helpers ──────────────────────────────────────────────
    function fmt(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + "M";
        if (bytes >= 1024) return (bytes / 1024).toFixed(0) + "K";
        return String(bytes);
    }

    // ── Bar shape ────────────────────────────────────────────
    Canvas {
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height, R = h;
            ctx.fillStyle = gruv.colBar;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.arc(w - R, 0, R, 0, Math.PI / 2, false);
            ctx.lineTo(R, h);
            ctx.arc(R, 0, R, Math.PI / 2, Math.PI, false);
            ctx.closePath();
            ctx.fill();
        }
    }

    // ── Content ──────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        // Workspaces — dynamic pill group
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: pillRow.implicitWidth + 12
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            radius: 8
            color: gruv.colTile

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: bar.workspaces

                    Rectangle {
                        required property var modelData
                        property bool hovered: false

                        Layout.preferredWidth: Math.max(22, labelText.implicitWidth + 10)
                        Layout.preferredHeight: 14
                        radius: 7

                        color: hovered ? gruv.colGreen
                             : modelData.urgent ? gruv.colRed
                             : modelData.active ? gruv.colBar
                             : gruv.colAqua

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: gruv.colFg
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false
                            onClicked: bar.focusWorkspace(modelData.id)
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Stats cluster (one icon + value per module)
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: statsRow.implicitWidth + 16
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            radius: 8
            color: gruv.colTile

            RowLayout {
                id: statsRow
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 9

                // NET — rich text with colored arrows (no icon font)
                Text {
                    color: gruv.colFg
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.netText
                    textFormat: Text.RichText
                }

                // MEM
                Text {
                    color: gruv.colYellow
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF35B"          // mdi-memory
                }
                Text {
                    color: gruv.colYellow
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.memPct + "%"
                }

                // CPU
                Text {
                    color: gruv.colOrange
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF61A"          // mdi-chip
                }
                Text {
                    color: gruv.colOrange
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.cpuPct + "%"
                }

                // KEYBOARD layout
                Text {
                    color: gruv.colPurple
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF30C"          // mdi-keyboard
                }
                Text {
                    color: gruv.colPurple
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.kbdShort
                }

                // DATE
                Text {
                    color: gruv.colAqua
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF0ED"          // mdi-calendar
                }
                Text {
                    color: gruv.colAqua
                    font.pixelSize: 9
                    text: bar.dateText
                }

                // CLOCK
                Text {
                    color: gruv.colRed
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF150"          // mdi-clock
                }
                Text {
                    color: gruv.colFg
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.clockText
                }
            }
        }

        // System tray (status notifier items)
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: trayRow.implicitWidth + 12
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            Layout.leftMargin: 8
            radius: 8
            color: gruv.colTile
            visible: trayRow.count > 0

            RowLayout {
                id: trayRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: SystemTray.items

                    Item {
                        required property var modelData
                        property bool hovered: false

                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 15

                        Image {
                            anchors.centerIn: parent
                            source: modelData.icon
                            width: 15
                            height: 15
                            sourceSize: Qt.size(15, 15)
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu)
                                        modelData.display(bar, mouseX, mouseY);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    modelData.secondaryActivate();
                                } else {
                                    modelData.activate();
                                }
                            }
                            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }
        }
    }
}