# 🐧 disubuntu · Ubuntu interim

An **Ubuntu interim-based setup, lean by design** — a pure-Wayland desktop that
runs on **~2 processes** and gets refreshed on the **6-month interim release
cadence**.

| Summary | |
|---|---|
| 🖥️ **OS** | Ubuntu interim (non-LTS, 6-month cadence) — Server *minimized* base |
| 🪟 **Compositor** | [niri](https://niri-wm.github.io/niri/) (scrollable tiling, pure Wayland) |
| 🧱 **Shell** | hand-written [quickshell](https://quickshell.org/) bar (~990 lines) |
| 🎨 **GPU** | Intel UHD (iGPU, panel) + NVIDIA RTX 2060 (dGPU, renders) |

> [!IMPORTANT]
> 🚧 **Still under development** — this documentation is updated as the setup develops.

---

## 📑 Table of Contents

| Section | Covers |
|---|---|
| [📸 Screenshots](#-screenshots) | how screenshots are taken & where they land |
| [📥 Installation](#-installation) | the full path: get the minimized server ISO → strip to a pure base → switch to the interim cadence → add every package, in order |
| [🖥️ Hardware](#-hardware) | the machine: CPU, RAM, storage, dual-GPU hybrid graphics |
| [🧩 Software stack & package inventory](#-software-stack--package-inventory) | the diagram, who does what, every package, process count |
| [🚀 Session Startup](#-session-startup) | greetd → niri → quickshell boot chain |
| [🎛️ niri Configuration](#-niri-configuration) | config.kdl explained section by section |
| [🧱 The Quickshell Bar](#-the-quickshell-bar) | the hand-written bar: files, IPC, patterns, launcher |
| [⌨️ Key Bindings](#-key-bindings) | the full cheat sheet |
| [🎮 NVIDIA](#-nvidia) | driver, modeset, VRAM fix, groups, diagnostics |
| [🚧 Work In Progress](#-work-in-progress) | what's done, what's open, the 6-month release plan |
| [📦 Packages & Details](#-packages--details) | the one-glance component table |
| [🛠️ Troubleshooting & Known Issues](#-troubleshooting--known-issues) | symptom→fix table, logs, recovery recipes |
| [🧹 Maintenance & Service Inventory](#-maintenance--service-inventory) | cleanup, services, dotfiles, routine care |
| [📜 Provisioning & Baseline](#-provisioning--baseline) | fresh-install baseline, install/reset commands |
| [❓ FAQ](#-faq) | quick answers: why interim, why hand-written bar, how to update/reset |
| [ℹ️ Quick facts](#-quick-facts) | TL;DR summary |

---

## 📸 Screenshots

Screenshots are **built into niri** — no extra tool needed. They land in
`~/Pictures/Screenshots/` and are added here as you go:

| Keys | What it captures |
|---|---|
| `Print` | area (drag to select) |
| `Ctrl+Print` | entire screen |
| `Alt+Print` | focused window |

```
docs/system/screenshots/<name>.png
```

> [!NOTE]
> **Screenshot target** is set by `screenshot-path` in the niri config
> (`~/.config/niri/config.kdl`, [misc section](#-niri-configuration)).

---

## 📥 Installation

<details>
<summary><strong>📥 INSTALLATION — from zero, in order</strong></summary>

> [!TIP]
> The whole path is reproducible — every step is a command in this document.
> Follow the numbered sections **in order**; each leaves the machine in a
> verifiable state before the next.

---

### 1️⃣ Which Ubuntu to get — the *minimized server*, not the regular one

**Use the Ubuntu _Server_ image, and inside the installer pick the
"Minimized" profile.** This is not the same as the regular install:

| Installer profile | What you get | Why we avoid it |
|---|---|---|
| **Ubuntu Server (default)** | full server stack: snapd, cloud-init, LXD, iSCSI, multipath, ModemManager, … | installed junk we'd have to purge |
| ✅ **Ubuntu Server — "Minimized"** | just the base: kernel, systemd, coreutils, apt, ssh | the lean base we build on |

**How to get it:**
1. Grab the current Ubuntu Server ISO from <https://ubuntu.com/download/server>.
2. Boot the installer; at the **software selection** step choose
   **Ubuntu Server** → then tick **"Minimized"**.
3. Finish the install, reboot, and verify the machine comes up (SSH or TTY).

> [!NOTE]
> The "Minimized" profile installs the `ubuntu-server-minimal` metapackage —
> ~27 direct dependencies (kernel, systemd, apt, coreutils…). The full
> inventory is in [📜 Provisioning & Baseline](#-provisioning--baseline).

---

### 2️⃣ What the minimal install comes with

The **"Minimized"** profile installs the `ubuntu-server-minimal` metapackage
(~27 direct deps) plus the installer base layer. Two kinds of things are in it:
**essentials** (keep) and **Canonical extras** (we remove in step 3):

**Keep — the essentials:**

| Component | What it is |
|---|---|
| `linux-generic` kernel + `grub-efi-amd64` + `shim-signed` | the boot stack (Secure Boot), never touched |
| `systemd` + `systemd-resolved` + `journald` | the service manager + DNS resolver + logs |
| `apt` | package manager (we add `nala` as a frontend later) |
| `openssh-server` | headless access |
| `sudo` / `sudo-rs`, `udev`, `locales`, `nano` | base userland |
| `chrony`, `apparmor`, `unattended-upgrades` | time sync, security, auto security updates |
| `ubuntu-drivers-common`, `ubuntu-release-upgrader-core` | GPU driver handling + the upgrader (needed for step 4!) |
| `gpu-manager` service | GPU detection (ships with `ubuntu-drivers-common`) |

**Remove — the Canonical/server extras (step 3 purges these):**

| Package | What it is | Why remove |
|---|---|---|
| `snapd` | snap framework | 7 daemons for 0 snaps |
| `cloud-init` | cloud provisioning | unused on bare metal (5 services) |
| `open-iscsi`, `multipath-tools`, `modemmanager` | SAN / multipath / mobile-broadband | server-image leftovers |
| `apport` (+core-dump-handler, +symptoms) | crash reporting | useless on a personal machine |
| `kdump-tools` | kernel crash dumps | a laptop never crash-dumps to disk |
| `pollinate` | Canonical entropy seeding | cloud-image feature |
| `avahi-daemon` | mDNS/Bonjour | nothing here uses it |
| `udisks2` | storage D-Bus daemon | no file manager needs it |
| `networkd-dispatcher` | systemd-networkd event handler | we use NetworkManager, not networkd |
| `lxd-installer` | LXD container wrapper | no containers |
| `unminimize` | un-restores "minimized" images (applies docs/manpages back) | we want to *stay* minimal |

**Optional (judgment call, safe to keep):**

| Package | Note |
|---|---|
| `thermald` | Intel thermal daemon — useful on a laptop, tiny; keep unless you want zero daemons |
| `accountsservice` | user-account D-Bus — greetd/agreety works without it |
| `needrestart` | reminds you to restart daemons after library upgrades — genuinely useful, keep |

> [!NOTE]
> `nautilus`, `gvfs*` and `xdg-desktop-portal-gnome` are **not** in the base —
> they sneak in later as dependencies of niri's portal recommendations. They're
> removed in step 5f, after the stack install.

---

### 3️⃣ Strip it down further — no snaps, no unused packages, nothing in the background

Remove the Canonical extras so **nothing runs in the background** beyond
systemd, and no snap exists anywhere:

```bash
# 3a. Purge snap — completely gone (no daemons, no loop mounts, no /snap)
sudo apt-get purge -y snapd snapd.socket
sudo rm -rf /snap /var/snap /var/lib/snapd /root/snap /home/*/snap

# 3b. Purge cloud provisioning + container/server leftovers (not used on bare metal)
sudo apt-get purge -y cloud-init lxd-installer
sudo rm -rf /etc/cloud /var/lib/cloud

# 3c. Remove SAN/multipath/mobile-broadband leftovers from the server image
sudo apt-get purge -y open-iscsi multipath-tools modemmanager

# 3d. Purge crash-reporting + Canonical extras (not just disable — uninstall)
sudo apt-get purge -y apport apport-core-dump-handler apport-symptoms kdump-tools \
  pollinate avahi-daemon udisks2 networkd-dispatcher unminimize

# 3e. Clean apt + journal caches
sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && sudo apt-get update
sudo journalctl --vacuum-size=200M

# 3f. Verify: nothing snap, nothing cloud, no iscsi/multipath/modem/avahi
snap --version          # should fail: command not found
systemctl list-unit-files --state=enabled --no-pager | wc -l   # baseline: ~33 services
```

After this the machine is a **pure minimal system** — systemd, kernel,
coreutils, apt. Everything else that runs later is something *we* added
(see the service inventory in [🧹 Maintenance](#-maintenance--service-inventory)).

---

### 4️⃣ Switch to the interim release cadence

The Ubuntu Server ISO installs an **LTS** by default. This setup runs the
**interim (non-LTS)** 6-month cadence instead:

```bash
# 4a. Tell the upgrader to chase interim releases, not LTS-to-LTS
sudo sed -i 's/^Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades
grep '^Prompt' /etc/update-manager/release-upgrades    # → Prompt=normal

# 4b. Upgrade to the current interim release (26.10 & later: 27.04, …)
sudo do-release-upgrade -d
sudo reboot
```

> [!NOTE]
> `Prompt=normal` is the *interim* mode. The default `Prompt=lts` would keep
> you on LTS forever — this is the single setting that defines the cadence.
> `-d` is required when the target interim release is still in development;
> drop it once it's released. Verify after reboot:
> `cat /etc/os-release | grep VERSION_CODENAME` and repeat
> `do-release-upgrade` **every 6 months** (the cadence in
> [🚧 Work In Progress](#-work-in-progress)).

---

### 5️⃣ What we add — every package, with a reason

**5a. Repositories** (order matters):

| Source | Provides | When |
|---|---|---|
| Ubuntu main/universe | base + most tools | preconfigured |
| `ppa:avengemedia/danklinux` | quickshell + niri (official Ubuntu packaging) | now |
| `pkg.helium.computer/deb` | `helium-bin` browser (real .deb, no snap) | now |

```bash
# 5b. Add the PPA + browser repo
sudo add-apt-repository -y ppa:avengemedia/danklinux
curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/helium.list
sudo apt update
```

**5c. The stack — every package, grouped by purpose:**

```bash
# Compositor + UI
sudo apt install -y niri quickshell qml6-module-qtquick-layouts

# Terminal + launcher + clipboard
sudo apt install -y ghostty fuzzel wl-clipboard

# Session helpers
sudo apt install -y greetd xdg-desktop-portal polkitd brightnessctl

# Media keys + audio control (audio restore: see step 5d)
sudo apt install -y playerctl pipewire pipewire-pulse wireplumber

# Network (if not already enabled by the installer)
sudo apt install -y network-manager wpa_supplicant

# Fonts (bar + terminal + emoji)
sudo apt install -y fonts-inter fonts-jetbrains-mono \
  fonts-noto-core fonts-noto-color-emoji fonts-materialdesignicons-webfont

# NVIDIA desktop driver (replaces the server variant)
sudo apt install -y nvidia-driver-595

# Terminal fallback + build deps (used by the awww wallpaper helper)
sudo apt install -y alacritty cargo rustc pkg-config libwayland-dev liblz4-dev

# Browser (real .deb, no snap)
sudo apt install -y helium-bin

# Pretty apt frontend
sudo apt install -y nala
```

**5d. Audio note:** `pipewire`/`wireplumber` were purged on this machine
during the GNOME cleanup; install them here to restore sound (volume keys are
already bound to `wpctl` in the config).

**5e. What each package does** — see the full purpose tables in
[🧩 Software stack & package inventory](#-software-stack--package-inventory)
(every package is listed there with a "why" column).

**5f. Post-install cleanup — GNOME leftovers that came with niri's deps:**

Two chains sneak in through niri's recommendations and gnome-keyring — a file
manager/portal chain and an indexer/calendar chain. Neither is used here:

1. **File manager + portal chain** (`niri` recommends `xdg-desktop-portal-gnome`):
   `nautilus` → `gvfs*` → `avahi-daemon`/`udisks2` + `ipp-usb`
2. **Indexer + calendar chain** (pulled by `gnome-keyring`, which we keep):
   `localsearch` (tracker indexer) + `evolution-data-server` (mail/calendar
   backend) + `bluez-obexd` — these spawn 5 background user services
   (evolution-* ×4, localsearch-3)

Remove both chains (`xdg-desktop-portal` + `xdg-desktop-portal-gtk` stay —
base portal support; `gnome-keyring` stays — needed for secrets):

```bash
sudo apt-get purge -y xdg-desktop-portal-gnome nautilus gvfs gvfs-backends \
  gvfs-daemons avahi-daemon udisks2 ipp-usb localsearch \
  evolution-data-server evolution-data-server-common bluez-obexd
sudo apt-get autoremove --purge -y
```

> [!NOTE]
> If you ever install a GTK file manager or need GNOME-style file dialogs,
> `sudo apt install nautilus` brings the chain back automatically — harmless.
> The evolution/localsearch user services stop on their own once purged; a
> session restart drops any lingering units.

---

### 6️⃣ NVIDIA driver follow-up (required after step 5)

```bash
# kernel cmdline + VRAM fix + groups — full steps in the NVIDIA section
sudoedit /etc/default/grub        # add nvidia-drm.modeset=1
sudo usermod -aG video,render $USER
sudo update-grub
```

> [!IMPORTANT]
> Apply the VRAM heap reuse fix (Step 2 in [🎮 NVIDIA](#-nvidia)) **before**
> first GUI session — niri can otherwise hoard 1 GiB+ of VRAM.

---

### 7️⃣ Config files (all ours, no third-party configs)

| File | What it is |
|---|---|
| `~/.config/niri/config.kdl` | compositor (rewritten, commented) |
| `~/.config/quickshell/shell.qml` | shell entry point |
| `~/.config/quickshell/Bar.qml` | top bar (workspaces · stats · tray) |
| `~/.config/quickshell/Taskbar.qml` | bottom bar (launcher · window taskbar) |
| `~/.config/quickshell/Launcher.qml` | app launcher popup |
| `~/.config/ghostty/config` | terminal |

These live in the `disubuntu` repo (`dotfiles/`) and are symlinked into
`~/.config/` — edit once, sync with `git push`.

---

### 8️⃣ Rebuilding from scratch checklist

- [ ] Install **Ubuntu Server "Minimized"** from the ISO
- [ ] Run step 3 (purge snaps/cloud/leftovers) + step 4 (interim cadence)
- [ ] `sudo add-apt-repository -y ppa:avengemedia/danklinux` + helium repo
- [ ] Install all packages from step 5c
- [ ] `nvidia-drm.modeset=1` kernel cmdline + `sudo update-grub` (see [🎮 NVIDIA](#-nvidia))
- [ ] NVIDIA VRAM fix JSON (see [🎮 NVIDIA](#-nvidia))
- [ ] `sudo usermod -aG video,render $USER`
- [ ] `sudo systemctl enable --now greetd` (auto-login; else start `niri-session` from a TTY)
- [ ] Copy configs from this repo (step 7)
- [ ] Reboot → log in on tty1 (greetd handles it)
- [ ] `systemctl --user status niri` + `pgrep -a quickshell` → desktop up
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

> [!TIP]
> **This is what "PRIME render offload" means in practice:** niri does its
> rendering on the dGPU (fast), then hands finished frames to the iGPU, which
> owns the panel. You get dGPU performance with iGPU battery behavior at idle.

### 🛠️ Hardware commands

| Command | What it shows |
|---|---|
| `lspci \| grep -iE "vga\|3d"` | both GPUs on the PCI bus |
| `nvidia-smi` | NVIDIA GPU status, VRAM, processes |
| `ls /dev/dri/` | render devices (`card0`=Intel, `card1`=NVIDIA) |
| `cat /sys/class/drm/card1/device/…` | raw GPU info if needed |

---

## 🧩 Software stack & package inventory

What runs, what each piece does, and every installed package by category.

> [!NOTE]
> 📊 **Snapshot 2026-08-04:** **961 packages** installed, **70 manually
> installed**, **30 enabled services** — measured *after* the steps-3/5f purge.

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
│  (audio: purged 2026-08-04 — see Package inventory)           │
├───────────────────────────────────────────────────────────────┤
│  GRAPHICS                                                     │
│  nvidia-driver-595 (dGPU render) + Intel iGPU (scanout)       │
│  Mesa (fallback GL) + Vulkan drivers                          │
└───────────────────────────────────────────────────────────────┘
```

### 👤 Who does what

> [!TIP]
> **Why these specific tools?** The table below is the whole "why" in one
> place — every role is filled by either niri itself, our own QML, or a
> standard Wayland utility. Nothing here pulls a desktop environment along.

| Job | Handled by | Why this choice |
|---|---|---|
| **Window management** | **niri** | scrollable tiling, pure Wayland, tiny |
| **Notifications** | **niri (built-in)** | popups rendered by the compositor — zero extra daemons |
| **Screenshots** | **niri (built-in)** | `Print` / `Ctrl+Print` / `Alt+Print` — no grim/slurp needed |
| **Status bar** | **quickshell + our `shell.qml`** | one process, ~990 lines of hand-written QML |
| **App launcher** | **quickshell (`Launcher.qml`)** | popup under the bar, Mod+R; fuzzel kept as fallback (Mod+D) |
| **Browser** | **Helium** (`helium-bin`, .deb repo) | Chromium fork with Chrome-extension support; real .deb, no snap |
| **Terminal** | **Ghostty** | native Wayland, GPU-accelerated |
| **Clipboard** | **wl-clipboard** (`wl-copy`/`wl-paste`) | the Wayland standard |
| **Backlight keys** | **brightnessctl** | works on Intel panels |
| **Audio** | **none (removed)** | purged with the GNOME cleanup; restore via `sudo apt install pipewire pipewire-pulse wireplumber` — volume keys use `wpctl` |
| **Login** | **greetd** | headless login manager, no GNOME bloat (installed; currently **disabled** — see [🚀 Session Startup](#-session-startup)) |
| **Desktop GPU** | **nvidia-driver-595** | see [🎮 NVIDIA](#-nvidia) |

### 🚫 What is intentionally NOT here

> [!TIP]
> **The lean principle:** if a component can be built into niri or our bar, we
> do not run a separate daemon for it. Every extra process is a point of
> failure, memory, and maintenance.

| Not installed | Why we skip it |
|---|---|
| Full X server / X11 apps | pure Wayland provides everything we need; rootless `xwayland-satellite` is installed to run rare X11 apps |
| Desktop environment, GUI display manager | greetd text login + niri is the whole "DE" |
| Third-party shell configs (waybar-ports, DMS shells, …) | the bar is ours — ~990 lines, fully readable |
| `waybar`, `mako`, `swaybg`, `swaylock`, `grim`, `slurp` | niri + our bar replace them (notifications & screenshots are built into niri) |
| `gammastep`/nightlight, polkit agent, standalone tray daemon | keep it lean — tray lives in the top bar

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
| `fonts-materialdesignicons-webfont` | Material Design Icons glyphs — used by the bar's NET/MEM/CPU/layout/clock icons |

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
| `xdg-desktop-portal` (+ `xdg-desktop-portal-gtk`) | screen sharing, file dialogs for sandboxed apps (the GNOME backend is deliberately removed in step 5f) |
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

| Process | Count | What it is |
|---|---|---|
| `niri` | **1** | the compositor |
| `quickshell` | **1** | the whole UI |
| terminal | **0** | nothing at idle |
| `pipewire` + `wireplumber` | **2–3** | only after audio is restored |

That's the whole desktop: **~2 processes** on top of systemd right now
(audioless); **~5** once pipewire + wireplumber are back.

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

1. **Ubuntu boots** → greetd takes over **tty1**
2. **greetd** runs `agreety` — a text login prompt (username + password)
3. After login, greetd runs: **`niri-session`**
4. `niri-session`:
   - imports the login environment into the systemd user session
   - refreshes the D-Bus activation environment
   - starts `niri.service` (the compositor, with `--session`)
5. **niri** reads `~/.config/niri/config.kdl` → spawns quickshell
6. **quickshell** renders the bars (top: workspaces · stats · tray; bottom: launcher · taskbar)
7. ✅ **Desktop is up** — ~2 processes total (audioless; ~5 with audio)

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

| Option | Why not / why yes |
|---|---|
| **GDM / SDDM** | would pull in GNOME/KDE dependencies — against the lean principle |
| **greetd** ✅ | one small daemon + a text greeter (`agreety`); runs `niri-session` for you and handles seat/permissions correctly |
| **Manual TTY login** | same UX, but greetd auto-starts the session — tidier |

> [!NOTE]
> This is a **headless login flow**: greetd has no GUI. You type your
> username + password on a text screen, and the desktop starts underneath it —
> no display-manager graphics at all.

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

| Command | What it does |
|---|---|
| `systemctl status greetd` | login manager status |
| `journalctl -u greetd` | login manager logs |
| `systemctl --user status niri` | compositor status |
| `journalctl --user -u niri -f` | compositor logs (live) |
| `niri msg -j workspaces` | verify IPC (bar data source) |
| `pgrep -a quickshell` | shell should be running |

---

## 🎛️ niri Configuration

`~/.config/niri/config.kdl` — the compositor. **Format**: KDL, `//` starts a
comment. Wiki: <https://niri-wm.github.io/niri/>.

### 🗺️ Section map

| Lines | Section | What it does |
|---|---|---|
| 10-35 | `environment` | environment variables for all Wayland apps |
| 37-58 | `input` | keyboard + touchpad settings |
| 60-87 | `layout` | gaps, background, focus ring, shadows |
| 90-95 | startup | spawns quickshell (the bar) + wallpaper restore |
| 97-108 | misc | CSD handling, screenshots |
| 111-152 | window/layer rules | corner radius, opacity, quickshell/pandora behavior |
| 155-320 | `binds` | all keybindings |

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

| Setting | Effect |
|---|---|
| `keyboard { xkb {} }` | layout follows **systemd-localed** — change it live with `localectl` (no reload needed) |
| `numlock` | NumLock on at boot |
| `touchpad { tap }` | tap-to-click |
| `natural-scroll` | macOS-style scrolling |

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

The entire UI is a hand-written quickshell config (~990 lines). No third-party
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

| Property | What it buys you |
|---|---|
| **One process** for the whole UI (~15 MB RSS) | minimal memory, no daemon coordination |
| **No third-party anything** (no shell configs, plugins, notification daemons) | the compositor does notifications + screenshots itself |
| **Plain QML + one documented command** (`niri msg`) | you can read, modify, and trust every line |

### 🔄 Reloading

Save any file — quickshell reloads automatically. If the bar disappears:

```bash
pgrep -a quickshell
# if missing, restart the session (Mod+Shift+E quits niri, greetd gives you a fresh one)
```

---

## ⌨️ Key Bindings

> [!TIP]
> **`Mod` = 👑 Super/Windows key.** Every single bind lives in `binds { }` in
> `~/.config/niri/config.kdl` — this table reflects that file exactly.
> Changed something? Just `niri msg action load-config-file`.

### 🚀 Apps

| Keys | Action |
|---|---|
| `Mod+T` (or `Mod+Return`) | open Ghostty (terminal) |
| `Mod+D` | open fuzzel (app launcher) |
| `Mod+R` | open quickshell app launcher (see [🧱 The Quickshell Bar](#-the-quickshell-bar)) |
| `Mod+S` | screenshot (drag to select area) |
| `Ctrl+Space` | kando pie menu (needs kando) |
| `XF86Tools` / `XF86Explorer` / `XF86Mail` | open spotify / nemo / thunderbird (needs the apps) |
| `Mod+Shift+/` | hotkey help overlay |

### 🔊 Audio & brightness

> [!WARNING]
> **Audio is currently purged** from the machine (removed with the GNOME
> cleanup on 2026-08-04). These binds work **after** you restore it:
> `sudo apt install -y pipewire pipewire-pulse wireplumber`.

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` / `Lower` | volume ±5% (works when locked) |
| `XF86AudioMute` | mute sink |
| `XF86AudioMicMute` | mute mic |
| `XF86AudioNext` / `Prev` / `Play` / `Pause` / `Stop` | playerctl media control (needs playerctl) |
| `XF86MonBrightnessUp` / `Down` | brightness ±10% (works when locked) |

### 🪟 Windows & columns

| Keys | Action |
|---|---|
| `Mod+Q` | close window |
| `Mod+H/J/K/L` (or arrows) | focus left / down / up / right |
| `Mod+Shift+H/J/K/L` (or `Mod+Ctrl+H/J/K/L`) | move focused window left / down / up / right |
| `Mod+Home` / `Mod+End` | first / last column |
| `Mod+Ctrl+Home` / `Mod+Ctrl+End` | move column to first / last position |
| `Mod+F` | fullscreen |
| `Mod+Shift+F` | maximize column |
| `Mod+Space` (or `Mod+Ctrl+V`) | toggle floating |
| `Mod+Shift+V` | switch focus between floating and tiling |
| `Mod+W` | toggle tabbed display in the column |
| `Mod+[` / `Mod+]` | consume/expel window into/out of the column |
| `Mod+,` / `Mod+.` | consume / expel |
| `Mod+Ctrl+W` | cycle column width preset (1/3 · 1/2 · 2/3) |
| `Mod+Ctrl+Shift+W` | …backwards |
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
| `Mod+Ctrl+Page_Down` / `Mod+Ctrl+Page_Up` | move column to previous / next workspace |
| `Mod+1` … `Mod+0` | jump to workspace 1–10 |
| `Mod+Shift+1` … `Mod+Shift+0` | move column to workspace 1–10 |
| `Mod+O` | overview (bird's-eye view of all workspaces) |
| `Mod+WheelUp/Down` | previous / next workspace |
| `Mod+Ctrl+WheelUp/Down` | move column to workspace |
| `Mod+WheelLeft/Right` | previous / next column |
| `Mod+Ctrl+WheelLeft/Right` | move column |

### 🖥️ Monitors (multi-screen)

| Keys | Action |
|---|---|
| `Mod+Alt+Left/Right/Up/Down` | focus monitor left / right / up / down |
| `Mod+Shift+Alt+Left/Right/Up/Down` | move column to monitor |

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
| `Mod+Shift+E` (or `Mod+Shift+Q`) | quit niri (back to greetd login) |
| `Ctrl+Alt+Delete` | quit niri |
| `Mod+Shift+R` | reload config |
| `Mod+Shift+P` | power off monitors |
| `Mod+Escape` | toggle keyboard-shortcut inhibitor (for remote-desktop apps) |

### 🖱️ Mouse actions

| Where | Action |
|---|---|
| bar workspace pill | click = jump to that workspace |
| touchpad | tap to click, natural (macOS-style) scrolling |
| top-left hot corner | opens the overview (if enabled) |

### ➕ Adding/removing binds

```bash
# 1. Edit binds { } in ~/.config/niri/config.kdl
# 2. Apply live (no restart, no reboot):
niri msg action load-config-file
```

**Bind syntax:** `Mod+Key { action; }` → example: `Mod+P { spawn "ghostty"; }`.

| Resource | What it gives |
|---|---|
| [niri Wiki → Configuration](https://niri-wm.github.io/niri/Configuration.html) | every action, in full |
| hotkey overlay `Mod+Shift+/` | on-screen list of your current binds |

> [!TIP]
> The overlay (`Mod+Shift+/`) is the fastest way to check what's bound —
> it reads live from the config, not from this doc.

---

## 🎮 NVIDIA

The situation when this machine was set up:

| Driver variant | What it is | Verdict |
|---|---|---|
| **`595-server-open`** (shipped with the image) | headless server stack: kernel modules + compute libs, **no display GL stack**, no `nvidia-smi` | ❌ useless for a desktop |
| **`nvidia-driver-595`** (desktop variant) | full display GL stack + tools | ✅ what we install — replaces the above |

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

| Piece | Role |
|---|---|
| **Intel iGPU** | the laptop panel (eDP) is wired to it — it always drives the panel (scanout) |
| **NVIDIA dGPU** | niri renders with it via EGL/GBM (compute + games offload here) |

This works **without any X11 config** — Wayland compositors handle multi-GPU
natively.

### 🛠️ Diagnostic commands

| Command | What it tells you |
|---|---|
| `nvidia-smi` | status, VRAM, processes |
| `lsmod \| grep nvidia` | module state |
| `cat /sys/module/nvidia_drm/parameters/modeset` | `Y` = modesetting on |
| `dmesg \| grep -i nvidia` | kernel messages |
| `journalctl -b \| grep -iE "nvidia\|egl"` | boot-log mentions |
| `ls /dev/dri/` | `card0` = Intel, `card1` = NVIDIA |

### ⚠️ Known quirks

| Quirk | Status |
|---|---|
| Screencast flickering on NVIDIA | ✅ fixed upstream in niri ≥ 25.08 — nothing to do |
| Suspend issues on some dual-GPU laptops | if suspend misbehaves: check `nvidia-smi` power state + kernel logs; a reboot usually clears it |
| VRAM heap | the profile must match the process name `niri` **exactly** |

---

## 🚧 Work In Progress

> [!NOTE]
> **What "done" means here:** the desktop is fully usable today — compositor,
> bar, launcher, NVIDIA, screenshots, notifications. The open items below are
> refinements and decisions, not blockers.

### ✅ Done

- [x] Minimal quickshell bar (workspaces, focused window title, clock).
- [x] App launcher popup written in quickshell (Mod+R); fuzzel kept as fallback (Mod+D).
- [x] Bar revamped as a waybar port: top bar = workspaces + stats cluster (NET/MEM/CPU/layout/date/clock) + system tray; bottom bar = app launcher + window taskbar; full-width bars with the off-edge side sweeping in a single full-height curve.
- [x] NVIDIA desktop driver (replaces server variant) + VRAM heap fix.
- [x] niri + quickshell stack runs (greetd path configured).

### 🚧 Open

- [ ] **greetd currently disabled** — decide: `sudo systemctl enable --now greetd` (auto-login) or keep manual `niri-session` start.
- [ ] Restore audio (pipewire/wireplumber was purged with the GNOME cleanup) + volume keys via `wpctl`.
- [ ] Wallpaper layer (optional quickshell backdrop; solid `#111111` for now).
- [ ] Bluetooth: not installed yet (bluez optional).
- [ ] Screen locker (none yet — `Mod+Shift+E` quits back to greetd).

### 📆 Release cadence

> [!TIP]
> **Interim releases, every 6 months:** `sudo do-release-upgrade` to the next
> Ubuntu interim release — Fedora-style cadence, apt-based, no dnf/rpm.
> Each release gets ~9 months of support. The switch is `Prompt=normal` in
> `/etc/update-manager/release-upgrades` (already set, see step 4 of
> [📥 Installation](#-installation)).

---

## 📦 Packages & Details

<details>
<summary><strong>📦 Packages & Details — every component, at a glance</strong></summary>

|  |  |
| :-- | --- |
| 🖥️ Distribution | [Ubuntu](https://ubuntu.com/) interim (6-month release cadence) — Server minimal |
| 📦 Package manager | [nala](https://gitlab.com/volian/nala) — pretty apt frontend (mirrors in `/etc/nala/sources.list`, aliases in `~/.bash_aliases`) |
| 🪟 Compositor | [niri](https://niri-wm.github.io/niri/) (scrollable tiling, pure Wayland) |
| 💻 Terminal Emulator | [Ghostty](https://ghostty.org/) (native Wayland, GPU-accelerated) |
| 🚀 Applications launcher | [quickshell](https://quickshell.org/) popup (Mod+R) • [fuzzel](https://codeberg.org/dnkl/fuzzel) (Mod+D) |
| 🧱 Bar / Shell | [quickshell](https://quickshell.org/) — hand-written `shell.qml` / `Bar.qml` / `Taskbar.qml` (~990 lines, waybar-style) |
| 🌍 Browser | [Helium](https://github.com/imputnet/helium-linux) (Chromium fork, real .deb) |
| 🔑 Login Manager | [greetd](https://sr.ht/~kennylevinsen/greetd/) (text greeter: agreety — installed; **currently disabled**, enable with `sudo systemctl enable --now greetd`) |
| 🔔 Compositor notifications | niri (built-in) |
| 📸 Screenshots | niri (built-in: `Print` family) |
| 📋 Clipboard Manager | [wl-clipboard](https://github.com/bugaevc/wl-clipboard) (`wl-copy` / `wl-paste`) |
| 🖼️ Wallpaper | [awww](https://codeberg.org/hurlbutt/awww) (images/GIFs, built from source) • [pandora](https://github.com/PandorasFox/pandora) (parallax scroll) — swap with `wp` / `wp --parallax` |
| 🔐 Authentication agent | polkitd |
| 🌐 Network management | [NetworkManager](https://networkmanager.dev/) + `wpa_supplicant` |
| 📡 Bluetooth | not installed — optional; add later with `sudo apt install bluez bluez-utils` (not part of the lean base) |
| 🔊 Audio control | pipewire + wireplumber (purged 2026-08-04, needs restore — see [🚧 Work In Progress](#-work-in-progress)) |
| 🔋 Power management | nvidia-powerd (nvidia-suspend/resume/hibernate units) |
| 🎮 Graphics | Intel UHD (iGPU, drives panel) + NVIDIA RTX 2060 Mobile (dGPU, renders via nvidia-driver-595) |
| 🖥️ Display stack | pure Wayland; `xwayland-satellite` for rare X11 apps |
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

| # | Rule | Why |
|---|---|---|
| 1 | **Everything logs somewhere** — check logs before touching anything | you avoid blind changes; the log usually names the exact cause |
| 2 | **The bar and compositor reload instantly** — editing a config is usually enough | only kernel/driver changes need a reboot |
| 3 | **TTY rescue**: `Ctrl+Alt+F2` → log in → full terminal even if the desktop is dead | the escape hatch for every session-level problem |

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

| Issue | Status / workaround |
|---|---|
| 🚪 **greetd is currently disabled** | desktop must be started manually (`niri-session -l` from a TTY/shell) or greetd re-enabled (`sudo systemctl enable --now greetd`) |
| 💤 **Suspend/resume** can glitch on this dual-GPU laptop | a reboot usually clears it |
| 🐧 Some **X11 apps** misbehave under pure Wayland | XWayland edge cases; run them via `xwayland-satellite` |
| 🎮 **NVIDIA VRAM heap quirk** (~1 GiB hoarded by compositors) | fixed by the application-profile JSON in [🎮 NVIDIA](#-nvidia); the profile must match `niri` |
| 🔇 **Audio purged** (2026-08-04, GNOME cleanup) | reinstall `pipewire pipewire-pulse wireplumber`; volume keys use `wpctl` |

### 🎮 NVIDIA-specific

| Symptom | Fix |
|---|---|
| **Black screen on start** | modeset missing → add `nvidia-drm.modeset=1` ([🎮 NVIDIA](#-nvidia) Step 1), `sudo update-grub`, reboot |
| **High VRAM** | re-apply the profile JSON ([🎮 NVIDIA](#-nvidia) Step 2), restart niri |
| **nvidia-smi missing** | driver package not installed — `sudo apt install nvidia-driver-595` |

```bash
nvidia-smi                                    # driver alive? VRAM usage?
lsmod | grep nvidia                           # modules loaded?
cat /sys/module/nvidia_drm/parameters/modeset # Y = modeset on (reboot needed to change)
cat /proc/cmdline                             # nvidia-drm.modeset=1 present?
```

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

| Situation | The move |
|---|---|
| **Desktop frozen** | `Ctrl+Alt+F2` → log in on tty2 → kill the session (below) |
| **Session won't quit** | `systemctl --user start niri-shutdown.target` (clean) or `pkill -u $USER niri` (hard) |
| **Bar broken/disappeared** | `pkill -f "quickshell"` then re-login (niri won't restart it itself) |
| **Bar errors invisible** | run `quickshell` in a terminal — errors print right there |

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
quickshell docs (<https://quickshell.org/>), then **search the exact error
line** from the logs — it's usually a known issue.

> [!TIP]
> **How to report a bug worth solving:** paste the full `journalctl --user -u
> niri -b -e` tail (or the quickshell error) — that one line usually contains
> the answer already.

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
| `nvidia-firmware-595-server` | auto-installed server firmware, unused with the desktop driver | ✅ **removed** (103 MB freed) |
| `lxd-installer` | LXD snap wrapper; no containers are used | ✅ **removed** |
| `open-iscsi`, `multipath-tools`, `modemmanager` | iSCSI/SAN/mobile-broadband leftovers from the server image | ✅ **removed** |
| `cloud-init` + `cloud-init-base` | cloud provisioning; unused on bare metal (5 services) | ✅ **purged** |
| `snapd` | running with **0 snaps installed** | ✅ **purged** (7 services) |
| `kdump-tools`, `apport` (+core-dump-handler, +symptoms) | crash dump/reporting, no value here | ✅ **purged** (was: disabled) |
| `pollinate`, `avahi-daemon`, `udisks2`, `networkd-dispatcher`, `unminimize` | Canonical/server leftovers | ✅ **purged** |
| `nautilus`, `gvfs*`, `xdg-desktop-portal-gnome`, `ipp-usb` | GNOME file-manager/portal chain (niri Recommends) | ✅ **purged** |
| `evolution-data-server` (+libs), `bluez-obexd`, `localsearch` | GNOME calendar/indexer chain (via gnome-keyring) — 5 user services stopped | ✅ **purged** |
| apt cache | 834 MB of `.deb` archives + lists | ✅ **cleaned** (56 KB now) |
| npm cache | 86 MB | ✅ **cleared** |
| autoremove sweep | packagekit, usb-modeswitch, snapd-glib deps, appstream, etc. | ✅ **purged** (46 pkgs) |
| journal | 25 MB | ✅ already small, vacuumed |

> [!NOTE]
> **Net effect of the cleanup:** ~200 MB + 46 packages freed; enabled services
> went **60 → 43 → 30** (verified 2026-08-04, after the full steps-3/5f purge).

### ⚙️ Service inventory (enabled, system — 30 currently)

**✅ Enabled now:** `NetworkManager` (+dispatcher/wait-online) · `chrony` ·
`systemd-resolved` · `systemd-networkd` (+wait-online, netplan-configure) ·
`apparmor` · `unattended-upgrades` · `thermald` · `gpu-manager` ·
`nvidia-suspend/resume/hibernate/powerd` (hybrid graphics) · `wpa_supplicant` ·
`accounts-daemon` · `lvm2-monitor` · `blk-availability` · `console-setup` ·
`keyboard-setup` · `setvtrgb` · `e2scrub_reap` · `finalrd` · `grub2-common` ·
`grub-initrd-fallback` · `secureboot-db` · `systemd-pstore` · `getty@`

**⏸️ Installed but not enabled:** `greetd` (login manager — **disabled**, see
[🚀 Session Startup](#-session-startup))

**🗑️ Not installed (purged by steps 3 + 5f):** `cloud-init` · `snapd` ·
`apport` · `kdump-tools` · `pollinate` · `avahi-daemon` · `udisks2` ·
`networkd-dispatcher` · `unminimize` · `nautilus`/`gvfs*` ·
`xdg-desktop-portal-gnome` · `evolution-data-server` · `localsearch` ·
`multipath-tools`, `open-iscsi`, `ModemManager`, `lxd-installer` ·
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
nala update && nala upgrade   # weekly — security + updates
nala autoremove               # monthly — drop orphaned deps
journalctl --vacuum-size=200M # if the journal grows past 200 MB
nvidia-smi                    # verify GPU health (VRAM, driver)
systemctl --user status niri  # compositor health
```

> [!NOTE]
> **What each command watches over:** `nala` keeps the ~961 packages patched,
> `journalctl` bounds disk, `nvidia-smi` catches the VRAM quirk, and `niri`
> status confirms the compositor survived the upgrade. None of these take more
> than a minute.

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

Of these, **step 3 of [📥 Installation](#-installation) purges** the Canonical
extras: `cloud-init`, `snapd`, `pollinate`, `open-iscsi`, `multipath-tools`,
`unminimize` — leaving only the essentials.

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

Follow the numbered [📥 Installation](#-installation) flow — it is the
authoritative, in-order command list:

```bash
# Step 1-2: install Ubuntu Server "Minimized" from the ISO, verify it boots
# Step 3:   strip to a pure base (purge snaps, cloud-init, leftovers)
# Step 4:   switch to the interim cadence (Prompt=normal + do-release-upgrade)
# Step 5:   repos + every package (niri, quickshell, ghostty, nvidia, fonts, …)
# Step 6:   NVIDIA kernel cmdline + VRAM fix + groups
# Step 7:   copy the configs from this repo into ~/.config/
# Step 8:   sudo systemctl enable --now greetd  +  reboot
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

| Untouched | Why |
|---|---|
| `linux-generic` kernel, GRUB/EFI, Secure Boot | installer-level — never fiddled with |
| `~/.ssh/authorized_keys` + `.bashrc` PATH line | personal access + your env stays intact |
| Home data (`~/docs`, `~/Pictures`, …) | reset only touches system state |
| `/etc/greetd/config.toml` | **not** restored by the reinstall path — copy it back manually (see [🚀 Session Startup](#-session-startup)) |

### ✅ Post-reboot verification

Run the [reinstall checklist](#-after-a-reinstall-checklist) below after any
reboot — it proves the desktop came up end-to-end (greetd → niri → quickshell →
NVIDIA → network).

### 🗃️ Reference snapshots

Current machine state (snapshot 2026-08-04): **961 packages** installed,
**70 manually installed**, **30 enabled services**. Regenerate these lists
anytime with:

```bash
apt-mark showmanual | sort > /tmp/manual-packages-current.txt
dpkg-query -W -f='${Package} ${Version}\n' | sort > /tmp/all-installed.txt
systemctl list-unit-files --type=service --state=enabled --no-pager | \
  grep enabled | awk '{print $1}' | sort > /tmp/enabled-services.txt
```

### ✅ After a reinstall, checklist

| # | Check | Expect |
|---|---|---|
| 1 | `systemctl status greetd` | login manager **up** |
| 2 | `systemctl --user status niri` | compositor **running** |
| 3 | `pgrep -a quickshell` | bar **spawned** |
| 4 | `nvidia-smi` | dGPU driver **loaded** |
| 5 | `nmcli device wifi list` | WiFi via NetworkManager |

---

## ❓ FAQ

**"Why not just install Ubuntu Desktop?"** Because it ships a GNOME desktop,
snaps, and hundreds of packages we'd never use. This setup starts from the
*minimized server* base and adds only what we need — **~961 packages** vs. a
stock desktop's several thousand, and **~2 processes at idle** instead of a
dozen.

**"Why interim instead of LTS?"** LTS releases stay on old software for 5+
years. The interim cadence (every 6 months) brings current kernels, drivers,
and Wayland compositors — especially relevant for niri and the NVIDIA driver,
which improve fast. `Prompt=normal` in `/etc/update-manager/release-upgrades`
is the single switch that makes this work.

**"Why hand-write a quickshell bar instead of using waybar?"** Waybar on
Wayland needs a separate IPC daemon, a window layer, and config duplication.
Quickshell gives us one process rendering both bars, a launcher, and the tray —
all in one readable QML file (~990 lines) with niri's IPC built in.

**"Is this stable enough for daily use?"** Yes — niri is the most
feature-complete scrollable-tiling compositor and reloads configs live. The
main caveats are the known NVIDIA quirks (documented in [🎮 NVIDIA](#-nvidia))
and that the bar is a WIP (see [🚧 Work In Progress](#-work-in-progress)).

**"How do I get audio back?"** `sudo apt install -y pipewire pipewire-pulse
wireplumber` — it was purged with the GNOME cleanup. Volume keys use `wpctl`.

**"How do I update everything?"** `nala update && nala upgrade` (weekly,
see [🧹 Maintenance](#-maintenance--service-inventory)). For the distro
itself: `sudo do-release-upgrade` every 6 months.

**"How do I reset back to a clean server?"** The [📜 Provisioning & Baseline](#-provisioning--baseline)
section has the exact reset commands.

---

## ℹ️ Quick facts

| | |
|---|---|
| 🖥️ **OS** | Ubuntu interim (non-LTS), 6-month cadence — fresh *minimized server* base |
| 📆 **Release plan** | `sudo do-release-upgrade` to the next interim release every 6 months (see [🚧 Work In Progress](#-work-in-progress)) |
| 🪟 **Compositor** | niri — scrollable-tiling, pure Wayland |
| 🧱 **Shell** | hand-written quickshell (~990 lines): top bar = workspaces · net/mem/cpu · kbd · date/clock · tray; bottom bar = launcher · window taskbar |
| 💻 **Terminal** | Ghostty (native Wayland) |
| 🚀 **Launcher** | quickshell popup (Mod+R) + fuzzel fallback (Mod+D) |
| 🌍 **Browser** | Helium — Chromium fork, real `.deb`, no snap |
| 🖥️ **Display stack** | pure Wayland, no X11 apps, no desktop environment |
| 🎯 **Policy** | only necessary packages; no third-party configs or shells |
