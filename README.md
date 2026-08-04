# 🐧 disubuntu · Ubuntu interim

An Ubuntu interim-based setup, lean by design, refreshed on the interim release cadence.

> [!NOTE]
> 🚧 **Still under development** — this documentation is updated as the setup develops.

---

## 📑 Table of Contents

| Section | Covers |
|---|---|
| [📸 Screenshots](#-screenshots) | how screenshots are taken & where they land |
| [📥 Installation](#-installation) | categorized install commands, repos, one-shot install, rebuild checklist |
| [🖥️ Hardware](#-hardware) | the machine: CPU, RAM, storage, dual-GPU hybrid graphics |
| [🧩 Software stack & package inventory](#-software-stack--package-inventory) | the diagram, who does what, every package, process count |
| [🚀 Session Startup](#-session-startup) | greetd → niri → quickshell boot chain |
| [🎛️ niri Configuration](#-niri-configuration) | config.kdl explained section by section |
| [🧱 The Quickshell Bar](#-the-quickshell-bar) | the hand-written bar: files, IPC, patterns, launcher |
| [⌨️ Key Bindings](#-key-bindings) | the full cheat sheet |
| [🎮 NVIDIA](#-nvidia) | driver, modeset, VRAM fix, groups, diagnostics |
| [🚧 Work In Progress](#-work-in-progress) | done & open tasks, incl. the fixed-release (6-month) plan |
| [📦 Packages & Details](#-packages--details) | the one-glance component table |
| [🛠️ Troubleshooting & Known Issues](#-troubleshooting--known-issues) | symptom→fix table, logs, recovery recipes |
| [🧹 Maintenance & Service Inventory](#-maintenance--service-inventory) | cleanup, services, dotfiles, routine care |
| [📜 Provisioning & Baseline](#-provisioning--baseline) | fresh-install baseline, install/reset commands |
| [ℹ️ Quick facts](#-quick-facts) | TL;DR summary |

---

## 📸 Screenshots

Screenshots land in `~/Pictures/Screenshots/` and are added here as you go:

| Keys | What it captures |
|---|---|
| `Print` | area (drag to select) |
| `Ctrl+Print` | entire screen |
| `Alt+Print` | focused window |

```
docs/system/screenshots/<name>.png
```

---

## 📥 Installation

<details>
<summary><h3>📥 INSTALLATION — Ubuntu interim</h3></summary>

> [!TIP]
> Start from a fresh [Ubuntu Server](https://ubuntu.com/server) **minimal**
> install and boot once to make sure the base system is healthy. The whole
> state is reproducible — every command is in this document (see
> [📜 Provisioning & Baseline](#-provisioning--baseline)).

### 🗔 niri And The Bar
```sh
sudo apt install -y niri quickshell \
  qml6-module-qtquick-layouts \
  ghostty fuzzel wl-clipboard
```

### 🧰 Dependencies
```sh
sudo apt install -y greetd xdg-desktop-portal polkitd \
  brightnessctl
```

### 🌐 Bluetooth And Network
```sh
sudo apt install -y network-manager wpa_supplicant bluez
```

### 🌍 Browser (real .deb — no snap)
```sh
curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/helium.list
sudo apt update && sudo apt install -y helium-bin
```

### 🔤 Fonts
```sh
sudo apt install -y fonts-inter fonts-jetbrains-mono \
  fonts-noto-core fonts-noto-color-emoji
```

### 🎮 NVIDIA drivers
```sh
sudo apt install -y nvidia-driver-595
```

> [!IMPORTANT]
> After the driver: add `nvidia-drm.modeset=1` to the kernel cmdline, apply
> the VRAM heap fix profile, add the user to `video,render`, and
> `sudo update-grub` — full steps in the [🎮 NVIDIA section](#-nvidia).

### 📚 Repositories

| Source | Status | Provides |
|---|---|---|
| Ubuntu main/universe | preconfigured | base system, niri, ghostty, fuzzel, fonts, tools |
| Ubuntu restricted | preconfigured | NVIDIA 595 |
| `ppa:avengemedia/danklinux` | preconfigured | quickshell (official Ubuntu packaging) |
| `pkg.helium.computer/deb` (keyring `helium.gpg`) | commands in [📜 Provisioning](#-provisioning--baseline) | `helium-bin` browser (real .deb — no snap) |

### ⚡ The one-shot install

```bash
# 1. Refresh package lists
sudo apt update

# 2. Install the stack
sudo apt install -y \
    quickshell ghostty \
    nvidia-driver-595 \
    wl-clipboard brightnessctl \
    qml6-module-qtquick-layouts \
    fonts-inter fonts-jetbrains-mono fonts-noto-core fonts-noto-color-emoji
```

### ✅ Already present from the Ubuntu base install

- **niri** + systemd units (`niri.service`) + session file
- **greetd** (login manager, configured but currently **disabled** — see [🚀 Session Startup](#-session-startup))
- **fuzzel** and **alacritty** (fallback tools)
- **xdg-desktop-portal**, **polkit**, **accountsservice**
- **waybar** is spawned by the *stock* niri config only — our config doesn't start it

### 📄 Config files (all ours, no third-party configs)

| File | What it is |
|---|---|
| `~/.config/niri/config.kdl` | compositor (rewritten, commented) |
| `~/.config/quickshell/shell.qml` | shell entry point |
| `~/.config/quickshell/Bar.qml` | top bar (workspaces · stats · tray) |
| `~/.config/quickshell/Taskbar.qml` | bottom bar (launcher · window taskbar) |
| `~/.config/quickshell/Launcher.qml` | app launcher popup |
| `~/.config/ghostty/config` | terminal |

### 📝 Rebuilding from scratch checklist

- [ ] `sudo apt install -y quickshell ghostty nvidia-driver-595 wl-clipboard brightnessctl qml6-module-qtquick-layouts fonts-inter fonts-jetbrains-mono fonts-noto-core fonts-noto-color-emoji`
- [ ] `nvidia-drm.modeset=1` kernel cmdline (see [🎮 NVIDIA](#-nvidia))
- [ ] NVIDIA VRAM fix JSON (see [🎮 NVIDIA](#-nvidia))
- [ ] `sudo usermod -aG video,render $USER`
- [ ] `sudo systemctl enable --now greetd` (auto-login; else start `niri-session` from a TTY)
- [ ] `sudo update-grub`
- [ ] Reboot → log in on tty1 (greetd handles it)
</details>

---

## 🖥️ Hardware

A **hybrid-graphics laptop** — TWO GPUs, and the desktop can use either one.

### 📋 System overview

| Component | Details |
|---|---|
| Machine | GWTN156-3BK (laptop, manufacturer: GPU Company) |
| CPU | Intel Core i5-10300H @ 2.50 GHz (4 cores / 8 threads, boost to 4.5 GHz) |
| RAM | 14 GiB |
| Storage | 500 GB NVMe (`nvme0n1`) + 238 GB NVMe (`nvme1n1`) |
| Kernel | Linux 7.0.0-28-generic |

### 🎛️ The two GPUs

```
00:02.0 VGA compatible controller: Intel Corporation CometLake-H GT2 [UHD Graphics]
01:00.0 VGA compatible controller: NVIDIA Corporation TU106M [GeForce RTX 2060 Mobile]
```

| GPU | Device | Role |
|---|---|---|
| 🟦 **Intel UHD Graphics (iGPU)** | `/dev/dri/card0` | integrated, low power, no proprietary driver; the eDP panel is physically wired to it, so it *always* does the display output |
| 🟩 **NVIDIA RTX 2060 Mobile (dGPU)** | `/dev/dri/card1` | 6 GB VRAM, more powerful; with `nvidia-drm.modeset=1` it renders the whole desktop (niri renders through it, Intel just scans out) |

### 🔀 How the graphics stack is wired (PRIME / hybrid)

```
Applications (Ghostty, quickshell, etc.)
        │  Vulkan/OpenGL/EGL
        ▼
   niri (compositor) ── renders with the NVIDIA GPU (via GBM/EGL)
        │
        ▼
   Intel iGPU ── scans out to the laptop screen (eDP)
```

Why "render with NVIDIA, display with Intel"? Intel alone is perfectly usable
and lightest, but the RTX 2060 gives much better performance for games and GPU
workloads. The NVIDIA driver has a known VRAM quirk affecting compositors — see
the [🎮 NVIDIA](#-nvidia) section for the fix that's already applied.

### 🛠️ Hardware commands

```bash
lspci | grep -iE "vga|3d"          # list GPUs
nvidia-smi                         # NVIDIA GPU status, VRAM, processes
ls /dev/dri/                       # render devices (card0=Intel, card1=NVIDIA)
cat /sys/class/drm/card1/device/... # raw GPU info if needed
```

---

## 🧩 Software stack & package inventory

What runs, what each piece does, and every installed package by category.
(Full `dpkg` list: **1089 packages**; manually installed: **61** — snapshot 2026-08-04.)

### 🗺️ The whole setup, one diagram

```
┌───────────────────────────────────────────────────────────────┐
│  DESKTOP (user-visible)                                       │
│                                                               │
│  ┌─────────────────────────┐  ┌────────────┐  ┌────────────┐  │
│  │  quickshell (1 process) │  │  fuzzel    │  │  Ghostty   │  │
│  │  ┌───────────────────┐  │  │  launcher  │  │  terminal  │  │
│  │  │ top bar:          │  │  │  (Mod+D)   │  │  (Mod+T)   │  │
│  │  │ workspaces ·      │  │  └────────────┘  └────────────┘  │
│  │  │ net/mem/cpu · kbd │  │                                 │
│  │  │ date · clock ·    │  │                                 │
│  │  │ tray              │  │                                 │
│  │  ├───────────────────┤  │                                 │
│  │  │ bottom bar:       │  │                                 │
│  │  │ launcher ·        │  │                                 │
│  │  │ window taskbar    │  │                                 │
│  │  └───────────────────┘  │                                 │
│  └─────────────────────────┘                                 │
│                                                               │
│  niri ── compositor: windows, workspaces, keybinds,           │
│          notifications (built-in), screenshots (built-in)     │
├───────────────────────────────────────────────────────────────┤
│  SYSTEM SERVICES                                              │
│  greetd (login) → niri session · quickshell spawned by niri  │
│  NOTE: greetd is currently DISABLED (started manually)        │
│  (audio: removed 2026-08-04 — see Package inventory)          │
├───────────────────────────────────────────────────────────────┤
│  GRAPHICS                                                     │
│  nvidia-driver-595 (dGPU render) + Intel iGPU (scanout)       │
│  Mesa (fallback GL) + Vulkan drivers                          │
└───────────────────────────────────────────────────────────────┘
```

### 👤 Who does what

| Job | Handled by | Why this choice |
|---|---|---|
| Window management | **niri** | scrollable tiling, pure Wayland, tiny |
| Notifications | **niri (built-in)** | popups rendered by the compositor — zero extra daemons |
| Screenshots | **niri (built-in)** | `Print` / `Ctrl+Print` / `Alt+Print` — no grim/slurp needed |
| Status bar | **quickshell + our `shell.qml`** | one process, one config, hand-written (~150 lines) |
| App launcher | **quickshell (`Launcher.qml`)** | popup under the bar, Mod+R; fuzzel kept as fallback (Mod+D) |
| Browser | **Helium** (`helium-bin`, .deb repo) | Chromium fork with Chrome-extension support; real .deb, no snap |
| Terminal | **Ghostty** | native Wayland, GPU-accelerated |
| Clipboard | **wl-clipboard** (`wl-copy`/`wl-paste`) | the Wayland standard |
| Backlight keys | **brightnessctl** | works on Intel panels |
| Audio | **none (removed)** | purged with the GNOME cleanup; restore via `sudo apt install pipewire pipewire-pulse wireplumber` — volume keys use `wpctl` |
| Login | **greetd** | headless login manager, no GNOME bloat (installed; currently **disabled** — see [🚀 Session Startup](#-session-startup)) |
| Desktop GPU | **nvidia-driver-595** | see [🎮 NVIDIA](#-nvidia) |

### 🚫 What is intentionally NOT here

- No X11 apps, no full X server (rootless `xwayland-satellite` 0.8.2 IS installed to run rare X11 apps)
- No desktop environment, no display manager with GUI
- No DMS/Noctalia/iNiR or any third-party shell config
- No waybar, mako, swaybg, swaylock, grim, slurp (niri + our bar replace them)
- No gammastep/nightlight, no polkit agent (keep it lean) — the tray lives in the top bar instead of a standalone daemon

### 📦 Package inventory (the part that matters)

**Core desktop stack (hand-picked)**

| Package | Version | Purpose |
|---|---|---|
| `niri` | — | the Wayland compositor |
| `quickshell` | — | QML runtime that renders our bar (from the `danklinux` PPA) |
| `ghostty` | — | terminal emulator |
| `fuzzel` | (universe) | application launcher |
| `wl-clipboard` | (universe) | `wl-copy` / `wl-paste` clipboard tools |
| `brightnessctl` | (universe) | screen brightness control |
| `qml6-module-qtquick-layouts` | (universe) | QML `RowLayout` module used by the bar |

**Fonts (needed by the bar, terminal, and apps)**

| Package | Purpose |
|---|---|
| `fonts-inter` | the bar's UI font (Inter) |
| `fonts-jetbrains-mono` | terminal monospace font |
| `fonts-noto-core` | fallback glyph coverage for most scripts |
| `fonts-noto-color-emoji` | emoji rendering in apps |

**Graphics: NVIDIA (desktop driver)**

| Package | Purpose |
|---|---|
| `nvidia-driver-595` | metapackage: full desktop stack |
| `libnvidia-gl-595` | GL/EGL rendering libraries (the dGPU's display stack) |
| `nvidia-utils-595` | `nvidia-smi`, tools |
| `nvidia-dkms-595` (or precompiled modules) | kernel modules (`nvidia`, `nvidia_drm`, …) |
| `nvidia-firmware-595` | GSP firmware for Turing (RTX 2060) |

**Graphics: Mesa / Intel (system defaults)**

| Package | Purpose |
|---|---|
| `mesa-libgallium` + `libgl1-mesa-dri` | open-source GL drivers (Intel + software) |
| `libegl-mesa0`, `libglx-mesa0` | EGL/GLX implementations |
| `libgbm1` | GBM buffer allocation (used by compositors) |
| `libdrm-intel1` | Intel kernel DRM userspace |
| `mesa-vulkan-drivers`, `libvulkan1` | Vulkan support |

**Audio (came with the Ubuntu server image; PURGED 2026-08-04 — reinstall to restore sound)**

| Package | Purpose |
|---|---|
| `pipewire`, `pipewire-bin` | audio server |
| `pipewire-audio`, `pipewire-pulse`, `pipewire-alsa` | audio + PulseAudio/ALSA compatibility |
| `wireplumber` | session manager (device routing, volumes) |
| `bluez` (+`libspa-0.2-bluetooth`) | Bluetooth audio support (also not currently installed) |

**Session & login**

| Package | Purpose |
|---|---|
| `greetd` | login manager (text greeter: `agreety`) |
| `xdg-desktop-portal` (+gnome/gtk backends) | screen sharing, file dialogs for sandboxed apps |
| `polkitd`, `pkexec` | privilege authorization for apps |
| `accountsservice` | user account info (avatar etc.) |

**Session tools the shell uses**

| Tool | Used for |
|---|---|
| `niri msg` | the bar reads workspaces + sends focus actions (see [🧱 The Quickshell Bar](#-the-quickshell-bar)) |
| `wpctl` | volume keys (in niri config binds) |
| `brightnessctl` | brightness keys (in niri config binds) |
| `fuzzel` | Mod+D (fallback launcher) |

### 🔢 Process count at idle

```
niri:                     1 process  (the compositor)
quickshell:               1 process  (the whole UI)
terminal:                 0 at idle
pipewire + wireplumber:   2-3 processes (only after audio is restored)
```

That's the whole desktop: **~2 processes** on top of systemd right now (audioless);
~5 once pipewire + wireplumber are back.

---

## 🚀 Session Startup

How this machine boots into the desktop. No GUI display manager — just `greetd`,
a headless login manager, and the compositor.

> [!NOTE]
> **Current state (2026-08-04):** `greetd` is installed and configured but is
> currently **disabled** (`systemctl is-enabled greetd` → `disabled`). The
> running desktop session was started from a shell (`/usr/bin/niri-session -l`).
> The flow below is the configured/auto-login path; to make it automatic:
> `sudo systemctl enable --now greetd`.

### 🥾 Boot order

```
1. Ubuntu boots; greetd takes over tty1
2. greetd runs `agreety` — a text login prompt (username + password)
3. After login, greetd runs:  niri-session
4. niri-session:
     - imports the login environment into the systemd user session
     - refreshes the D-Bus activation environment
     - starts niri.service (the compositor, with `--session`)
5. niri reads ~/.config/niri/config.kdl and spawns quickshell
6. quickshell renders the bars (top: workspaces · stats · tray; bottom: launcher · taskbar)
7. Desktop is up:  ~2 processes total (audioless; ~5 with audio)
```

### 🗂️ Where the pieces live

| Piece | File |
|---|---|
| greetd config | `/etc/greetd/config.toml` |
| greetd service | `greetd.service` (system) |
| niri systemd unit | `/usr/lib/systemd/user/niri.service` |
| niri session script | `/usr/bin/niri-session` |
| compositor config | `~/.config/niri/config.kdl` |
| shell config | `~/.config/quickshell/shell.qml` |

### 🤔 Why greetd instead of GDM/SDDM?

- **Server install** = no display manager. GDM would pull in GNOME dependencies.
- `greetd` is one small daemon + a text greeter. It runs `niri-session` for you
  and handles seat/permissions correctly.
- Same UX as a TTY login, but tidier (auto session start).

### ⚙️ The greetd config (already set up)

`/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "agreety --cmd niri-session"
user = "greeter"
```

| Setting | Meaning |
|---|---|
| `vt = 1` | greeter on tty1 |
| `agreety --cmd niri-session` | after login, run niri |
| `user = "greeter"` | greeter runs as unprivileged `greeter`; your session runs as *you* |

**To enable greetd (it is currently disabled):**

```bash
sudo systemctl enable --now greetd   # auto-login: boot → greetd → niri → quickshell
```

> [!TIP]
> If greetd shows "start-limit-hit" in `systemctl status greetd`, it was
> restarted too quickly (e.g. a session exited right after boot). It resets on
> reboot; if it persists, check `journalctl -u greetd`.

### 🧱 How the shell starts

niri's config contains `spawn-at-startup "quickshell"` — the compositor starts
the bar as its child, so quickshell automatically gets `WAYLAND_DISPLAY`. (No
systemd unit needed for it — that would require extra environment plumbing for
no benefit.)

### 🛠️ Useful commands

```bash
systemctl status greetd              # login manager status
journalctl -u greetd                 # login manager logs
systemctl --user status niri         # compositor status
journalctl --user -u niri -f         # compositor logs (live)
niri msg -j workspaces               # verify IPC (bar data source)
pgrep -a quickshell                  # shell should be running
```

---

## 🎛️ niri Configuration

`~/.config/niri/config.kdl` — the compositor. **Format**: KDL, `//` starts a
comment. Wiki: <https://niri-wm.github.io/niri/>.

### 🗺️ Section map

| Lines | Section | What it does |
|---|---|---|
| 7-14 | `environment` | environment variables for all Wayland apps |
| 16-34 | `input` | keyboard + touchpad settings |
| 36-63 | `layout` | gaps, background, focus ring, shadows |
| 65-68 | startup | spawns quickshell (the bar) |
| 70-81 | misc | CSD handling, screenshots, animations |
| 83-114 | window/layer rules | corner radius, opacity, quickshell behavior |
| 116-257 | `binds` | all keybindings |

### 🌍 `environment` — what apps see

```kdl
environment {
    XDG_CURRENT_DESKTOP "niri"          // apps know the desktop name
    QT_QPA_PLATFORM "wayland"           // Qt apps: native Wayland (no X11)
    QT_QPA_PLATFORMTHEME "gtk3"         // Qt apps follow the GTK theme
    QT_QPA_PLATFORMTHEME_QT6 "gtk3"
    ELECTRON_OZONE_PLATFORM_HINT "auto" // Electron apps: use Wayland
}
```

> [!NOTE]
> Without these, Qt/Electron apps fall back to X11 (which we don't run) or look
> out of place.

### ⌨️ `input`

```kdl
keyboard { xkb {} numlock }   // layout from systemd-localed; NumLock on
touchpad { tap; natural-scroll }   // tap-to-click, macOS-style scrolling
mouse   { }                   // defaults
```

Change keyboard layout with: `localectl set-x11-keymap us` (or `de`, `fr`, …).

### 🖼️ `layout` — how windows look

```kdl
gaps 8                     // spacing between windows (logical px)
background-color "#111111" // dark background (no wallpaper in this setup)
focus-ring { width 2 ... } // thin ring around the focused window
border { off }             // no permanent borders
shadow  { on ... }         // soft drop shadows
default-column-width { proportion 0.5; } // new windows take half the screen
```

> [!TIP]
> Want a wallpaper later? Set `background-color "transparent"` and run a
> wallpaper layer (e.g. a quickshell layer in the background). Not needed now.

### 🚀 Startup

```kdl
spawn-at-startup "quickshell"
```

The only autostart. Everything else is keybound.

### ⚙️ Misc

```kdl
prefer-no-csd    // ask apps to drop their own titlebars (cleaner tiling)
screenshot-path  // Print-key screenshots land in ~/Pictures/Screenshots/
```

### 🪟 Window rules

| Rule | Effect |
|---|---|
| ghostty / alacritty: `draw-border-with-background false` | no focus-ring rectangle behind terminal transparency |
| all windows: `geometry-corner-radius 12`, `clip-to-geometry` | rounded corners |
| inactive windows: `opacity 0.9` | subtle dimming of the unfocused window |
| `app-id ~ org.quickshell`: `open-floating true` | quickshell popups float |

### 📐 Layer rules

```kdl
layer-rule { match namespace="^quickshell$" place-within-backdrop true }
```

Puts quickshell's layers on the workspace backdrop so they're visible in the
Overview (`Mod+O`).

### 🔄 Checking and reloading

```bash
niri msg action load-config-file   # apply config without restarting
niri msg -j workspaces          # verify IPC (the bar reads this)
niri msg version                # compositor version
```

> [!TIP]
> Reload is **instant and safe** — that's how you iterate on this file.

---

## 🧱 The Quickshell Bar

The entire UI is a hand-written quickshell config (~900 lines). No third-party
shells, no plugins — just quickshell core + niri's IPC. The look is a port of
the user's waybar config (`diskukumber/disnixos` · `.config/waybar`), including
its Gruvbox palette and per-module colors.

### 📄 Files

| File | What it is |
|---|---|
| `~/.config/quickshell/shell.qml` | entry point (starts the bars) |
| `~/.config/quickshell/Bar.qml` | **top bar** — workspaces + stats + tray |
| `~/.config/quickshell/Taskbar.qml` | **bottom bar** — app launcher + window taskbar (icons only) |
| `~/.config/quickshell/Launcher.qml` | app launcher popup (Mod+R) |
| `~/.config/quickshell/Gruvbox.qml` | shared palette + icon font name (auto-imported component) |
| `~/.config/quickshell/AppIcons.qml` | shared icon resolver: app id → icon file path (auto-imported) |

> [!NOTE]
> Quickshell loads `shell.qml` automatically when started. Files in the same
> folder starting with an uppercase letter (like `Bar.qml`) become importable
> components.

### 👀 What the bar shows

- **Top bar** (`Bar.qml`, 26 px, docked at the top edge):

```
┌───────────────────────────────────────────────────────────────────────┐
│ [1][2][3]        ⇣1.2M ⇡340K   MEM 34%   CPU 12%   US   Mon Aug 3  14:37 ● │
└───────────────────────────────────────────────────────────────────────┘
  workspace     NET ↓/↑ (1s)   memory (5s)   cpu (1s)   layout   date   clock
  pills (left)  (icons: MDI font)            stats cluster (right) + tray
```

- **Workspace pills** — **dynamic**: only workspaces holding windows plus
  the active one appear, numbered with plain digits (name appended if set).
  Active = dark pill, urgent = red, idle = teal, hover = green. Click to
  switch.
- **Stats cluster** (waybar right modules, Material Design Icons glyphs
  from the `fonts-materialdesignicons-webfont` apt package): NET
  `↓` red / `↑` green (1 s), MEM yellow, CPU orange, keyboard layout purple
  (5 s), date teal, clock with red icon (1 s).
- **System tray** (status notifier items): left-click activate, middle
  secondary, right-click menu, scroll to scroll. Auto-hides when empty.

**Bottom bar** (`Taskbar.qml`, 44 px, docked at the bottom edge):

```
┌───────────────────────────────────────────────────────────────────────┐
│ ▦   [app icon][app icon][app icon]          (icons only, 46px buttons)│
└───────────────────────────────────────────────────────────────────────┘
 launcher (grid)     window taskbar — ICONS ONLY; letter fallback when
                      an app has no icon; focus/hover = green underline
```

- Both bars are full-width and the **off-screen side sweeps in one big
  curve** (radius = full bar height, drawn with `Canvas`) until it just
  touches the screen edge at the corner points.

### 🔌 How it talks to niri

No special plugin — it communicates with niri over its IPC and reads `/proc`
for stats, all through `Quickshell.Io.Process`:

```
top bar    read:  niri msg -j workspaces        → JSON → workspace pills
                  niri msg -j keyboard-layouts   → JSON → layout short name
                  /proc/stat  + /proc/meminfo    → CPU % · MEM %
                  /proc/net/dev                  → NET ↓/↑ bandwidth
        write:  niri msg action focus-workspace <id>   (on pill click)
bottom bar read:  niri msg -j windows            → JSON → taskbar buttons
        write:  niri msg action focus-window --id <id>   (left-click)
               niri msg action close-window --id <id>    (middle/right)
```

- The read loops: `Process` with `stdout: SplitParser` (fires per output
  line). `onRunningChanged: if (!running) running = true` makes each **re-run
  immediately** after completion — a lightweight polling loop, one spawn per
  timer tick (workspaces/windows 1 s, net/cpu 1 s, mem/kbd 5 s).
- Actions are fire-and-forget: set `command`, flip `running` on.

> [!TIP]
> **Why poll instead of `niri msg event-stream`?** Simpler and more robust: no
> long-lived connection to manage, no JSON-event parsing, nothing to reconnect
> after niri restarts. One `niri msg` per second costs nothing.

### 📊 The data (what `niri msg -j workspaces` returns)

```json
[
  {
    "id": 1,
    "name": "",
    "output": "eDP-1",
    "windows": [ { "app-id": "com.mitchellh.ghostty", "title": "...", "is-focused": true, ... } ],
    "is-active": true,
    "is-urgent": false
  },
  ...
]
```

The top bar maps: `id` → pill id, `name` (or id) → pill label, `is-active` →
highlight, `is-urgent` → red. The bottom bar maps each window's `id` →
button, `title` → button text, and `is_focused` → the highlighted/pinned one.

### 🛠️ Changing things

| You want to… | Edit in `Bar.qml` or `Taskbar.qml` |
|---|---|
| re-theme | the `col*` properties at the top of each file (`colBar`, `colFg`, `colTile`, …) |
| different bar height | `implicitHeight` and `exclusiveZone` (keep them equal) — the corner curve radius follows the height automatically |
| add a module (battery, volume, …) | add a `Text`/`Process` + a `Timer`; see the clock pattern below |
| show workspace names instead of numbers | set `label: ws.name` in `parseWorkspaces()` |
| no workspace switching on click | delete the `MouseArea` in the pill |
| live-test changes | save the file — quickshell hot-reloads instantly |

### 🧩 Pattern cheatsheet (for adding modules)

Clock (timer-driven text):

```qml
Text { text: root.clockText }
Timer { interval: 1000; running: true; repeat: true
        onTriggered: root.clockText = Qt.formatTime(new Date(), "HH:mm") }
```

Polled value (process-driven):

```qml
Process { id: p; command: [...]; stdout: SplitParser { onRead: d => { if (d) root.myValue = d.trim() } } }
Timer { interval: 2000; running: true; repeat: true; onTriggered: p.running = true }
```

### 🔍 The app launcher

`Launcher.qml` is a `PopupWindow` anchored below the bar. niri binds `Mod+R`
to `spawn-sh "echo toggle >> /tmp/qs-launcher-toggle"`; the launcher watches
that file with `Process { command: ["tail", "-n", "0", "-F", ...] }` and a
`SplitParser`, toggling the popup on every new line. No daemons.

- **Apps**: `DesktopEntries.applications` (.desktop files). It loads
  *asynchronously* — wait for `applicationsChanged`, then copy `.values`
  (it has no `.count`/`.get`).
- **Icons**: Qt doesn't resolve theme icon names, so a `find` process over
  `/usr/share/icons/hicolor` + `/usr/share/pixmaps` + `Adwaita` builds a
  name→`file://` path map.
- **Search**: the input filters `visibleApps`; Enter launches (`app.execute()`),
  Esc closes, ↑/↓ navigate, click works too.
- **Positioning**: `PopupWindow` has no `anchors` — set
  `launcher.anchor.window = barWindow` and `anchor.rect.x/y` manually.
- **`grabFocus`**: leave it `false`; `true` fails with "Failed to create
  grabbing popup" on this build.

### 💡 Why this design

- **One process** for the whole UI (~15 MB RSS).
- **No third-party anything**: no shell configs, no plugins, no notification
  daemons — the compositor does notifications and screenshots.
- Everything here is plain QML + one documented command line (`niri msg`), so
  you can read, modify, and trust every line.

### 🔄 Reloading

Save any file — quickshell reloads automatically. If the bar disappears:

```bash
pgrep -a quickshell
# if missing, restart the session (Mod+Shift+E quits niri, greetd gives you a fresh one)
```

---

## ⌨️ Key Bindings

`Mod` = **Super/Windows** key. Every bind lives in `binds { }` in
`~/.config/niri/config.kdl`.

### 🚀 Apps

| Keys | Action |
|---|---|
| `Mod+T` | open Ghostty (terminal) |
| `Mod+D` | open fuzzel (app launcher) |
| `Mod+R` | open quickshell app launcher (see [🧱 The Quickshell Bar](#-the-quickshell-bar)) |
| `Mod+Shift+/` | hotkey help overlay |

### 🔊 Audio & brightness

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` / `Lower` | volume ±5% (works when locked) |
| `XF86AudioMute` | mute sink |
| `XF86AudioMicMute` | mute mic |
| `XF86MonBrightnessUp` / `Down` | brightness ±10% (works when locked) |

### 🪟 Windows & columns

| Keys | Action |
|---|---|
| `Mod+Q` | close window |
| `Mod+H/J/K/L` (or arrows) | focus left / down / up / right |
| `Mod+Ctrl+H/J/K/L` | move focused window left / down / up / right |
| `Mod+Home` / `Mod+End` | first / last column |
| `Mod+F` | maximize column |
| `Mod+Shift+F` | fullscreen |
| `Mod+Ctrl+V` | toggle floating |
| `Mod+Shift+V` | switch focus between floating and tiling |
| `Mod+W` | toggle tabbed display in the column |
| `Mod+[` / `Mod+]` | consume/expel window into/out of the column |
| `Mod+,` / `Mod+.` | consume / expel |
| `Mod+Ctrl+W` | cycle column width preset (1/3 · 1/2 · 2/3) |
| `Mod+Shift+R` | …backwards |
| `Mod+Ctrl+Shift+R` | cycle window height presets |
| `Mod+Ctrl+R` | reset window height |
| `Mod+-` / `Mod+=` | column width −/+ 10% |
| `Mod+Shift+-` / `Mod+Shift+=` | window height −/+ 10% |
| `Mod+Ctrl+F` | expand column to available width |
| `Mod+C` | center column |
| `Mod+Ctrl+C` | center all visible columns |

### 🗂️ Workspaces

| Keys | Action |
|---|---|
| `Mod+U` / `Mod+I` (or PgUp/PgDn) | previous / next workspace |
| `Mod+Ctrl+U/I` | move column to previous / next workspace |
| `Mod+1` … `Mod+9` | jump to workspace 1–9 |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | move column to workspace 1–9 |
| `Mod+O` | overview (bird's-eye view of all workspaces) |
| `Mod+WheelUp/Down` | previous / next workspace |
| `Mod+Ctrl+WheelUp/Down` | move column to workspace |
| `Mod+WheelLeft/Right` | previous / next column |
| `Mod+Ctrl+WheelLeft/Right` | move column |

### 🖥️ Monitors (multi-screen)

| Keys | Action |
|---|---|
| `Mod+Shift+H/J/K/L` | focus monitor left / down / up / right |
| `Mod+Ctrl+Shift+H/J/K/L` | move column to monitor |

### 📸 Screenshots

| Keys | Action |
|---|---|
| `Print` | screenshot (drag to select area) |
| `Ctrl+Print` | entire screen |
| `Alt+Print` | focused window |

Saved to `~/Pictures/Screenshots/` (see `screenshot-path` in the config).

### 🔒 Session

| Keys | Action |
|---|---|
| `Mod+Shift+E` | quit niri (back to greetd login) |
| `Ctrl+Alt+Delete` | quit niri |
| `Mod+Shift+P` | power off monitors |
| `Mod+Escape` | toggle keyboard-shortcut inhibitor (for remote-desktop apps) |

### 🖱️ Mouse actions

| Where | Action |
|---|---|
| bar workspace pill | click = jump to that workspace |
| touchpad | tap to click, natural (macOS-style) scrolling |
| top-left hot corner | opens the overview (if enabled) |

### ➕ Adding/removing binds

1. Edit `binds { }` in `~/.config/niri/config.kdl`
2. Reload: `niri msg action load-config-file` (no restart needed)

Bind syntax: `Mod+Key { action; }` — e.g. `Mod+P { spawn "ghostty"; }`.
Actions are listed in the wiki (Configuration → Key Bindings) or in the hotkey
overlay.

---

## 🎮 NVIDIA

The situation when this machine was set up:

- Ubuntu shipped with the **`595-server-open`** driver variant (headless server
  stack: kernel modules + compute libs, but **no display GL stack**, no
  `nvidia-smi`).
- That variant is useless for a desktop. We install the proper **`nvidia-driver-595`**
  (desktop variant) which replaces it.

### 📦 What the desktop driver gives you

| Piece | Package | Needed for |
|---|---|---|
| Kernel modules (`nvidia`, `nvidia_drm`, `nvidia_modeset`) | `linux-modules-nvidia-595-*` | hardware access |
| GL/EGL display stack | `libnvidia-gl-595` | niri + apps render on the dGPU |
| `nvidia-smi` | `nvidia-utils-595` | monitoring, verification |
| Firmware (GSP for Turing+) | `nvidia-firmware-595` | RTX 2060 is Turing (TU106) |

Verify after install:

```bash
nvidia-smi          # must print a driver table, not "command not found"
lsmod | grep nvidia # nvidia, nvidia_drm, nvidia_modeset loaded
dpkg -l | grep nvidia-driver
```

### 1️⃣ Step 1 — kernel command line: `nvidia-drm.modeset=1`

The kernel needs NVIDIA modesetting enabled for the dGPU to do full compositing
(memory management + GBM buffer sharing with the iGPU).

```bash
sudoedit /etc/default/grub
# → GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1"
sudo update-grub
```

Verify after reboot:

```bash
cat /proc/cmdline          # should contain nvidia-drm.modeset=1
cat /sys/module/nvidia_drm/parameters/modeset   # should print Y
```

### 2️⃣ Step 2 — VRAM heap reuse fix (required, do not skip)

> [!IMPORTANT]
> The NVIDIA driver has a quirk: compositors like niri that recycle buffers
> cause the driver to hoard VRAM (**1 GiB+** instead of ~100 MiB). The fix is a
> per-process application profile that disables the heap reuse heuristic.

```bash
sudo mkdir -p /etc/nvidia/nvidia-application-profiles-rc.d
sudo tee /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json > /dev/null <<'EOF'
{
  "rules": [
    {
      "pattern": { "feature": "procname", "matches": "niri" },
      "profile": "Limit Free Buffer Pool On Wayland Compositors"
    }
  ],
  "profiles": [
    {
      "name": "Limit Free Buffer Pool On Wayland Compositors",
      "settings": [
        { "key": "GLVidHeapReuseRatio", "value": 0 }
      ]
    }
  ]
}
EOF
```

Restart niri (or reboot) afterwards. Check VRAM usage with `nvtop` or
`watch -n 2 nvidia-smi` — should stay near ~100 MiB.

### 3️⃣ Step 3 — user groups

```bash
sudo usermod -aG video,render diskukumber
```

Verify with `groups` (takes effect after next login).

### 🔀 How the two GPUs cooperate

- The laptop panel (eDP) is wired to the **Intel** iGPU — it always drives the panel.
- niri renders with the **NVIDIA** dGPU via EGL/GBM.
- This works without any X11 config: Wayland compositors handle multi-GPU natively.

### 🛠️ Diagnostic commands

```bash
nvidia-smi                                   # status, VRAM, processes
lsmod | grep nvidia                          # module state
cat /sys/module/nvidia_drm/parameters/modeset # Y = modesetting on
dmesg | grep -i nvidia                       # kernel messages
journalctl -b | grep -iE "nvidia|egl"        # boot log mentions
ls /dev/dri/                                 # card0 = Intel, card1 = NVIDIA
```

### ⚠️ Known quirks

- **Screencast flickering** on NVIDIA: fixed upstream in niri ≥ 25.08 — nothing to do.
- **Suspend issues** on some dual-GPU laptops: if suspend misbehaves, check
  `nvidia-smi` power state and kernel logs; a reboot usually clears it.
- **VRAM heap**: the profile above must match the process name `niri` exactly.

---

## 🚧 Work In Progress

- [x] Minimal quickshell bar (workspaces, focused window title, clock).
- [x] App launcher popup written in quickshell (Mod+R); fuzzel kept as fallback (Mod+D).
- [x] Bar revamped as a waybar port: top bar = workspaces + stats cluster (NET/MEM/CPU/layout/date/clock) + system tray; bottom bar = app launcher + window taskbar; full-width bars with the off-edge side sweeping in a single full-height curve.
- [x] NVIDIA desktop driver (replaces server variant) + VRAM heap fix.
- [x] niri + quickshell stack runs (greetd path configured).
- [ ] **greetd currently disabled** — decide: `sudo systemctl enable --now greetd` (auto-login) or keep manual `niri-session` start.
- [ ] Restore audio (pipewire/wireplumber was purged with the GNOME cleanup) + volume keys via `wpctl`.
- [ ] Wallpaper layer (optional quickshell backdrop; solid `#111111` for now).
- [ ] Bluetooth: not installed yet (bluez optional).
- [ ] **Release cadence: interim** — every 6 months `sudo do-release-upgrade` to the next Ubuntu interim release (Fedora-style cadence, apt-based, no dnf/rpm; ~9 months of support per release).
- [ ] Screen locker (none yet — `Mod+Shift+E` quits back to greetd).

---

## 📦 Packages & Details

<details>
<summary><h3>📦 Packages & Details</h3></summary>

|  |  |
| :-- | --- |
🖥️ Distribution | [Ubuntu](https://ubuntu.com/) interim (6-month release cadence) — Server minimal
📦 Package manager | [nala](https://gitlab.com/volian/nala) 0.16.0 — pretty apt frontend (mirrors in `/etc/nala/sources.list`, aliases in `~/.bash_aliases`)
🪟 Compositor | [niri](https://niri-wm.github.io/niri/) (scrollable tiling, pure Wayland)
💻 Terminal Emulator | [Ghostty](https://ghostty.org/) (native Wayland, GPU-accelerated)
🚀 Applications launcher | [quickshell](https://quickshell.org/) popup (Mod+R) • [fuzzel](https://codeberg.org/dnkl/fuzzel) (Mod+D)
🧱 Bar / Shell | [quickshell](https://quickshell.org/) — hand-written `shell.qml` / `Bar.qml` / `Taskbar.qml` (~900 lines, waybar-style) |
🌍 Browser | [Helium](https://github.com/imputnet/helium-linux) (Chromium fork, real .deb)
🔑 Login Manager | [greetd](https://sr.ht/~kennylevinsen/greetd/) (text greeter: agreety — installed; **currently disabled**, enable with `sudo systemctl enable --now greetd`)
🔔 Compositor notifications | niri (built-in)
📸 Screenshots | niri (built-in: `Print` family)
📋 Clipboard Manager | [wl-clipboard](https://github.com/bugaevc/wl-clipboard) (`wl-copy` / `wl-paste`)
🖼️ Wallpaper | [awww](https://codeberg.org/hurlbutt/awww) 0.12.1 (images/GIFs, built from source) • [pandora](https://github.com/PandorasFox/pandora) 1.0.0 (parallax scroll) — swap with `wp` / `wp --parallax`
🔐 Authentication agent | polkitd
🌐 Network management | [NetworkManager](https://networkmanager.dev/) + `wpa_supplicant`
📡 Bluetooth | not installed — `bluez` + `bluez-utils` optional (see [📥 Installation](#-installation))
🔊 Audio control | pipewire + wireplumber (purged 2026-08-04, needs restore — see [🚧 Work In Progress](#-work-in-progress))
🔋 Power management | nvidia-powerd (nvidia-suspend/resume/hibernate units)
🎮 Graphics | Intel UHD (iGPU, drives panel) + NVIDIA RTX 2060 Mobile (dGPU, renders via nvidia-driver-595)
🖥️ Display stack | pure Wayland; `xwayland-satellite` for rare X11 apps
</details>

> [!TIP]
> **Wallpaper** (`wp` on PATH, works from any terminal):
> - `wp <file>` — set image or animated GIF via **awww** (covering every connected output)
> - `wp --parallax <file>` — static image with parallax workspace-scroll via **pandora**
> - `wp stop` — clear
> - Restored automatically at session start (niri `spawn-at-startup`); last file + mode live in `~/.cache/wp-current` / `~/.cache/wp-mode`
> - **Known quirk**: pandora logs one benign `unknown variant CastsChanged` IPC warning on niri (harmless — scroll still works)

---

## 🛠️ Troubleshooting & Known Issues

### 🥇 Golden rules

1. **Everything logs somewhere.** Check the logs before touching anything.
2. **The bar and compositor reload instantly** — editing a config is usually
   enough; only kernel/driver changes need a reboot.
3. **TTY rescue**: `Ctrl+Alt+F2` → log in → you have a full terminal even if
   the desktop is dead.

### 🩺 Symptom → fix table

| Symptom | Likely cause → fix |
|---|---|
| Black screen after login | niri failed to start. On tty2: `systemctl --user status niri`, `journalctl --user -u niri -b -e`. See [🎮 NVIDIA](#-nvidia) notes. |
| Desktop works, no bar | quickshell didn't start. On tty2: `pgrep -a quickshell`; run `quickshell` manually to see QML errors. |
| Greetd fails in a loop | `journalctl -u greetd -b -e`. Usually a session that exits instantly. `sudo systemctl restart greetd` after fixing the cause. |
| GPU fans spin, high idle power | `nvidia-smi` — check `nvidia` isn't rendering when it shouldn't; VRAM fix missing? See [🎮 NVIDIA](#-nvidia). |
| ~1 GiB VRAM used by niri | The GLVidHeapReuseRatio fix isn't applied or the process name changed. Re-check [🎮 NVIDIA](#-nvidia) Step 2 and restart niri. |
| Volume keys do nothing | `wpctl status` — is there a default sink? Wireplumber running? `systemctl --user status wireplumber`. |
| Brightness keys do nothing | `brightnessctl` not installed or the panel isn't exposed (`brightnessctl --list`). |
| Screenshots save nowhere | `~/Pictures/Screenshots` missing? `mkdir -p ~/Pictures/Screenshots`. |
| Bar shows no workspaces | `niri msg -j workspaces` from a terminal — does it return JSON? If "no niri instance", the compositor isn't running. |
| Bar shows stale workspaces | quickshell's polling loop died (rare). `quickshell` in the terminal shows the error; restart the session. |
| Ghostty doesn't open | `ghostty` from a terminal to see errors (missing font = install `fonts-jetbrains-mono`). |
| Apps look wrong / huge | Missing fonts → `fc-list | grep Inter`; install `fonts-inter`. |
| Bluetooth audio glitches | `systemctl --user status pipewire wireplumber`; reboot if needed. |
| Suspend/resume broken | Known hybrid-GPU quirk. `journalctl -b -1 | grep -i nvidia`; reboot usually clears it. |

### ⚠️ Known issues

- 🚪 **greetd is currently disabled** — the desktop must be started manually
  (`niri-session -l` from a TTY/shell) or greetd re-enabled
  (`sudo systemctl enable --now greetd`).
- 💤 **Suspend/resume** on this dual-GPU laptop can glitch — a reboot usually clears it.
- 🐧 Some **X11 apps** don't work under the pure Wayland session (**XWayland edge cases**).
- 🎮 **NVIDIA VRAM heap quirk** (~1 GiB hoarded by compositors): fixed by the
  application-profile JSON in [🎮 NVIDIA](#-nvidia); the profile must match `niri`.
- 🔇 **Audio purged** 2026-08-04 with the GNOME cleanup — volume keys need
  `pipewire pipewire-pulse wireplumber` reinstalled and `wpctl` binds.

### 🎮 NVIDIA-specific

```bash
nvidia-smi                                    # driver alive? VRAM usage?
lsmod | grep nvidia                           # modules loaded?
cat /sys/module/nvidia_drm/parameters/modeset # Y = modeset on (reboot needed to change)
cat /proc/cmdline                             # nvidia-drm.modeset=1 present?
```

- **Black screen on start**: modeset missing → add `nvidia-drm.modeset=1`
  ([🎮 NVIDIA](#-nvidia) Step 1), `sudo update-grub`, reboot.
- **High VRAM**: re-apply the profile JSON ([🎮 NVIDIA](#-nvidia) Step 2), restart niri.
- **nvidia-smi missing**: driver package not installed — `sudo apt install nvidia-driver-595`.

### 🔬 Checking the whole stack at once

```bash
# one-liner status report
systemctl status greetd --no-pager | head -3
systemctl --user status niri --no-pager | head -3
pgrep -a quickshell
niri msg -j workspaces | head -20
wpctl status | head -10
nvidia-smi | head -10
```

### 📁 Log locations

| Component | Where |
|---|---|
| greetd (login) | `journalctl -u greetd -b` |
| niri (compositor) | `journalctl --user -u niri -b` |
| quickshell (bar) | run `quickshell` from a terminal; also `journalctl --user -u quickshell` if a unit exists |
| pipewire / wireplumber | `journalctl --user -u pipewire -b`, `-u wireplumber` |
| kernel (drivers, GPUs) | `dmesg | grep -iE "nvidia|drm|i915"` |

### 🧯 Recovery recipes

**Kill the session from a TTY:**

```bash
# on tty2 (Ctrl+Alt+F2)
systemctl --user start niri-shutdown.target   # cleanly stop the session
# or
pkill -u $USER niri                            # hard way
```

**Reset a broken bar:**

```bash
pkill -f "quickshell"    # niri will not restart it — instead:
# restart the session from the login screen (Mod+Shift+E → log in again)
```

**Test the bar config standalone** (errors print to the terminal):

```bash
quickshell   # from a TTY inside the session or a nested terminal
```

### ❓ Still stuck?

Check the niri wiki FAQ (<https://niri-wm.github.io/niri/FAQ.html>) and the
quickshell docs (<https://quickshell.org/>), then search the error line from
the logs — it's usually a known issue.

---

## 🧹 Maintenance & Service Inventory

What's running, what can be trimmed, and the routine care this system needs.
Last audited: 2026-08-04.

### 🧽 One-time cleanup (done 2026-08-04)

All applied, review-first. How it was done:

<details>
<summary>🛠️ The cleanup steps (review-first, safe to re-run)</summary>

```bash
# 1. Remove unused automatic packages (nvidia-firmware-595-server)
sudo apt-get autoremove -y --purge

# 2. Remove optional packages not needed on this setup (dry-run first)
sudo apt-get remove --dry-run lxd-installer open-iscsi multipath-tools modemmanager
# apply with: sudo apt-get remove --purge lxd-installer open-iscsi multipath-tools modemmanager

# 3. Disable services that are leftovers from the server image
sudo systemctl disable --now kdump-tools multipathd ModemManager apport snapd snapd.socket

# 4. Purge cloud-init (provisioning leftovers, unused on bare metal)
sudo apt-get purge cloud-init -y && sudo rm -rf /etc/cloud /var/lib/cloud

# 5. Clean apt + npm caches
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
npm cache clean --force

# 6. Trim journal logs (keep last 200 MB)
sudo journalctl --vacuum-size=200M

# 7. Review ~/.cache before deleting (small, usually skipped)
du -sh ~/.cache
```
</details>

| Item | What | Status |
|---|---|---|
| `nvidia-firmware-595-server` | auto-installed server firmware, unused with the desktop driver | **removed** (103 MB freed) |
| `lxd-installer` | LXD snap wrapper; no containers are used | **removed** |
| `open-iscsi`, `multipath-tools`, `modemmanager` | iSCSI/SAN/mobile-broadband leftovers from the server image | **removed** |
| `cloud-init` + `cloud-init-base` | cloud provisioning; unused on bare metal (5 services) | **purged** |
| `snapd` | running with **0 snaps installed** | **purged** (7 services) |
| `kdump-tools`, `apport` | crash dump/reporting, no value here | **disabled** |
| apt cache | 834 MB of `.deb` archives + lists | **cleaned** (56 KB now) |
| npm cache | 86 MB | **cleared** |
| autoremove sweep | packagekit, usb-modeswitch, snapd-glib deps, appstream, etc. | **purged** (46 pkgs) |
| journal | 25 MB | already small, vacuumed |

Results: **~200 MB + 46 packages freed**; enabled services went 60 → 43 → **33 today** (verified 2026-08-04).

### ⚙️ Service inventory (enabled, system — 33 currently)

**✅ Enabled now:** `NetworkManager` + dispatcher · `chrony` · `systemd-resolved` ·
`apparmor` · `unattended-upgrades` · `thermald` · `gpu-manager` · `udisks2` ·
`nvidia-suspend/resume/hibernate/powerd` (hybrid graphics) · `wpa_supplicant` ·
`accounts-daemon` · `avahi-daemon` (optional, mDNS) · `lvm2-monitor`

**⏸️ Installed but not enabled:** `greetd` (login manager — **disabled**, see
[🚀 Session Startup](#-session-startup)) · `kdump-tools` (disabled) · `apport`
(disabled)

**🗑️ Not installed (already handled in cleanup):** `cloud-init` (purged) · `snapd`
(purged) · `multipath-tools`, `open-iscsi`, `ModemManager` (removed) ·
`power-profiles-daemon`, `systemd-oomd`, `switcheroo-control`, `bluez` (never
installed)

### 📄 Dotfiles & config inventory

| Path | Purpose |
|---|---|
| `~/.bashrc` | prompt, history, `ll/la/l` aliases, opencode PATH (all stock Ubuntu) |
| `~/.profile` | stock; sources `.bashrc`, adds `~/bin` + `~/.local/bin` to PATH |
| `~/.config/niri/config.kdl` | compositor: keybinds, layout, startup |
| `~/.config/ghostty/config` | terminal: theme, font, opacity |
| `~/.config/quickshell/shell.qml` + `Bar.qml` | the status bar |
| `~/.config/opencode/opencode.jsonc` | opencode config (currently minimal) |
| `~/.config/dconf`, `goa-1.0`, `evolution` | GNOME leftovers, unused in niri |
| `~/.local/share/keyrings` | login keyring (used by libsecret) |
| `~/.ssh/authorized_keys` | SSH keys (password login already off) |
| `~/.npm` | npm cache (86 MB, cleaned) |
| `~/.opencode` | opencode binary + system dir |

Applied bash aliases (`~/.bash_aliases`, loaded by `.bashrc`):

```bash
# type `apt` / `sudo apt …` and get nala:
alias sudo='sudo '   # trailing space → expands the word after sudo too
alias apt='nala'
alias apt-get='nala'
alias i='nala install'      # install
alias r='nala remove'       # remove
alias s='nala search'       # search
alias u='nala update'       # refresh package lists
alias up='nala upgrade'     # upgrade with the nice UI
alias nf='nala fetch'       # pick fastest mirrors
```

### 🔄 Routine maintenance

```bash
nala update && nala upgrade   # weekly
nala autoremove               # monthly (or: sudo apt autoremove --purge)
journalctl --vacuum-size=200M # if journal grows
nvidia-smi                    # verify GPU health
systemctl --user status niri  # compositor health
```

### ↩️ Rollback notes

- Service disables are reversible: `sudo systemctl enable --now <svc>`
- Removed packages: reinstall via `apt install <name>` (see [📥 Installation](#-installation))
- cloud-init purge removes `/etc/cloud` + `/var/lib/cloud`; harmless on bare metal

---

## 📜 Provisioning & Baseline

This machine's state is reproducible from the commands in this document.

### 📦 The baseline (fresh Ubuntu Server Minimal)

The baseline is defined by the `ubuntu-server-minimal` metapackage (27 direct
deps):

```
apparmor          apt            bcache-tools     btrfs-progs
chrony            cloud-init     cryptsetup       dbus
e2fsprogs         lvm2           mdadm            multipath-tools
netbase           open-iscsi     pollinate        snapd
sudo / sudo-rs    systemd        systemd-resolved systemd-sysv
ubuntu-drivers-common           ubuntu-release-upgrader-core
udev              unminimize     xfsprogs
```

Plus the installer's base layer: `linux-generic` kernel, `grub-efi-amd64` +
`shim-signed` (Secure Boot), `locales`, `nano`, `unattended-upgrades`,
`needrestart`, `hwctl`, standard `util-linux`/`coreutils` set.

**Default enabled services (fresh install):**

```
accounts-daemon  apparmor     apport         avahi-daemon
blk-availability bluetooth    chrony         cloud-init-* (5 units)
console-setup    e2scrub_reap finalrd        getty@
gpu-manager      grub2-common kdump-tools    keyboard-setup
lvm2-monitor     ModemManager multipathd     netplan-configure
networkd-dispatcher          NetworkManager-* (3)
open-iscsi       snapd.* (7)  switcheroo-control
systemd-networkd* systemd-oomd systemd-pstore systemd-resolved
thermald         udisks2      unattended-upgrades wpa_supplicant
```

**Default apt sources:**

```
http://ly.archive.ubuntu.com/ubuntu/    main restricted universe multiverse
https://security.ubuntu.com/ubuntu/     main restricted universe multiverse
```

### 🗺️ The model

```
fresh Ubuntu Server minimal  ──┐
                               ├── [install commands] ──▶ current desktop
current desktop state        ──┘           ▲
       │                                   │
       └── [reset commands] ───────────────┘
              (back to near-baseline)
```

### 💻 Commands

**▶️ Install (rebuild the whole desktop from a fresh install):**

```bash
# 1. Add the danklinux PPA (provides quickshell + niri on interim releases)
sudo add-apt-repository -y ppa:avengemedia/danklinux

# 2. Add the Helium browser repo (real .deb, no snap)
curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/helium.list > /dev/null

# 3. Install the desktop stack
sudo apt-get update
sudo apt-get install -y alacritty brightnessctl fuzzel ghostty greetd helium-bin niri \
  qml6-module-qtquick-layouts quickshell wl-clipboard \
  fonts-inter fonts-jetbrains-mono fonts-noto-color-emoji fonts-noto-core
sudo apt-get install -y nvidia-driver-595

# 4. Enable the desktop services
sudo systemctl enable --now greetd network-manager wpa_supplicant

# 5. Copy the configs back in place (see 📄 Config files in 📥 Installation)
#    ~/.config/niri/config.kdl · ~/.config/quickshell/*.qml · ~/.config/ghostty/config
#    /etc/greetd/config.toml · NVIDIA fixes (see 🎮 NVIDIA)
```

**⏹️ Reset (undo everything, back to near-baseline):**

```bash
sudo apt-get remove -y --purge alacritty brightnessctl fuzzel ghostty greetd helium-bin niri \
  qml6-module-qtquick-layouts quickshell wl-clipboard \
  fonts-inter fonts-jetbrains-mono fonts-noto-color-emoji fonts-noto-core
sudo apt-get purge --dry-run nvidia-driver-595   # review, then drop --dry-run
sudo systemctl disable --now greetd network-manager wpa_supplicant
sudo rm -f /etc/apt/sources.list.d/avengemedia-ubuntu-danklinux-resolute.sources
sudo rm -f /etc/apt/sources.list.d/helium.list /usr/share/keyrings/helium.gpg
sudo apt-get update && sudo apt-get autoremove --purge -y
# (kernel + grub + base remain untouched)
```

> [!TIP]
> Dry-run any apt operation first with `--dry-run` / `-s`.

### 🚫 What the commands do NOT touch (by design)

- `linux-generic` kernel, GRUB/EFI, Secure Boot (installer-level)
- `~/.ssh/authorized_keys` and `.bashrc` PATH line
- Home data (`~/docs`, `~/Pictures`, etc.)
- The reinstall path does NOT restore `/etc/greetd/config.toml` automatically —
  copy it back (see [🚀 Session Startup](#-session-startup)).

### ✅ Post-reboot verification

### 🗃️ Reference snapshots

Current machine state (snapshot 2026-08-04): **1089 packages** installed,
**61 manually installed**, **33 enabled services**. Regenerate these lists
anytime with:

```bash
apt-mark showmanual | sort > /tmp/manual-packages-current.txt
dpkg-query -W -f='${Package} ${Version}\n' | sort > /tmp/all-installed.txt
systemctl list-unit-files --type=service --state=enabled --no-pager | \
  grep enabled | awk '{print $1}' | sort > /tmp/enabled-services.txt
```

### ✅ After a reinstall, checklist

1. `systemctl status greetd` — login manager up
2. `systemctl --user status niri` — compositor running
3. `pgrep -a quickshell` — bar spawned
4. `nvidia-smi` — dGPU driver loaded
5. `nmcli device wifi list` — WiFi via NetworkManager

---

## ℹ️ Quick facts

- 🖥️ **OS**: Ubuntu interim (6-month release cadence), fresh minimal server install
- 📆 **Release plan**: interim cadence — bump to the next Ubuntu interim release every 6 months
  via `sudo do-release-upgrade` (see [🚧 Work In Progress](#-work-in-progress))
- 🪟 **Compositor**: niri (scrollable tiling Wayland compositor)
- 🧱 **Shell**: a small hand-written quickshell UI (top bar: workspaces, net/mem/cpu stats, keyboard, date/clock, tray; bottom bar: app launcher + window taskbar)
- 💻 **Terminal**: Ghostty
- 🚀 **Launcher**: quickshell popup (Mod+R); fuzzel kept as fallback (Mod+D)
- 🌍 **Browser**: Helium (Chromium fork, real .deb — no snap)
- 🖥️ **Display stack**: pure Wayland, no X11 apps, no desktop environment
- 🎯 **Policy**: only necessary packages, no third-party configs or shells
