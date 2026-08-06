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

    // Only workspaces/windows of this output are shown (the bars
    // are pinned to one screen; niri reports every output's
    // workspaces/windows, including "active" per output).
    readonly property string outputName: bar.screen ? bar.screen.name : "eDP-2"
    property var wsOutputs: ({})           // workspace id → output name

    // Waybar-parity modules: caffeine (idle inhibitor), lock keys,
    // layout switch + IP tooltip.
    property bool caffeineOn: false        // systemd-inhibit running?
    property string lockState: "0 0"       // numlock capslock (1/0)
    property string ipText: ""             // hover tooltip for NET
    property string tipText: ""            // hover tooltip text

    readonly property bool numLock: lockState.split(" ")[0] === "1"
    readonly property bool capsLock: lockState.split(" ")[1] === "1"

    signal launcherRequested()

    property var notifs: null          // Notifs service (bell + DND)

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
                        if (w.workspace_id && bar.wsOutputs[w.workspace_id] === bar.outputName)
                            ids.add(w.workspace_id);
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

    function focusWorkspaceRelative(dir) {
        actionProc.command = ["niri", "msg", "action",
            dir === "down" ? "focus-workspace-down" : "focus-workspace-up"];
        actionProc.running = true;
    }

    // ── Caffeine (waybar idle_inhibitor port) ────────────────
    // systemd-inhibit runs in the background; its pid lives in
    // /tmp/qs-caffeine.pid (also used to restore state on start).
    Process { id: caffeineProc; command: [] }
    Process { id: caffeineKillProc; command: [] }

    function toggleCaffeine() {
        if (bar.caffeineOn) {
            caffeineKillProc.command = ["sh", "-c",
                "[ -f /tmp/qs-caffeine.pid ] && kill $(cat /tmp/qs-caffeine.pid) && rm -f /tmp/qs-caffeine.pid"];
            caffeineKillProc.running = true;
            bar.caffeineOn = false;
        } else {
            caffeineProc.command = ["sh", "-c",
                "systemd-inhibit --what=idle:handle-lid-switch --why=Caffeine --mode=block sleep infinity & echo $! > /tmp/qs-caffeine.pid"];
            caffeineProc.running = true;
            bar.caffeineOn = true;
        }
    }

    Process {
        id: caffeineStateProc
        command: ["sh", "-c", "[ -f /tmp/qs-caffeine.pid ] && echo on"]
        stdout: SplitParser { onRead: d => { if (String(d).trim() === "on") bar.caffeineOn = true; } }
    }

    // ── Lock keys (waybar keyboard-state port) ───────────────
    // Reads the LED brightness of the built-in AT keyboard.
    Process {
        id: lockProc
        command: ["sh", "-c",
            "for l in numlock capslock; do v=0; for d in /sys/class/leds/input*::$l; do " +
            "[ \"$(cat \"$d/device/name\" 2>/dev/null)\" = \"AT Translated Set 2 keyboard\" ] && " +
            "v=$(cat \"$d/brightness\" 2>/dev/null); done; printf \"%s \" \"$v\"; done"]
        stdout: SplitParser { onRead: d => { const t = String(d).trim(); if (t !== "") bar.lockState = t; } }
    }

    // ── Layout switch (waybar hyprland/language on-click) ────
    Process { id: layoutProc; command: ["niri", "msg", "action", "switch-layout", "next"] }

    function switchLayout() { layoutProc.running = true; }

    // ── NET tooltip: current IP (waybar network tooltip) ─────
    Process {
        id: ipProc
        command: ["sh", "-c",
            "ip -4 -o addr show scope global | awk '$2!=\"lo\"{print $2, $4; exit}'"]
        stdout: SplitParser { onRead: d => { const t = String(d).trim(); if (t !== "") { bar.ipText = t; if (bar.tipText.startsWith("IP")) bar.tipText = "IP: " + t; } } }
    }

    // Dynamic: only this output's workspaces holding windows plus
    // the active one. Labels are plain numbers, with the workspace
    // name appended.
    function parseWorkspaces(json) {
        const list = JSON.parse(json);
        const outMap = {};
        for (const ws of list) outMap[ws.id] = ws.output;
        bar.wsOutputs = outMap;
        const arr = [];
        for (const ws of list) {
            if (ws.output !== bar.outputName) continue;
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
    Component.onCompleted: {
        workspacesProc.running = true;
        windowsProc.running = true;
        lockProc.running = true;
        caffeineStateProc.running = true;
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: workspacesProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: windowsProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: netProc.running = true; }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuProc.running = true; }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: lockProc.running = true; }
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

        // Workspaces — dynamic pill group with a sliding active
        // indicator (ported from caelestia-dots/shell) and an
        // animated background pill spanning occupied runs.
        Rectangle {
            id: wsBox

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: pillRow.implicitWidth + 12
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            radius: 8
            color: gruv.colTile

            // Wheel over the workspace group switches workspaces
            // (waybar on-scroll parity). No buttons: pill clicks pass.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) bar.focusWorkspaceRelative("down");
                    else bar.focusWorkspaceRelative("up");
                }
            }

            // Contiguous runs of occupied workspaces → background pills
            property var runs: []

            function computeRuns() {
                const occ = new Set(bar.windowIds);
                const ws = bar.workspaces;
                const arr = [];
                let i = 0;
                while (i < ws.length) {
                    if (!occ.has(ws[i].id)) { i++; continue; }
                    const run = { start: i, end: i };
                    let j = i + 1;
                    while (j < ws.length && occ.has(ws[j].id)) { run.end = j; j++; }
                    arr.push(run);
                    i = j;
                }
                runs = arr;
            }

            Connections {
                target: bar
                function onWorkspacesChanged() { wsBox.computeRuns(); }
                function onWindowIdsChanged() { wsBox.computeRuns(); }
            }

            Component.onCompleted: computeRuns()

            // Occupied background — darker pill behind occupied runs
            Repeater {
                model: wsBox.runs

                Rectangle {
                    required property var modelData

                    readonly property var firstPill: pillsRep.itemAt(modelData.start)
                    readonly property var lastPill: pillsRep.itemAt(modelData.end)

                    z: 0
                    y: pillRow.y + (firstPill ? firstPill.y : 0)
                    height: 14
                    radius: 7
                    color: gruv.colBar

                    x: pillRow.x + (firstPill ? firstPill.x : 0)
                    width: firstPill && lastPill
                         ? lastPill.x + lastPill.width - firstPill.x : 0

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            }

            // Active indicator — glides over the active pill
            Rectangle {
                id: activeInd

                readonly property var pill: {
                    for (let i = 0; i < pillsRep.count; i++) {
                        const p = pillsRep.itemAt(i);
                        if (p && p.modelData.active) return p;
                    }
                    return null;
                }

                z: 1
                visible: pillsRep.count > 0
                x: pillRow.x + (pill ? pill.x : 0)
                y: pillRow.y + (pill ? pill.y : 0)
                width: pill ? pill.width : 22
                height: 14
                radius: 7
                color: gruv.colGreen

                Behavior on x {
                    SpringAnimation { spring: 3; damping: 0.5 }
                }
                Behavior on width {
                    SpringAnimation { spring: 3; damping: 0.5 }
                }
            }

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 2
                z: 2

                Repeater {
                    id: pillsRep
                    model: bar.workspaces

                    Rectangle {
                        required property var modelData
                        property bool hovered: false

                        Layout.preferredWidth: Math.max(22, labelText.implicitWidth + 10)
                        Layout.preferredHeight: 14
                        radius: 7
                        color: "transparent"

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: hovered ? gruv.colGreen
                                 : modelData.urgent ? gruv.colRed
                                 : modelData.active ? gruv.colFgDark
                                 : bar.windowIds.includes(modelData.id) ? gruv.colFg
                                 : gruv.colMuted
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
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const p = parent.mapToItem(bar, 0, 0);
                            bar.tipText = bar.ipText ? "IP: " + bar.ipText : "…";
                            tip.showAt(bar, Qt.rect(p.x, bar.implicitHeight + 6, 1, 1));
                            ipProc.running = true;
                        }
                        onExited: bar.tipText = ""
                    }
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

                // KEYBOARD lock state (num/caps) — waybar keyboard-state port
                Text {
                    color: bar.numLock ? gruv.colRed : gruv.colGreen
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF3BE"          // mdi-numeric-9-box-outline (numlock)
                }
                Text {
                    color: bar.capsLock ? gruv.colRed : gruv.colGreen
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF30E"          // mdi-keyboard-caps (capslock)
                }

                // KEYBOARD layout — click switches (waybar language on-click)
                Text {
                    color: gruv.colPurple
                    font.family: gruv.iconFont
                    font.pixelSize: 10
                    text: "\uF30C"          // mdi-keyboard
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const p = parent.mapToItem(bar, 0, 0);
                            bar.tipText = "Click to switch keyboard layout";
                            tip.showAt(bar, Qt.rect(p.x, bar.implicitHeight + 6, 1, 1));
                        }
                        onExited: bar.tipText = ""
                        onClicked: bar.switchLayout()
                    }
                }
                Text {
                    color: gruv.colPurple
                    font.pixelSize: 9
                    font.bold: true
                    text: bar.kbdShort
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const p = parent.mapToItem(bar, 0, 0);
                            bar.tipText = "Click to switch keyboard layout";
                            tip.showAt(bar, Qt.rect(p.x, bar.implicitHeight + 6, 1, 1));
                        }
                        onExited: bar.tipText = ""
                        onClicked: bar.switchLayout()
                    }
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

        // Bell (notifications) — swaync port: left = open the
        // control center, right = toggle Do Not Disturb.
        Rectangle {
            id: bellBox

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: 26
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            Layout.leftMargin: 8
            radius: 8
            color: gruv.colTile
            visible: bar.notifs !== null

            Text {
                anchors.centerIn: parent
                text: bar.notifs && bar.notifs.dnd ? "\uF09B" : "\uF09A"
                color: bar.notifs && bar.notifs.dnd ? gruv.colMuted : gruv.colGreen
                font.family: gruv.iconFont
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (!bar.notifs) return;
                    if (mouse.button === Qt.RightButton) bar.notifs.toggleDnd();
                    else bar.notifs.toggleCenter();
                }
                onEntered: {
                    const p = parent.mapToItem(bar, 0, 0);
                    bar.tipText = "Notifications — left: center, right: DND";
                    tip.showAt(bar, Qt.rect(p.x, bar.implicitHeight + 6, 1, 1));
                }
                onExited: bar.tipText = ""
            }
        }

        // Caffeine (idle inhibitor) — waybar idle_inhibitor port:
        // click toggles a systemd-inhibit lock; green = active.
        Rectangle {
            id: caffeineBox

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 15
            Layout.preferredWidth: 26
            Layout.topMargin: 5
            Layout.bottomMargin: 6
            Layout.leftMargin: 8
            radius: 8
            color: gruv.colTile

            Text {
                anchors.centerIn: parent
                text: bar.caffeineOn ? "\uF176" : "\uF1AA"   // mdi-coffee / mdi-cup
                color: bar.caffeineOn ? gruv.colGreen : gruv.colMuted
                font.family: gruv.iconFont
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.toggleCaffeine()
                onEntered: {
                    const p = parent.mapToItem(bar, 0, 0);
                    bar.tipText = bar.caffeineOn ? "Caffeine ON — click to disable" : "Caffeine OFF — click to enable";
                    tip.showAt(bar, Qt.rect(p.x, bar.implicitHeight + 6, 1, 1));
                }
                onExited: bar.tipText = ""
            }
        }
    }

    // Floating hover tooltip (popup window; see ToolTip.qml)
    ToolTip {
        id: tip
        text: bar.tipText
    }
}