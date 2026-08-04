# disubuntu

Dotfiles for my Ubuntu setup running the **niri** Wayland compositor with a
**quickshell** bar.

## Layout

```
.config/
  niri/config.kdl      # single-file niri config (keybinds mirroring old Hyprland setup)
  quickshell/          # bar, taskbar, launcher, shell (QML)
.local/bin/
  wp-restore           # pipewire sink restore helper (called from niri startup)
home/
  .bash_aliases        # apt->nala aliases + misc
```

The `.config/{niri,quickshell}` paths in `~` are symlinks into this repo, so
editing live configs stays in sync with git.

## Install (fresh machine)

- niri, quickshell, ghostty, fuzzel, brightnessctl, playerctl
- `ln -s $HOME/dotfiles/.config/niri $HOME/.config/niri`
- `ln -s $HOME/dotfiles/.config/quickshell $HOME/.config/quickshell`
- `cp $HOME/dotfiles/.local/bin/wp-restore $HOME/.local/bin/`
- `cp $HOME/dotfiles/home/.bash_aliases $HOME/.bash_aliases`

## Notes

- Keybinds are ported from the old Hyprland config; see comments inside
  `config.kdl` for the app bindings that still need their binaries
  (gtklock, kando, spotify, nemo, thunderbird, copyq, ...).