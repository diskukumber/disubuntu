# Active Accent Frame — window decoration (Aurorae)

**Active Accent Frame v9.0** — Breeze-based Aurorae window decoration without
titlebar. Frames the active window in the color scheme's accent color
(`ColorScheme-ViewFocus`) and inactive windows in the scheme's background
color (`ColorScheme-Background`) — so with Plasma's adaptive colors enabled,
the active-window frame follows the wallpaper accent natively.

- Upstream: <https://github.com/nclarius/Plasma-window-decorations>
- KDE Store: <https://store.kde.org/p/1678088>
- Pinned commit: `02058699173f5651816d4cb31960d08b45553255` (branch `main`)
- License: GPL-3.0 (see `LICENSE`)

## Local modification

`ActiveAccentFramerc` — borders trimmed to 2px all around (upstream: 4/4/5/5)
for the thin-frame look. `Shadow=true`, `TitleHeight=0`, `ButtonHeight=0`
unchanged.

## Install

```bash
mkdir -p ~/.local/share/aurorae/themes
cp -r ActiveAccentFrame ~/.local/share/aurorae/themes/
# then set in kwinrc:
#   [org.kde.kdecoration2]
#   theme=ActiveAccentFrame
#   BorderSize=Normal
```

Requirement (from upstream): window borders must be enabled with a normal
value — `BorderSize=NoBorder` hides the frame entirely.
Known limit: maximized windows show no frame (Aurorae limitation, bug 451505).
