import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Bottom bar — a slim dock:
//    left:  app launcher button (grid icon, opens the launcher)
//    right: window taskbar — ICONS ONLY (app icon per window;
//           letter fallback when no icon exists)
//  Nothing else. Docked at the bottom edge; the top corners
//  sweep in one full-bar-height curve that just touches the
//  screen edge at the corners (Canvas).
//  Data: `niri msg -j windows` (loop) + AppIcons resolver.
// ─────────────────────────────────────────────────────────────

PanelWindow {
    id: taskbar

    Gruvbox { id: gruv }
    AppIcons { id: appIcons }

    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 44
    implicitHeight: 44
    color: "#00000000"

    // ── State ────────────────────────────────────────────────
    property var windows: []               // [{id, appId, title}]
    property int focusedId: -1

    signal launcherRequested()

    // ── niri IPC: window list (1 s loop) ─────────────────────
    Process {
        id: winProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                try { parseWindows(data); } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    Process { id: actionProc; command: [] }

    function action(args) {
        actionProc.command = ["niri", "msg", "action"].concat(args);
        actionProc.running = true;
    }

    function parseWindows(json) {
        const list = JSON.parse(json);
        const arr = [];
        for (const w of list) {
            arr.push({ id: w.id, appId: w.app_id || "", title: w.title || "" });
            if (w["is_focused"]) focusedId = w.id;
        }
        windows = arr;
    }

    // ── Timers ───────────────────────────────────────────────
    Component.onCompleted: winProc.running = true;
    Timer { interval: 1000; running: true; repeat: true; onTriggered: winProc.running = true; }

    // ── Bar shape ────────────────────────────────────────────
    Canvas {
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height, R = h;
            ctx.fillStyle = gruv.colBar;
            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.arc(R, R, R, Math.PI, 1.5 * Math.PI, false);
            ctx.lineTo(w - R, 0);
            ctx.arc(w - R, R, R, -0.5 * Math.PI, 0, false);
            ctx.closePath();
            ctx.fill();
        }
    }

    // ── Content ──────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 8

        // App launcher button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 40
            Layout.preferredHeight: 32
            radius: 16
            color: "#00000000"

            Text {
                anchors.centerIn: parent
                text: "\uF570"              // mdi-view-grid
                color: gruv.colAqua
                font.family: gruv.iconFont
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: taskbar.launcherRequested()
            }
        }

        // Window taskbar — icon only
        RowLayout {
            id: winRow
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: taskbar.windows

                Rectangle {
                    required property var modelData
                    property bool focused: modelData.id === taskbar.focusedId
                    property bool hovered: false

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 36
                    radius: 18

                    color: focused ? gruv.colTile : "#00000000"

                    // window icon, or a letter when none is found
                    IconImage {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: appIcons.iconFor(modelData.appId)
                        smooth: true
                        visible: source !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        text: appIcons.letterFor(modelData.appId)
                        color: focused ? gruv.colFg : gruv.colMuted
                        font.pixelSize: 13
                        font.bold: true
                        visible: appIcons.iconFor(modelData.appId) === ""
                    }

                    // bottom indicator (waybar inset style)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        height: 3
                        radius: 2
                        color: hovered ? gruv.colGreen
                             : focused ? gruv.colGreen
                             : gruv.colMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton)
                                taskbar.action(["close-window", "--id", String(modelData.id)]);
                            else
                                taskbar.action(["focus-window", "--id", String(modelData.id)]);
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }   // left spacer
        }
    }
}