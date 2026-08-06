import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Notification center (swaync control-center replacement).
//  Top-right popup: label · menubar (power/…) · app grid ·
//  backlight · volume · mpris · notifications + clear · DND.
//  Toggle: Mod+N (toggle file, see config.kdl) or the bar bell.
// ─────────────────────────────────────────────────────────────

PanelWindow {
    id: center

    required property var notifs          // Notifs service
    required property var icons           // AppIcons instance
    required property var barWindow       // top bar (geometry reference)

    Gruvbox { id: gruv }

    color: "#00000000"
    implicitWidth: 620
    implicitHeight: Math.min(850, Math.max(300, col.implicitHeight + 24))

    // PopupWindow is unusable in this quickshell build (0.3.0ppa8):
    // it never maps. PanelWindow (layer-shell) maps reliably. Centered
    // horizontally under the bar via the computed left margin.
    anchors.top: true
    anchors.left: true
    margins.top: -16
    margins.left: (screen.width - center.implicitWidth) / 2
    exclusiveZone: 0

    // PanelWindow `visible` behaves when toggled from a signal, but
    // keep it imperative — mirrors the notifs state exactly.
    visible: false
    Connections {
        target: center.notifs
        function onCenterOpenChanged() { center.visible = !!center.notifs.centerOpen; }
    }

    onVisibleChanged: {
        if (visible) backProc.running = true;
    }

    // ── Exec + tool availability ─────────────────────────────
    Process { id: execProc; command: [] }

    property var hasTool: ({})
    property bool toolsLoaded: false
    Process {
        id: toolsProc
        command: ["sh", "-c",
            "for b in gtklock powerprofilesctl nm-connection-editor blueman-manager " +
            "opensnitch-ui pavucontrol qjackctl; do command -v \"$b\" >/dev/null 2>&1 && echo \"$b\"; done"]
        stdout: SplitParser {
            onRead: d => {
                const t = String(d).trim();
                if (t) center.hasTool[t] = true;
            }
        }
        onRunningChanged: if (!running) {
            center.toolsLoaded = true;
            center.menus = center.buildMenus();
        }
    }

    function run(cmd) {
        execProc.command = ["sh", "-c", cmd];
        execProc.running = true;
    }

    // ── Menu definitions (swaync menubar parity) ─────────────
    property var menus: []                // built once tools are known
    property int openMenu: -1

    function buildMenus() {
        const defs = [];

        const power = {
            key: "power", icon: "\uF425", label: "Power", entries: [
                { label: "Reboot",      icon: "\uF459", cmd: "systemctl reboot" },
                { label: "Logout",      icon: "\uF5FD", cmd: "niri msg action quit" },
                { label: "Shut down",   icon: "\uF425", cmd: "systemctl poweroff" },
            ]
        };
        if (center.hasTool.gtklock) {
            power.entries.unshift({ label: "Lock", icon: "\uF33E", cmd: "gtklock" });
        }
        defs.push(power);

        if (center.hasTool.powerprofilesctl) {
            defs.push({
                key: "powermode", icon: "\uF079", label: "Power Mode", entries: [
                    { label: "Performance", icon: "\uF57E", cmd: "powerprofilesctl set performance" },
                    { label: "Balanced",    icon: "\uF580", cmd: "powerprofilesctl set balanced" },
                    { label: "Power saver", icon: "\uF4B2", cmd: "powerprofilesctl set power-saver" },
                ]
            });
        }

        const connEntries = [];
        if (center.hasTool["nm-connection-editor"]) connEntries.push({ label: "Network Manager", icon: "\uF5A9", cmd: "nm-connection-editor" });
        if (center.hasTool["blueman-manager"])  connEntries.push({ label: "Bluetooth Manager", icon: "\uF0AF", cmd: "blueman-manager" });
        if (center.hasTool["opensnitch-ui"])    connEntries.push({ label: "Firewall", icon: "\uF499", cmd: "opensnitch-ui" });
        if (connEntries.length > 0) {
            defs.push({ key: "connectivity", icon: "\uF5A9", label: "Connectivity", entries: connEntries });
        }

        const audioEntries = [];
        if (center.hasTool["pavucontrol"]) audioEntries.push({ label: "Audio Control", icon: "\uF57E", cmd: "pavucontrol" });
        if (center.hasTool["qjackctl"])    audioEntries.push({ label: "Advanced Audio", icon: "\uF57F", cmd: "qjackctl" });
        if (audioEntries.length > 0) {
            defs.push({ key: "audio", icon: "\uF57E", label: "Audio", entries: audioEntries });
        }

        return defs;
    }

    // ── Backlight (brightnessctl) ────────────────────────────
    property int backlightPct: 0
    Process {
        id: backProc
        command: ["sh", "-c",
            "g=$(brightnessctl get); m=$(brightnessctl max); echo $((g*100/m))"]
        stdout: SplitParser { onRead: d => { const v = parseInt(d, 10); if (!isNaN(v)) center.backlightPct = v; } }
    }
    property bool backDragging: false

    // ── Volume (Pipewire) ────────────────────────────────────
    property var sink: null
    property int volPct: 0
    property bool volDragging: false

    function refreshSink() {
        center.sink = Pipewire ? Pipewire.defaultSink : null;
        if (center.sink && !center.volDragging) {
            center.volPct = Math.round(center.sink.volume * 100);
        }
    }

    // ── Mpris ────────────────────────────────────────────────
    property var player: null

    function refreshPlayer() {
        let best = null;
        const vals = Mpris ? Mpris.players.values : [];
        for (const p of vals) { if (p.isPlaying) { best = p; break; } }
        if (!best && vals.length > 0) best = vals[0];
        center.player = best;
    }

    // ── Toggle via niri (Mod+N → toggle file) ────────────────
    Process { id: touchProc; command: ["touch", "/tmp/qs-center-toggle"] }
    Process {
        id: tailProc
        command: ["tail", "-n", "0", "-F", "/tmp/qs-center-toggle"]
        stdout: SplitParser { onRead: () => notifs.toggleCenter() }
    }

    // ── Timers ───────────────────────────────────────────────
    Component.onCompleted: {
        toolsProc.running = true;
        touchProc.running = true;
        tailProc.running = true;
        backProc.running = true;
        refreshSink();
        refreshPlayer();
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: backProc.running = true; }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: { refreshSink(); refreshPlayer(); } }

    // ── UI ───────────────────────────────────────────────────
    Rectangle {
        id: root
        anchors.fill: parent
        radius: 12
        color: gruv.colBar
        border.color: gruv.colTile
        border.width: 1

        // Click-away for menus (first child = bottom z; controls
        // rendered later still receive their own clicks).
        MouseArea {
            anchors.fill: parent
            onClicked: center.openMenu = -1
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ── Label: header ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uF2DA"              // mdi-history
                    color: gruv.colMuted
                    font.family: gruv.iconFont
                    font.pixelSize: 12
                }
                Text {
                    text: "Control Center"
                    color: gruv.colFg
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: notifs.dnd ? "\uF09B" : "\uF09A"
                    color: notifs.dnd ? gruv.colMuted : gruv.colAqua
                    font.family: gruv.iconFont
                    font.pixelSize: 12
                }
            }

            // ── Menubar ──────────────────────────────────────
            RowLayout {
                id: menuRow
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: center.menus

                    Rectangle {
                        required property var modelData
                        required property int index

                        Layout.preferredHeight: 30
                        Layout.preferredWidth: Math.max(90, menuLbl.implicitWidth + 34)
                        radius: 8
                        color: center.openMenu === index ? gruv.colGreen : gruv.colTile

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                color: center.openMenu === index ? gruv.colFgDark : gruv.colFg
                                font.family: gruv.iconFont
                                font.pixelSize: 11
                            }
                            Text {
                                id: menuLbl
                                text: modelData.label
                                color: center.openMenu === index ? gruv.colFgDark : gruv.colFg
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: center.openMenu = center.openMenu === index ? -1 : index
                        }
                    }
                }
            }

            // ── Menu dropdown (overlay) ──────────────────────
            Rectangle {
                id: dropdown
                Layout.fillWidth: true
                visible: center.openMenu >= 0
                height: visible ? dropdownCol.implicitHeight + 12 : 0
                radius: 8
                color: gruv.colTile
                z: 5

                Column {
                    id: dropdownCol
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Repeater {
                        model: center.openMenu >= 0 && center.openMenu < center.menus.length
                            ? center.menus[center.openMenu].entries : []

                        Rectangle {
                            required property var modelData

                            height: 28
                            width: parent.width
                            radius: 6
                            color: "#00000000"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                spacing: 8

                                Text {
                                    text: modelData.icon || "\uF156"
                                    color: gruv.colMuted
                                    font.family: gruv.iconFont
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: modelData.label
                                    color: gruv.colFg
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    center.openMenu = -1;
                                    center.run(modelData.cmd);
                                }
                            }
                        }
                    }
                }
            }

            // ── App grid (swaync buttons-grid) ───────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: [
                        { id: "helium",          cmd: "helium",          label: "Browser" },
                        { id: "com.mitchellh.ghostty", cmd: "ghostty",   label: "Terminal" },
                        { id: "Alacritty",       cmd: "alacritty",       label: "Alacritty" },
                        { id: "nvidia-settings", cmd: "nvidia-settings", label: "GPU" },
                    ]

                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 8
                        color: gruv.colTile

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3

                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: center.icons.iconFor(modelData.id)
                                visible: source !== ""
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: center.icons.letterFor(modelData.id)
                                color: gruv.colMuted
                                font.pixelSize: 11
                                font.bold: true
                                visible: center.icons.iconFor(modelData.id) === ""
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: gruv.colMuted
                                font.pixelSize: 8
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: center.run(modelData.cmd)
                        }
                    }
                }
            }

            // ── Backlight ────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "\uF0E0"              // mdi-brightness-7
                    color: gruv.colYellow
                    font.family: gruv.iconFont
                    font.pixelSize: 13
                }

                Slider {
                    id: backSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: center.backlightPct
                    onPressedChanged: {
                        center.backDragging = pressed;
                        if (pressed) center.backlightPct = value;
                    }
                    onValueChanged: {
                        if (center.backDragging) {
                            center.backlightPct = value;
                            center.run("brightnessctl set " + Math.round(value) + "%");
                        }
                    }
                }

                Text {
                    text: center.backlightPct + "%"
                    color: gruv.colFg
                    font.pixelSize: 9
                    font.bold: true
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ── Volume (Pipewire) ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: center.sink !== null

                Text {
                    text: center.sink && center.sink.muted ? "\uF581" : "\uF57E"
                    color: center.sink && center.sink.muted ? gruv.colRed : gruv.colAqua
                    font.family: gruv.iconFont
                    font.pixelSize: 13

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (center.sink && typeof center.sink.toggleMute === "function")
                                center.sink.toggleMute();
                        }
                    }
                }

                Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: center.volPct
                    onPressedChanged: {
                        center.volDragging = pressed;
                        if (pressed) center.volPct = value;
                    }
                    onValueChanged: {
                        if (center.volDragging && center.sink && typeof center.sink.setVolume === "function") {
                            center.volPct = value;
                            center.sink.setVolume(value / 100);
                        }
                    }
                }

                Text {
                    text: center.volPct + "%"
                    color: gruv.colFg
                    font.pixelSize: 9
                    font.bold: true
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                Layout.fillWidth: true
                visible: center.sink === null
                text: "No audio device — PipeWire is not running (apt install pipewire pipewire-pulse wireplumber)"
                color: gruv.colMuted
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            // ── Mpris ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: center.player !== null
                height: 96
                radius: 8
                color: gruv.colTile

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 76
                        Layout.preferredHeight: 76
                        radius: 6
                        color: "#504945"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: center.player && center.player.albumArt ? center.player.albumArt : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: center.player ? center.player.title || "" : ""
                            color: gruv.colFg
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: center.player ? center.player.artist || "" : ""
                            color: gruv.colMuted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.topMargin: 8
                            spacing: 12

                            Text {
                                text: "\uF4AE"      // mdi-skip-previous
                                color: center.player && center.player.canGoPrevious !== false ? gruv.colGreen : gruv.colMuted
                                font.family: gruv.iconFont
                                font.pixelSize: 16
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (center.player && typeof center.player.previous === "function")
                                            center.player.previous();
                                    }
                                }
                            }
                            Text {
                                text: center.player && center.player.isPlaying ? "\uF3E4" : "\uF40A"
                                color: gruv.colFg
                                font.family: gruv.iconFont
                                font.pixelSize: 20
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (center.player && typeof center.player.playPause === "function")
                                            center.player.playPause();
                                    }
                                }
                            }
                            Text {
                                text: "\uF4AD"      // mdi-skip-next
                                color: center.player && center.player.canGoNext !== false ? gruv.colGreen : gruv.colMuted
                                font.family: gruv.iconFont
                                font.pixelSize: 16
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (center.player && typeof center.player.next === "function")
                                            center.player.next();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Title: Notifications + Clear All ─────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: gruv.colFg
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    text: "Clear All"
                    color: gruv.colMuted
                    font.pixelSize: 9
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: notifs.dismissAll()
                    }
                }
            }

            // ── DND ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Do Not Disturb"
                    color: gruv.colFg
                    font.pixelSize: 10
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 18
                    radius: 9
                    color: notifs.dnd ? gruv.colGreen : gruv.colTile

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: gruv.colFgDark
                        anchors.verticalCenter: parent.verticalCenter
                        x: notifs.dnd ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: notifs.toggleDnd()
                    }
                }
            }

            // ── Notification list ────────────────────────────
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: notifs.list.length === 0
                    ? 90
                    : Math.min(370, notifs.list.length * 74)
                clip: true
                spacing: 6
                model: notifs.list

                delegate: NotifToast {
                    required property var modelData

                    notif: modelData
                    icons: center.icons
                    width: list.width
                    onDismiss: id => center.notifs.dismiss(id)
                }

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: gruv.colMuted
                    font.pixelSize: 10
                    visible: list.count === 0
                }
            }
        }
    }
}
