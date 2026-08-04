import QtQuick

// ─────────────────────────────────────────────────────────────
//  Gruvbox palette + fonts, shared by every quickshell piece.
//  Auto-imported as a component type (uppercase file name).
// ─────────────────────────────────────────────────────────────

QtObject {
    readonly property color colBar:    "#282828"   // bar background
    readonly property color colTile:   "#504945"   // module tiles / focused
    readonly property color colFg:     "#ebdbb2"   // text
    readonly property color colMuted:  "#a89984"   // dimmed text
    readonly property color colRed:    "#cc241d"   // NET ↓ · urgent · clock
    readonly property color colGreen:  "#8ec07c"   // NET ↑ · hover
    readonly property color colYellow: "#d79921"   // memory
    readonly property color colOrange: "#d65d0e"   // cpu
    readonly property color colAqua:   "#458588"   // date · launcher
    readonly property color colPurple: "#b16286"   // keyboard layout
    readonly property color colFgDark: "#1d2021"   // text on light tiles

    readonly property string iconFont: "Material Design Icons"
}
