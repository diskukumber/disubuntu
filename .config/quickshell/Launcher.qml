import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  Launcher — quickshell app launcher popup.
//
//  Trigger: niri binds Mod+R to:
//      spawn-sh "echo toggle >> /tmp/qs-launcher-toggle"
//  A `tail -F` process watches that file; any new line toggles
//  the popup. No extra daemons, no FileReader needed.
//
//  Apps come from DesktopEntries (parses .desktop files),
//  icons resolve through the shared AppIcons map.
//  Enter launches, Esc closes, arrows navigate.
// ─────────────────────────────────────────────────────────────

PopupWindow {
    id: launcher

    Gruvbox { id: gruv }
    AppIcons { id: appIcons }

    // The bar window this popup anchors to (set from shell.qml)
    required property var barWindow

    // Positioned via anchor.rect (see positionPopup()) relative to the bar.
    implicitWidth: 480
    implicitHeight: Math.min(44 + 44 * visibleApps.length, 44 + 44 * 8)
    grabFocus: false
    visible: false

    // ── Theme (Gruvbox, same as the bars) ────────────────────
    readonly property color colBg:     gruv.colBar
    readonly property color colBorder: gruv.colTile
    readonly property color colSep:    gruv.colMuted

    // ── App data ─────────────────────────────────────────────
    property var allApps: []        // full DesktopEntry list
    property var visibleApps: []    // filtered by search
    property string query: ""
    property int selected: 0
    property bool appsReady: false

    // ── Trigger: watch the toggle file ───────────────────────
    Process { id: touchProc; command: ["touch", "/tmp/qs-launcher-toggle"] }

    Process {
        id: tailProc
        command: ["tail", "-n", "0", "-F", "/tmp/qs-launcher-toggle"]
        stdout: SplitParser { onRead: () => launcher.toggle() }
    }

    // ── Toggle / show ────────────────────────────────────────
    function toggle() {
        if (visible) closeLauncher();
        else openLauncher();
    }

    function openLauncher() {
        query = "";
        selected = 0;
        rebuildFilter();
        positionPopup();
        visible = true;
        searchField.forceActiveFocus();
    }

    function closeLauncher() {
        visible = false;
        searchField.text = "";
    }

    function positionPopup() {
        launcher.anchor.window = barWindow;
        // center the popup under the bar
        launcher.anchor.rect.x = barWindow.width / 2 - width / 2;
        launcher.anchor.rect.y = barWindow.height + 8;
    }

    // ── Filtering ────────────────────────────────────────────
    function rebuildFilter() {
        const q = query.trim().toLowerCase();
        visibleApps = q === ""
            ? allApps
            : allApps.filter(a => a.name.toLowerCase().includes(q));
        selected = 0;
    }

    function launch(idx) {
        const app = visibleApps[idx];
        if (app) {
            app.execute();
            closeLauncher();
        }
    }

    Component.onCompleted: {
        // DesktopEntries loads asynchronously; grab the list when ready.
        const tryLoad = () => {
            const vals = DesktopEntries.applications.values;
            if (vals && vals.length > 0) {
                allApps = vals.slice().sort((a, b) => a.name.localeCompare(b.name));
                appsReady = true;
                rebuildFilter();
            }
        };

        DesktopEntries.applicationsChanged.connect(tryLoad);
        tryLoad();

        // prepare trigger file, then start watching
        touchProc.running = true;
        tailProc.running = true;

        // anchor to the bar before first show
        positionPopup();
    }

    // ── UI ───────────────────────────────────────────────────
    Rectangle {
        id: root
        anchors.fill: parent
        radius: 12
        color: launcher.colBg
        border.color: launcher.colBorder
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Search field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "\uF349"          // mdi-magnify
                        color: gruv.colMuted
                        font.family: gruv.iconFont
                        font.pixelSize: 16
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: gruv.colFg
                        font.pixelSize: 14
                        clip: true
                        selectByMouse: true

                        onTextChanged: {
                            launcher.query = text;
                            launcher.rebuildFilter();
                        }

                        Keys.onReturnPressed: {
                            launcher.launch(launcher.selected);
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: {
                            launcher.closeLauncher();
                            event.accepted = true;
                        }
                        Keys.onDownPressed: {
                            launcher.selected = Math.min(launcher.selected + 1, launcher.visibleApps.length - 1);
                            event.accepted = true;
                        }
                        Keys.onUpPressed: {
                            launcher.selected = Math.max(launcher.selected - 1, 0);
                            event.accepted = true;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: launcher.colSep
            }

            // Results list
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: launcher.visibleApps
                currentIndex: launcher.selected
                keyNavigationWraps: true
                clip: true

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: list.width
                    height: 44
                    color: index === launcher.selected ? gruv.colTile : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        IconImage {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: appIcons.iconFor(modelData.icon)
                            smooth: true
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData.name
                            color: gruv.colFg
                            font.pixelSize: 13
                        }

                        Text {
                            text: modelData.genericName
                            elide: Text.ElideRight
                            color: gruv.colMuted
                            font.pixelSize: 11
                            Layout.preferredWidth: Math.min(implicitWidth, 160)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: launcher.selected = index
                        onClicked: launcher.launch(index)
                    }
                }
            }
        }
    }
}