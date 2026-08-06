import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────────────────────
//  One notification row — used by the floating popup and the
//  control center. swaync styling: Gruvbox, green normal border,
//  red critical border, green action buttons, round corners.
//  In popup mode: auto-dismiss (low 4 s / normal 6 s / critical
//  never), paused while hovered.
// ─────────────────────────────────────────────────────────────

Rectangle {
    id: toast

    required property var notif          // {n, time}
    required property var onDismiss      // function(id)
    required property var icons          // AppIcons instance
    property bool popupMode: false
    property int iconSize: 48

    readonly property var n: notif.n
    readonly property bool critical: n.urgency >= NotificationUrgency.Critical
    property bool hovered: false

    // Explicit size — toasts live in a ListView (center) or a plain
    // Column (popup), neither of which honors Layout.* attached props.
    height: popupMode ? Math.max(iconSize + 22, textCol.implicitHeight + 18) : 74

    radius: 8
    color: "#282828"
    border.width: 1
    border.color: critical ? "#cc241d" : "#8ec07c"

    // ── Auto-dismiss (popup mode only) ───────────────────────
    Timer {
        id: autoTimer
        running: toast.popupMode && !toast.hovered && !toast.critical
        interval: toast.n.urgency >= NotificationUrgency.Normal ? 6000 : 4000
        onTriggered: {
            toast.onDismiss(toast.n.id);
        }
    }

    // ── Click-on-body dismiss (popups) — FIRST child so action
    // buttons and the close button (later children) stay clickable.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: toast.hovered = true
        onExited: toast.hovered = false
        onClicked: { if (toast.popupMode) toast.onDismiss(toast.n.id); }
    }

    // ── Body ─────────────────────────────────────────────────
    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 9
        spacing: 10
        clip: true

        // App icon (or letter fallback)
        Rectangle {
            Layout.preferredWidth: toast.iconSize
            Layout.preferredHeight: toast.iconSize
            Layout.alignment: Qt.AlignTop
            radius: 8
            color: "#504945"

            IconImage {
                anchors.centerIn: parent
                width: toast.iconSize - 12
                height: toast.iconSize - 12
                source: toast.icons.iconFor(toast.n.appIcon)
                visible: source !== ""
            }
            Text {
                anchors.centerIn: parent
                text: toast.icons.letterFor(toast.n.appName)
                color: "#ebdbb2"
                font.pixelSize: 14
                font.bold: true
                visible: toast.icons.iconFor(toast.n.appIcon) === ""
            }
        }

        // Text column
        ColumnLayout {
            id: textCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: toast.n.appName || "Unknown"
                    color: "#a89984"
                    font.pixelSize: 9
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    text: Qt.formatTime(new Date(toast.notif.time), "hh:mm")
                    color: "#a89984"
                    font.pixelSize: 9
                }
            }

            Text {
                Layout.fillWidth: true
                text: toast.n.summary || ""
                color: "#ebdbb2"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: toast.n.body || ""
                color: "#ebdbb2"
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: toast.popupMode ? 3 : 1
                visible: text !== ""
            }

            // Action buttons
            Row {
                Layout.topMargin: 4
                spacing: 6
                visible: toast.n.actions && toast.n.actions.length > 0

                Repeater {
                    model: toast.n.actions

                    Rectangle {
                        required property var modelData

                        height: 22
                        width: actLabel.implicitWidth + 18
                        radius: 6
                        color: "#504945"

                        Text {
                            id: actLabel
                            anchors.centerIn: parent
                            text: modelData.text || ""
                            color: "#ebdbb2"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (typeof modelData.invoke === "function") modelData.invoke();
                                toast.onDismiss(toast.n.id);
                            }
                        }
                    }
                }
            }
        }

        // Close button
        Rectangle {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignTop
            radius: 9
            color: "#00000000"

            Text {
                anchors.centerIn: parent
                text: "\uF156"              // mdi-close
                color: "#a89984"
                font.family: "Material Design Icons"
                font.pixelSize: 10
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: toast.onDismiss(toast.n.id)
            }
        }
    }
}
