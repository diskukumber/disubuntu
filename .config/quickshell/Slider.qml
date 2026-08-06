import QtQuick

// ─────────────────────────────────────────────────────────────
//  Minimal custom slider (QtQuick.Controls is not installed).
//  Track + fill + knob, click-to-jump and drag. Gruvbox styled.
//  API mirrors the Controls slider: from/to/value/pressed.
// ─────────────────────────────────────────────────────────────

Item {
    id: slider

    property real from: 0
    property real to: 100
    property real value: from
    property bool pressed: false

    implicitWidth: 200
    implicitHeight: 18

    readonly property real frac: Math.min(1, Math.max(0, (value - from) / (to - from)))

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: "#3c3836"
    }

    Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: "#8ec07c"
        width: track.width * slider.frac
    }

    Rectangle {
        x: track.x + track.width * slider.frac - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: slider.pressed ? "#8ec07c" : "#ebdbb2"

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MouseArea {
        anchors.fill: parent

        function setFromMouse(mouse) {
            const f = Math.min(1, Math.max(0, mouse.x / slider.width));
            slider.value = slider.from + f * (slider.to - slider.from);
        }

        onPressed: mouse => {
            slider.pressed = true;
            setFromMouse(mouse);
        }
        onPositionChanged: mouse => { if (slider.pressed) setFromMouse(mouse); }
        onReleased: slider.pressed = false;
    }
}
