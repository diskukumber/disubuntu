# 🐧 disubuntu · Ubuntu interim

An **Ubuntu interim-based setup, lean by design** — a pure-Wayland desktop on
**KDE Plasma 6** (minimal, full-functional core: exactly four KDE apps —
dolphin, konsole, kdeconnect, ark — no indexers, no snaps) that gets
refreshed on the **6-month interim release cadence**.

| Summary | |
|---|---|
| 🖥️ **OS** | Ubuntu **26.04 LTS (Resolute)** → **26.10 (Stonking Stingray)** interim via `do-release-upgrade` — Server *minimized* base |
| 🪟 **Desktop** | [KDE Plasma 6](https://kde.org/plasma-desktop/) — **Wayland only** (`kwin_wayland`), full core: widgets, panels, settings — exactly four KDE apps: dolphin + konsole + kdeconnect + ark |
| 🗂️ **Tiling** | **Kröhnkite** (dynamic tiling KWin script, only third-party component) + native KWin tiling fallback |
| 🔥 **Firewall** | firewalld + plasma-firewall KCM (`public` zone, `ssh`+`dhcpv6-client`) · firmware via fwupd |
| 🔑 **Login** | [SDDM](https://github.com/sddm/sddm) (breeze theme) — native Plasma display manager |
| 🎨 **GPU** | Intel UHD (iGPU, panel + scanout) + NVIDIA RTX 2060 (dGPU, renders via modeset=1 set in `/etc/modprobe.d`) |

---

## 📑 Table of Contents

| Section | Covers |
|---|---|
| [📸 Screenshots](#-screenshots) | how screenshots are taken & where they land |
| [📥 Installation](#-installation) | the full path: minimized server ISO → strip to a pure base → interim cadence → minimal Plasma → every package, in order |
| [🖥️ Hardware](#-hardware) | the machine: CPU, RAM, storage, dual-GPU hybrid graphics |
| [🧩 Software stack & package inventory](#-software-stack--package-inventory) | the diagram, who does what, every package, process count |
| [🚀 Session Startup](#-session-startup) | SDDM → Plasma (Wayland) boot chain |
| [🎛️ KWin & Plasma Configuration](#-kwin--plasma-configuration) | kwinrc, panels, shortcuts — section by section (incl. Kröhnkite tiling) |
| [⌨️ Key Bindings](#-key-bindings) | the KDE default + custom cheat sheet (incl. Kröhnkite) |
| [🎮 NVIDIA](#-nvidia) | driver, modeset, VRAM fix, groups, diagnostics |
| [🛠️ Troubleshooting & Known Issues](#-troubleshooting--known-issues) | symptom→fix table, logs, recovery recipes |
| [🧹 Maintenance & Service Inventory](#-maintenance--service-inventory) | services, dotfiles, routine care, reset |
| [🤖 setup.sh](#-setup-sh) | the plain-bash installer (no gum) — `bash setup.sh --check` |
| [❓ FAQ](#-faq) | quick answers: why interim, how to update/reset |

---

## 📸 Screenshots

Screenshots use **KDE Spectacle** (small, native Wayland):

| Keys | What it captures |
|---|---|
| `Print` | interactive: area / screen / window picker |
| `Shift+Print` | full screen (immediate) |
| `Alt+Print` | focused window |

Saved to `~/Pictures/Screenshots/` (configurable in Spectacle settings).

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

---

### 2️⃣ What the minimal install comes with — the full inventory

The **"Minimized"** profile installs exactly two sources of packages:

| Source | What it is |
|---|---|
| `ubuntu-server-minimal` metapackage | **27 direct deps** + 4 Recommends (installed alongside) — the base system *plus* the Canonical/server extras below |
| installer base layer | kernel, bootloader, SSH, locales + a few server leftovers (modemmanager, avahi, …) |

Every package that lands on a fresh install is in the tables below, grouped
with a verdict. What's marked ❌ is the Canonical/server stuff this setup
purges in step 3.

> [!NOTE]
> **What "Canonical extras" / "snap" means:** things Canonical ships for
> cloud/enterprise/telemetry that a personal laptop never uses — `snapd` (the
> snap packaging framework), `cloud-init` (cloud provisioning), `apport`
> (crash reporting), `pollinate` (entropy seeding). None serve a bare-metal
> workstation. Purging them leaves a base that is only systemd + coreutils +
> apt — every daemon after that is one *we* chose.

**🧱 Boot & storage stack — keep forever:**

| Package | What it is | Verdict |
|---|---|---|
| `linux-generic` | the kernel | ✅ keep |
| `grub-efi-amd64` + `shim-signed` | bootloader + Secure Boot | ✅ keep |
| `cryptsetup` · `lvm2` · `mdadm` | disk encryption / LVM / RAID tools | ✅ keep (tiny; the installer uses them) |

**📦 Base system — the clean core:**

| Package | What it is | Verdict |
|---|---|---|
| `apt` | package manager | ✅ keep |
| `systemd` + `systemd-sysv` + `systemd-resolved` | the service manager + DNS resolver | ✅ keep |
| `dbus` · `udev` | IPC bus · device management | ✅ keep |
| `sudo` / `sudo-rs` | privilege elevation | ✅ keep |
| `apparmor` | mandatory access control | ✅ keep |
| `chrony` | time sync | ✅ keep |
| `netbase` · `e2fsprogs` · `xfsprogs` · `btrfs-progs` · `bcache-tools` | network + filesystem base | ✅ keep |
| `locales` · `nano` · util-linux/coreutils set | base userland | ✅ keep |
| `openssh-server` | headless access | ✅ keep (remove only if you never SSH in) |
| `hwctl` · `needrestart` · `unattended-upgrades` | hardware probing · restart reminders · auto security updates | ✅ keep |
| `ubuntu-drivers-common` (+ `gpu-manager`) | GPU driver handling + detection | ✅ keep |
| `ubuntu-release-upgrader-core` | the distro upgrader — **required for step 4** (interim cadence) | ✅ keep |

**🔴 Canonical extras — purge (step 3):**

| Package | What it is | Why remove |
|---|---|---|
| `snapd` (+ `snapd.socket`) | the snap packaging framework | 7 daemons for 0 snaps |
| `cloud-init` | cloud provisioning | unused on bare metal (5 services) |
| `apport` (+ `apport-core-dump-handler`, `apport-symptoms`) | crash reporting | useless on a personal machine |
| `kdump-tools` | kernel crash dumps | a laptop never crash-dumps to disk |
| `pollinate` | Canonical entropy seeding | cloud-image feature (may already be absent — harmless no-op) |
| `unminimize` | reverses the minimized image | we want to *stay* minimal |

**🔴 Server-image leftovers — purge (step 3):**

| Package | What it is | Why remove |
|---|---|---|
| `open-iscsi` | iSCSI SAN client | no SAN |
| `multipath-tools` | multipath storage | single NVMe |
| `modemmanager` | mobile-broadband modem daemon | no SIM slot |
| `lxd-installer` | LXD container wrapper | no containers |
| `avahi-daemon` | mDNS/Bonjour | nothing here uses it |
| `udisks2` | storage D-Bus daemon | no file manager needs it (note: *Plasma pulls it back — see step 5e*) |
| `networkd-dispatcher` | systemd-networkd event handler | we use NetworkManager, not networkd |

**🟡 Optional — your call (safe either way):**

| Package | Note |
|---|---|
| `thermald` | Intel thermal daemon — useful on a laptop, tiny; keep unless you want zero daemons |
| `accountsservice` | user-account D-Bus — Plasma uses it; keep |

---

### 3️⃣ Strip it down — no snaps, no Canonical, no server leftovers

Remove everything marked ❌ in step 2 so **nothing runs in the background**
beyond systemd, and no snap exists anywhere:

```bash
# 3a. Snap — completely gone (no daemons, no loop mounts, no /snap)
sudo apt-get purge -y snapd snapd.socket
sudo rm -rf /snap /var/snap /var/lib/snapd /root/snap /home/*/snap

# 3a'. Snap, permanently — pin snapd so apt can never pull it back as a dep
sudo tee /etc/apt/preferences.d/no-snap.pref > /dev/null <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
apt-cache policy snapd    # → Candidate: (none)

# 3b. Canonical extras — cloud provisioning, crash reporting, image helpers
sudo apt-get purge -y cloud-init pollinate unminimize \
  apport apport-core-dump-handler apport-symptoms kdump-tools
sudo rm -rf /etc/cloud /var/lib/cloud

# 3c. Server-image leftovers
sudo apt-get purge -y open-iscsi multipath-tools modemmanager lxd-installer \
  avahi-daemon udisks2 networkd-dispatcher

# 3d. Clean apt + journal caches
sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && sudo apt-get update
sudo journalctl --vacuum-size=200M

# 3e. Verify
snap --version          # should fail: command not found
systemctl list-unit-files --state=enabled --no-pager | wc -l   # baseline: ~33 services
```

After this the machine is a **pure minimal system** — systemd, kernel,
coreutils, apt. Everything else that runs later is something *we* added.

---

### 3f. De-brand — no Canonical/Ubuntu theming

The Ubuntu branding that survives the server base is **login-time only** — the
desktop itself is 100% native (Breeze Dark, no Canonical wallpapers, no Yaru,
no plymouth). What remains and how it's removed:

```bash
# SDDM's orphaned Ubuntu login theme — never active (/etc/sddm.conf: Current=breeze)
sudo rm -rf /usr/share/sddm/themes/ubuntu-theme

# MOTD at SSH/console login: Ubuntu ASCII logo, help text, news feed, notices
sudo chmod -x /etc/update-motd.d/00-header \
              /etc/update-motd.d/10-help-text \
              /etc/update-motd.d/50-motd-news \
              /etc/update-motd.d/60-unminimize \
              /etc/update-motd.d/91-release-upgrade

# Kill the Canonical news service at the source (config + timer)
sudo tee /etc/default/motd-news > /dev/null <<'EOF'
ENABLED=0
EOF
sudo systemctl disable --now motd-news.timer
```

**Kept on purpose** (functional, not theming): `/etc/os-release` +
`/etc/lsb-release` (required by `ubuntu-release-upgrader` for the interim
cadence), `85-fwupd` + `92-unattended-upgrades` MOTD notices (useful status).

---

### 4️⃣ Switch to the interim release cadence

The Ubuntu Server ISO installs an **LTS** by default. This setup runs the
**interim (non-LTS)** 6-month cadence instead:

```bash
# 4a. Tell the upgrader to chase interim releases, not LTS-to-LTS
sudo sed -i 's/^Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades

# 4b. Upgrade to the current interim release
sudo do-release-upgrade -d
sudo reboot
```

> [!NOTE]
> `Prompt=normal` is the *interim* mode. Verify after reboot:
> `cat /etc/os-release | grep VERSION_CODENAME` and repeat
> `do-release-upgrade` **every 6 months**.

---

### 5️⃣ What we add — every package, with a reason

**5a. Repositories:**

| Source | Provides | When |
|---|---|---|
| Ubuntu main/universe | base + most tools | preconfigured |
| `pkg.helium.computer/deb` | `helium-bin` browser (real .deb, no snap) | now |

```bash
# 5b. Add the browser repo
curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/helium.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/helium.list
sudo apt update
```

**5c. The stack — every package, grouped by purpose:**

```bash
# KDE Plasma 6 — the full functional desktop core (no apps, no bloat Recommends)
sudo apt install -y --no-install-recommends \
  plasma-desktop plasma-session-wayland kwin-wayland \
  sddm sddm-theme-breeze kde-config-sddm \
  systemsettings kscreen kio-extras kde-cli-tools \
  powerdevil plasma-nm plasma-pa ksshaskpass \
  polkit-kde-agent-1 breeze breeze-gtk-theme \
  xdg-desktop-portal-kde kde-config-gtk-style \
  kde-config-screenlocker kactivitymanagerd kmenuedit \
  kde-spectacle kinfocenter

# The two KDE apps: file manager + terminal (metapackage-free)
sudo apt install -y --no-install-recommends dolphin konsole

# Terminal + clipboard + launcher extras
sudo apt install -y wl-clipboard

# System monitor daemon (panel CPU/Memory applets)
sudo apt install -y ksystemstats

# Audio (pipewire + plasma-pa volume control)
sudo apt install -y pipewire pipewire-pulse wireplumber

# Network (if not already enabled by the installer)
sudo apt install -y network-manager wpa_supplicant

# Fonts (Plasma + terminal + emoji)
sudo apt install -y fonts-inter fonts-jetbrains-mono \
  fonts-noto-core fonts-noto-color-emoji

# NVIDIA desktop driver (replaces the server variant)
sudo apt install -y nvidia-driver-595

# Browser (real .deb, no snap)
sudo apt install -y helium-bin

# Security: firewall (firewalld + Plasma KCM) + firmware updates (fwupd)
sudo apt install -y firewalld plasma-firewall fwupd

# Dynamic tiling (KWin script installer)
sudo apt install -y kpackagetool6

# Phone integration (KDE Connect) + archive manager (Ark)
sudo apt install -y --no-install-recommends kdeconnect ark
```

**KDE Connect firewall rule** — without it the phone pair/transfer silently
fails (firewalld blocks 1714–1764 by default; firewalld ships a ready service
definition):

```bash
sudo firewall-cmd --permanent --add-service=kdeconnect
sudo firewall-cmd --reload
```

**What the `--no-install-recommends` intentionally leaves out** (bloat or
backends we don't have): `plasma-discover` (app store), `plasma-browser-integration`,
`plasma-vault` (needs cryfs), `plasma-thunderbolt`,
`bluedevil` (no bluez), `plasma-disks` (needs udisks2), `khelpcenter`, `kgamma`,
plus the rest of the KDE app suite (`kde-baseapps`: kate, gwenview, elisa…).
`setup.sh` is plain bash — no `nala`, no `gum`; plain apt is the package
manager. No kwin-x11 — **Wayland only**, no X session.

> [!NOTE]
> **What about X on disk?** `xserver-xorg-core` *is* installed — as an
> **unavoidable hard-dependency** of the NVIDIA driver (`nvidia-driver-595` →
> `xserver-xorg-video-nvidia-595` → `xserver-xorg-core`). It never runs (no
> `Xorg` process, ever). `Xwayland` also ships and runs **rootless** as KWin's
> default for legacy apps — kept by choice; only KDE's own tray bridges
> (`xembedsniproxy`, `gmenudbusmenupr`) run on it, no user apps
> (helium/konsole are Wayland-native).

> [!NOTE]
> **`udisks2` returns as a hard dep of `plasma-workspace`** (removable-media
> support). It is a dormant D-Bus-activated daemon here: `systemctl disable
> udisks2` keeps it from running at boot; it starts on demand the moment
> something mounts a drive. Best of both — no idle daemon, full function.

> [!NOTE]
> **Indexer: installed with dolphin, disabled.** The `baloo6` daemon comes
> back as a **hard dep of `dolphin`**. It is **disabled**
> (`balooctl6 disable`) — Plasma runs with zero file-indexing in the
> background.

**5d. What each package does** — see the purpose tables in
[🧩 Software stack & package inventory](#-software-stack--package-inventory).

**5e. Post-install cleanup — the `udisks2` daemon:**

```bash
# Dormant-at-idle: disabled at boot, D-Bus starts it on demand (drive mounts)
sudo systemctl disable udisks2
```

**5f. Post-install — zero background indexing:**

```bash
balooctl6 disable   # dolphin's hard dep baloo6 — keep zero background indexing
```

`dolphin` = the file manager (`Meta+E`); `konsole` = the terminal
(`Meta+Return`, second via `Ctrl+Alt+T`).

**Konsole profile:** `disubuntu.profile` + `disubuntu.colorscheme` live in
`home/.local/share/konsole/` — JetBrains Mono 11pt, Breeze-Dark-tuned
palette (bg `#202326`), **15% translucent + blur** so the wallpaper shows
through. `konsolerc` pins `DefaultProfile=disubuntu.profile`.

---

### 6️⃣ NVIDIA driver follow-up (required after step 5)

```bash
# modeset=1 is ALREADY active — the nvidia-driver-595 package ships
# /etc/modprobe.d/nvidia-graphics-drivers-kms.conf with `options nvidia_drm
# modeset=1`. Only the user groups are needed here:
sudo usermod -aG video,render $USER
```

> [!IMPORTANT]
> Apply the VRAM heap reuse fix (Step 2 in [🎮 NVIDIA](#-nvidia)) — the
> process-name profile must match `kwin_wayland`.

---

### 7️⃣ Config files (all ours, tracked in this repo)

| File | What it is |
|---|---|
| `~/.bash_aliases` | **in this repo** (`home/.bash_aliases`) — plain-apt aliases (`i/r/s/u/up`) |
| `~/.config/kwinrc` | compositor settings (effects, animations, window rules) — **in repo** (`home/.config/kwinrc`) |
| `~/.config/kwinrulesrc` | global `noborder` window rule (borderless) — **in repo** |
| `~/.config/plasma-org.kde.plasma.desktop-appletsrc` | panel layout + widgets — **in repo** |
| `~/.config/plasmashellrc` | shell settings — **in repo** |
| `~/.config/kglobalshortcutsrc` | key bindings — **in repo** |
| `~/.config/kdeglobals` | colors, fonts, icons, cursor — **in repo** |
| `~/.config/gtk-3.0/` + `~/.config/gtk-4.0/` | GTK theme (Breeze-Dark + Inter) — **in repo** |
| `~/.config/powermanagementprofilesrc` | power/backlight behavior — **in repo** |
| `~/.config/konsole/` + `~/.local/share/konsole/` | terminal — `disubuntu` profile + colorscheme **in repo** (`home/.local/share/konsole/`) + `konsolerc` |

> [!NOTE]
> **All configs are tracked in this repo** (`home/` mirrors `~`). They are
> plain copies — edit on the machine, then copy back into the repo and
> `git push` to keep the backup current. Secrets (SSH keys, keyrings) stay
> out of the repo by design.

---

### 8️⃣ Rebuilding from scratch checklist

- [ ] Install **Ubuntu Server "Minimized"** from the ISO
- [ ] Run step 3 (purge snaps/cloud/leftovers) + step 3f (de-brand) + step 4 (interim cadence)
- [ ] Add the helium repo (step 5b)
- [ ] Install all packages from step 5c (plain apt — no nala, no gum)
- [ ] `balooctl6 disable` + `sudo systemctl disable udisks2` (steps 5e/5f)
- [ ] NVIDIA VRAM fix JSON with `kwin_wayland` (see [🎮 NVIDIA](#-nvidia)) + `sudo usermod -aG video,render $USER`
- [ ] Install the Kröhnkite artifact from `vendor/krohnkite/` (`kpackagetool6 -t KWin/Script -i`) + enable
- [ ] Borderless windows come from tracked config alone — `kwinrc` (`theme=Breeze`, `BorderlessMaximizedWindows=true`) + `kwinrulesrc` (global `noborder` rule); nothing to install
- [ ] Enable + start `firewalld`, allow `ssh`; `systemctl enable --now fwupd` + `fwupdmgr refresh`
- [ ] Copy configs from this repo (step 7 — incl. the `disubuntu` Konsole profile)
- [ ] Reboot → SDDM → log in → Plasma (Wayland)
- [ ] `pgrep -a kwin_wayland` + `pgrep -a plasmashell` → desktop up

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
| Displays | 🖥️ **eDP-1** (built-in BOE panel, 1920×1080 @ **120 Hz**) · 🖥️ **HDMI-A-4** (Sharp TV, 1920×1080 @ **60 Hz** — forced over its 50 Hz preferred mode) |

### 🖥️ Displays (configured in System Settings → Display / `kscreen-doctor`)

| Output | Mode | Position | Notes |
|---|---|---|---|
| `eDP-1` (BOE panel) | `1920x1080@120.002` | primary | the main screen |
| `HDMI-A-4` (Sharp TV) | `1920x1080@60.000` | right of panel | TV prefers 50 Hz; 60 Hz forced for a smoother desktop |

Find your modes/positions anytime with `kscreen-doctor -o`.

### 🎛️ The two GPUs

```
00:02.0 VGA compatible controller: Intel Corporation CometLake-H GT2 [UHD Graphics]
01:00.0 VGA compatible controller: NVIDIA Corporation TU106M [GeForce RTX 2060 Mobile]
```

| GPU | Device | Role |
|---|---|---|
| 🟦 **Intel UHD Graphics (iGPU)** | `/dev/dri/card0` | integrated, low power, no proprietary driver; the eDP panel is physically wired to it, so it *always* does the display output + scanout |
| 🟩 **NVIDIA RTX 2060 Mobile (dGPU)** | `/dev/dri/card1` | 6 GB VRAM, more powerful; KWin renders on it (`nvidia-smi` shows `kwin_wayland` with a context) while the iGPU scans out |

### 🔀 How the graphics stack is wired (PRIME / hybrid)

```
Applications (Konsole, plasmashell, etc.)
        │  Vulkan/OpenGL/EGL
        ▼
   KWin (compositor) ── renders on the NVIDIA GPU (modeset=1, GBM/EGL)
        │
        ▼
   Intel iGPU ── scans out to the laptop screen (eDP)
```

> [!NOTE]
> **How modeset=1 gets here:** the `nvidia-driver-595` package ships
> `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf` with
> `options nvidia_drm modeset=1` — so **modesetting IS active**
> (`/sys/module/nvidia_drm/parameters/modeset` → `Y`) with **no**
> `/etc/default/grub` edit needed (that file doesn't even exist on this
> machine). A grub cmdline entry is only needed to push the flag into the
> initramfs early (NVIDIA console output before boot) — an optional extra:
>
> ```bash
> sudoedit /etc/default/grub        # GRUB_CMDLINE_LINUX_DEFAULT += nvidia-drm.modeset=1
> sudo update-grub
> sudo reboot
> ```

### 🛠️ Hardware commands

| Command | What it shows |
|---|---|
| `lspci \| grep -iE "vga\|3d"` | both GPUs on the PCI bus |
| `nvidia-smi` | NVIDIA GPU status, VRAM, processes |
| `ls /dev/dri/` | render devices (`card0`=Intel, `card1`=NVIDIA) |
| `kscreen-doctor -o` | outputs, modes, positions |

---

## 🧩 Software stack & package inventory

What runs, what each piece does, and every installed package by category.

> [!NOTE]
> 📊 **Snapshot:** **1,468 packages** installed, **89 manually installed**,
> **29 enabled services** (+ the Kröhnkite KWin script; fwupd is
> socket-activated with an enabled `fwupd-refresh.timer`). Regenerate the
> lists anytime:
>
> ```bash
> apt-mark showmanual | sort > /tmp/manual-packages-current.txt
> dpkg-query -W -f='${Package} ${Version}\n' | sort > /tmp/all-installed.txt
> systemctl list-unit-files --type=service --state=enabled --no-pager | \
>   grep enabled | awk '{print $1}' | sort > /tmp/enabled-services.txt
> ```

### 🗺️ The whole setup, one diagram

```
┌───────────────────────────────────────────────────────────────┐
│  PLASMA DESKTOP (user-visible)                                │
│                                                               │
│  ┌───────────────────────────────┐  ┌────────────┐  ┌───────┐ │
│  │  plasmashell (1 process)      │  │  KRunner   │  │Konsole│ │
│  │  panels + widgets:            │  │  launcher  │  │terminal│ │
│  │  · top panel: apps · clock    │  │  (Meta)    │  └───────┘ │
│  │  · bottom panel: taskbar,     │  │            │            │
│  │    system tray (network,      │  │            │            │
│  │    audio, power), clipboard   │  └────────────┘            │
│  └───────────────────────────────┘                            │
│                                                               │
│  KWin (kwin_wayland) ── compositor: windows, effects,         │
│          notifications, screen locker, screen edges           │
├───────────────────────────────────────────────────────────────┤
│  SYSTEM SERVICES                                              │
│  SDDM (login) → Plasma session (Wayland)                      │
│  powerdevil (power/brightness) · kded6 · kactivitymanagerd    │
│  polkit agent · plasma-nm (NetworkManager applet)             │
├───────────────────────────────────────────────────────────────┤
│  GRAPHICS                                                     │
│  nvidia-driver-595 (dGPU render) + Intel iGPU (scanout)       │
│  Mesa (fallback GL) + Vulkan drivers                          │
└───────────────────────────────────────────────────────────────┘
```

### 👤 Who does what

| Job | Handled by | Why this choice |
|---|---|---|
| **Desktop shell** | **plasmashell** | panels, widgets, notifications, tray — Plasma's native shell |
| **Window management** | **KWin (Wayland)** + **Kröhnkite** | Plasma's compositor; dynamic tiling via the Kröhnkite KWin script (only third-party desktop component — see 🪟 Kröhnkite) |
| **App launcher** | **KRunner** (`Meta`) | Plasma's built-in launcher + app search |
| **Screenshots** | **KDE Spectacle** | Plasma's native tool; `Print` family |
| **Status bar / tray** | plasmashell panels | native network (plasma-nm), audio (plasma-pa), power (powerdevil) applets |
| **Browser** | **Helium** (`helium-bin`, .deb repo) | Chromium fork with Chrome-extension support; real .deb, no snap |
| **Terminal** | **Konsole** | KDE Plasma default, Wayland native — `disubuntu` profile (JetBrains Mono 11, 15% translucent, blur) |
| **System monitor** | **ksystemstats** + native System Monitor applets | CPU + Memory widgets in the panel — no third-party widgets |
| **File manager** | **Dolphin** | `Meta+E`; uses the dormant `udisks2` for mounting |
| **Phone integration** | **KDE Connect** (`kdeconnect`) | notifications, clipboard sync, file transfer, remote input — ports 1714–1764 open in firewalld (`kdeconnect` service) |
| **Archives** | **Ark** | zip/tar/7z/rar archive manager — opens in Dolphin |
| **Clipboard** | Plasma clipboard + **wl-clipboard** | both installed; plasma's clipboard has history |
| **Backlight keys** | **powerdevil** | Plasma's power management handles brightness natively |
| **Audio** | **pipewire + wireplumber + plasma-pa** | volume keys in KWin |
| **Login** | **SDDM** | Plasma's native display manager; breeze theme |
| **Firewall** | **firewalld** + **plasma-firewall** KCM | host firewall, `public` zone on WiFi, `ssh`+`dhcpv6-client` allowed; configured in System Settings → Firewall |
| **Firmware updates** | **fwupd** (`fwupdmgr`) | LVFS firmware metadata + updates |
| **Desktop GPU** | **nvidia-driver-595** | see [🎮 NVIDIA](#-nvidia) |

### 🚫 What is intentionally NOT here

| Not installed | Why we skip it |
|---|---|
| Rest of the KDE app suite (`kde-baseapps`: kate, gwenview, elisa, …) | Plasma is the desktop, not an app bundle — dolphin/konsole/helium cover the needs |
| `plasma-discover` | GUI app store — we use plain `apt` |
| `nala` · `gum` | third-party helpers — plain apt covers everything |
| `baloo` indexer daemon | **installed as a dolphin hard-dep, but disabled** (`balooctl6 disable`) — zero background indexing |
| `kwin-x11` | **not installed** — the X11 compositor is gone; KWin runs Wayland only |
| `xserver-xorg-core` | present **as the NVIDIA driver's hard-dep** (`xserver-xorg-video-nvidia-595`); never runs, no X session |
| `Xwayland` | runs **rootless** (KWin default) — only KDE's tray bridges (`xembedsniproxy`, `gmenudbusmenupr`) use it; all user apps are Wayland-native |
| Full X session / X11 apps | pure Wayland provides everything we need |
| Snaps, cloud-init, apport, GNOME leftovers | the base rules from step 3 |

### 📦 Package inventory (the part that matters)

**Plasma core (hand-picked, no Recommends bloat)**

| Package | Purpose |
|---|---|
| `plasma-desktop` (+ `plasma-workspace`) | the desktop shell — panels, widgets, KCMs |
| `kwin-wayland` + `plasma-session-wayland` | the compositor + Wayland session files |
| `sddm` + `sddm-theme-breeze` + `kde-config-sddm` | login manager + theme + settings KCM |
| `systemsettings` | the control center |
| `kscreen` | display configuration |
| `powerdevil` | power profiles + backlight control |
| `plasma-nm` | NetworkManager system-tray applet |
| `plasma-pa` | audio applet (needs pipewire) |
| `kde-spectacle` | screenshots |
| `kio-extras` · `kde-cli-tools` | file-dialog + command-line plumbing |
| `ksshaskpass` · `polkit-kde-agent-1` | SSH/polkit prompts |
| `breeze` + `breeze-gtk-theme` + `kde-config-gtk-style` | theme + GTK integration |
| `xdg-desktop-portal-kde` | Wayland portals (screen sharing, file dialogs) |
| `kde-config-screenlocker` · `kactivitymanagerd` · `kmenuedit` | lock screen · activities · menu editor |
| `kinfocenter` | system info |

**The rest of the stack**

| Package | Purpose |
|---|---|
| `konsole` | terminal emulator (default) — `disubuntu` translucent profile |
| `ksystemstats` | system-stats daemon backing the panel's CPU/Memory monitor applets |
| `dolphin` | file manager (`Meta+E`) |
| `kdeconnect` | phone integration — notifications, clipboard sync, file transfer (requires the firewalld `kdeconnect` service) |
| `ark` | archive manager — zip/tar/7z |
| `helium-bin` | the browser (real .deb) |
| `wl-clipboard` | `wl-copy` / `wl-paste` |
| `gh` · `git` | GitHub CLI + version control |
| `qml6-module-qtquick-layouts` | Qt6 QML module — **required by the Plasma stack** (removing it pulls out plasma-desktop; kept) |
| `software-properties-common` | `add-apt-repository` (used for the helium repo) |
| `pipewire` + `pipewire-pulse` + `wireplumber` | audio |
| `nvidia-driver-595` + stack | dGPU driver (see [🎮 NVIDIA](#-nvidia)) |
| fonts: inter, jetbrains-mono, noto-core, noto-color-emoji | UI + terminal + emoji |

### 🔢 Process count at idle

| Process | Count | What it is |
|---|---|---|
| `kwin_wayland` (+ wrapper) | 2 | the compositor |
| `Xwayland` + tray bridges (`xembedsniproxy`, `gmenudbusmenupr`) | 3 | rootless X server, KWin default — only KDE's legacy-tray bridges run on it |
| `plasmashell` | 1 | the whole UI (panels + widgets + tray) |
| `kded6` + `kactivitymanagerd` | 2 | Plasma service daemons |
| `polkit-kde-authentication-agent-1` | 1 | privilege prompts |
| `powerdevil` | 1 | power management |
| `xdg-desktop-portal*` (kde + document + permission) | 2-3 | portals |
| `pipewire` + `pipewire-pulse` + `wireplumber` | 3 | audio |
| `ksystemstats` | 1 | system-monitor daemon (panel CPU/Memory applets) |
| `kdeconnectd` | 1 | KDE Connect daemon (phone pairing, file transfer) |
| **total** | **~32** | session processes with the browser closed (systemd on top); ~76 with Helium + its crashpad open |

That's the honest cost of a full desktop: **~32 session processes at idle**
(including Plasma's own helper daemons — kwalletd6, ksecretd, gnome-keyring,
at-spi a11y, dconf, the two Xwayland tray bridges, plus KWin's rootless
Xwayland) — in exchange for the complete, supported Plasma feature set
(settings, widgets, lock screen, power, network, audio).

---

## 🚀 Session Startup

No GUI display manager bloat — just **SDDM**, Plasma's own lightweight login
manager, and the Wayland session.

### 🥾 Boot order

1. **Ubuntu boots** → SDDM takes over a VT
2. **SDDM** shows the login screen (breeze theme)
3. After login, SDDM starts: **`plasma-session` (Wayland)**
4. `plasma-session` starts `kwin_wayland` (the compositor) → `plasmashell` → plasma-nm/plasma-pa/powerdevil applets
5. ✅ **Desktop is up** — panels + widgets + tray

### 🗂️ Where the pieces live

| Piece | File |
|---|---|
| SDDM config | `/etc/sddm.conf.d/10-plasma.conf` (breeze, Wayland, numlock) |
| SDDM service | `sddm.service` (system) |
| session files | `/usr/share/wayland-sessions/plasma.desktop` |
| compositor config | `~/.config/kwinrc` |
| shell config | `~/.config/plasmashellrc` + `plasma-org.kde.plasma.desktop-appletsrc` |

### 🤔 Why SDDM instead of GDM?

| Option | Why not / why yes |
|---|---|
| **GDM** | GNOME's DM — would pull GNOME dependencies |
| **SDDM** ✅ | Plasma's native DM — graphical login, breeze theme, `kde-config-sddm` settings KCM, screen-locker integration |

### ⚙️ Useful commands

| Command | What it does |
|---|---|
| `systemctl status sddm` | login manager status |
| `journalctl -u sddm -b` | login manager logs |
| `pgrep -a kwin_wayland` | compositor running? |
| `pgrep -a plasmashell` | shell running? |
| `plasmashell --replace` | restart the shell (fixes a broken panel) |
| `kscreen-doctor -o` | display status |

---

## 🎛️ KWin & Plasma Configuration

Config files in `~/.config/`. Everything is editable as plain text and live-
applies via System Settings; key files:

| File | Controls |
|---|---|
| `~/.config/kwinrc` | effects, animations, window rules, screen edges |
| `~/.config/kglobalshortcutsrc` | all key bindings |
| `~/.config/kdeglobals` | colors, fonts, icons, cursor |
| `~/.config/plasma-org.kde.plasma.desktop-appletsrc` | panels + widgets layout |
| `~/.config/plasmashellrc` | shell behavior |
| `~/.config/powermanagementprofilesrc` | power profiles |
| `/etc/sddm.conf.d/` | login screen settings (system config, not user) |

### 🖼️ Panels & widgets (the "bar")

One floating top panel (46px), configured in System Settings → Desktop:

- Left: **pager → global menu** · right (pushed by a spacer): **system tray → CPU → memory → clock**
  (System Monitor CPU/Memory applets, backed by the `ksystemstats` daemon —
  native, no third-party widgets)
- No app launcher and no task manager by design: `Meta` opens KRunner,
  `Meta+W` the Overview, `Meta+1…6` switch desktops, `Alt+Tab` switches
  windows, and Kröhnkite tiles everything anyway
- `Alt+F1` still opens the kickoff launcher for emergencies

Everything is movable: right-click a panel → Edit Mode. The layout lands in
`plasma-org.kde.plasma.desktop-appletsrc` and is backed up to this repo.

### 🪟 KWin — compositor

| Setting | What it does |
|---|---|
| Effects: blur, glide, fade, magic-lamp minimize, fall apart, scale, slide, dim-inactive, blend-changes | tuned in System Settings → Desktop Effects — all built-in, no wobbly windows |
| Window rules | none — Kröhnkite floats panels + polkit via `floatingClass`, dialogs float natively |
| Screen edges | corners → overview / desktop grid |
| Tiling | Kröhnkite owns tile drags (`BorderSnapZone=0` — KWin edge-snap off); native tiling layout system kept as fallback (`Meta+T`) |

### 🖱️ Focus, placement & animations

| Setting (`kwinrc`) | Value | Effect |
|---|---|---|
| `[Windows] FocusPolicy` | `FocusFollowsMouse` | hover activates a window — no click needed (the "tiling WM feel") |
| `[Windows] ActiveMouseScreen` | `true` | the screen under the pointer is the active one (pairs with `SeparateScreenFocus=true`) |
| `[Windows] Placement` | `Centered` | every new *floating* window opens centered — dialogs, polkit prompt, KRunner |
| `[Windows] BorderSnapZone` | `0` | KWin edge-snap off — drags belong to Kröhnkite's tile-swap |
| `[TabBox] MultiScreenMode` | `1` | **independent per-screen desktops** — switching on one monitor doesn't touch the other |
| `[KDE] AnimationDurationFactor` | `0.5` | snappy 2×-speed animations |
| `[Plugins]` minimize/close | magic-lamp + fall-apart | smooth suck-into-panel minimize; subtle shatter on close — `squashEnabled=false` (the one that glitches under Kröhnkite) |

### 🪟 Kröhnkite — dynamic tiling

**The only third-party component in this setup.** Dynamic window tiling for
KWin — windows auto-arrange instead of overlapping; every new window splits
the focused one (binary tree by default).

| | |
|---|---|
| **Version** | `0.9.9.2` — pinned, artifact vendored in `vendor/krohnkite/krohnkite-0.9.9.2.kwinscript` (SHA256 `42f7f66531d366c74b5fc860381da3517ccb4cdccd1f80c122fcab6e9a8fcf7e`). 0.9.9.3-beta exists but is unstable; the TS6 source build is broken — use the release artifact |
| **Install** | `kpackagetool6 -t KWin/Script -i vendor/krohnkite/krohnkite-0.9.9.2.kwinscript`; enable via System Settings → Window Management → KWin Scripts (`krohnkiteEnabled=true` in `kwinrc`) |
| **Config** | `[Script-krohnkite]` in `~/.config/kwinrc` (tracked in this repo) |

Per-screen layout (stored in `screenDefaultLayout`): **binary tree**
(`btreelayout`) on both `eDP-1` (internal) and `HDMI-A-4` — native
`.25/.5/.25` KWin tiling is kept as a fallback.

| Option (kwinrc) | Value | Effect |
|---|---|---|
| `screenGap*` | `top 14`, others `10` | gaps around tiles (10px; top gap taller so tiles sit clear of the floating top panel) |
| `directionalKeyFocus` | `true` | `Meta+Arrow` moves focus between tiles |
| `keepTilingOnDrag` | `true` (default) | dragging a tiled window swaps tiles instead of floating it |
| `newWindowPosition` | `0` (default) | new windows split the focused tile |
| `floatingClass` | `plasmashell,,,org.kde.krunner,org.kde.plasmashell,org.kde.polkit-kde-authentication-agent-1` | panels, KRunner and the polkit prompt never get tiled |

> [!NOTE]
> `ignoreScreen` is **not used** — it matches *screen names* (eDP-1, …), not
> window classes, so it would be dead config. Panels/polkit float via
> `floatingClass` above; dialogs float via Kröhnkite's built-in `floatUtility`.

Known Plasma-6.6 quirks (see [🛠️ Troubleshooting](#-troubleshooting--known-issues)):
- **"Minimize all other windows"** is left **unbound** — it conflicts with
  Kröhnkite's focus handling.
- The default **Squash** minimize animation misbehaves under Kröhnkite;
  **Magic Lamp** is used instead (`magiclampEnabled=true`, `squashEnabled=false`).

### 🤝 Kröhnkite ⟷ KWin — the coexistence contract

Kröhnkite and KWin split the work explicitly so nothing fights:

| Concern | Owner | How |
|---|---|---|
| Auto-arrange tiled windows, layouts, focus | **Kröhnkite** | binary-tree layouts per screen |
| Where *floating* windows land | **KWin** | `Placement=Centered` — new floats open centered |
| Float-by-default (panels, KRunner, polkit prompt) | **Kröhnkite** | `floatingClass` + built-in `floatUtility`/`ignoreClass` (polkit is also a default ignore) |
| Drag-to-arrange tiles | **Kröhnkite** | tile-swap on drag — KWin edge-snap off (`BorderSnapZone=0`) so it never steals the drag |
| Window ops (close, fullscreen, peek, switch) | **KWin** | Plasma defaults |
| Custom `.25/.5/.25` native layouts | **KWin** (fallback) | `[Tiling]` sections kept; `Meta+T` editor still reachable |

**Binding arbitration** — KWin's binds that overlapped Kröhnkite's are
**unbound** in `kglobalshortcutsrc`: `Meta+Ctrl+arrows` (Switch One Desktop —
frees Kröhnkite Shrink/Grow), `Meta+arrows` (Quick Tile — frees directional
focus), `Meta+Shift+Left/Right` (Move to Screen — frees Move window).
KDE's own binds keep their Plasma meaning: `Meta+D` (show desktop), `Meta+T`
(edit tiles), `Meta+L` (lock session), `Alt+Tab` (walk windows).

### 🪞 Window decoration — no titlebars, fully native

Windows have **no titlebar or frame**: stock **Breeze** decoration plus a
native KWin window rule (`home/.config/kwinrulesrc`) matching every window
(`wmclassmatch=3`, unimportant) with `noborder=true` (Force), so the whole
desktop is borderless — zero third-party decoration code.

- **Active-window indication**: KWin's `diminactive` effect is on
  (`diminactiveEnabled=true` in `kwinrc`), so the active window reads clearly
  against dimmed inactive ones.
- **Maximized windows** additionally drop the frame natively via
  `BorderlessMaximizedWindows=true` (`[Windows]` in `kwinrc`) — belt and
  suspenders on top of the global rule.
- `kdeglobals` pins `ColorScheme=Adaptive`; fonts are **Inter** + **JetBrains
  Mono**, animations at 0.5× speed.
- The frame is gone entirely (no accent-colored edge); if you ever want a
  framed look again, delete `kwinrulesrc` and switch `theme=` back to
  `Breeze` with a titlebar.
- GTK apps get the same frameless look via `kde-config-gtk-style`
  (`window-decorations-gtk-module` in `gtk-3.0/settings.ini`, tracked in repo).
  Qt/GTK look-and-feel is consistent: `gtk-theme-name=Breeze-Dark` in both
  `gtk-3.0/` and `gtk-4.0/settings.ini`, breeze-dark icons, Inter font.

### 🚀 Startup

Autostart apps: System Settings → Autostart (adds entries to `~/.config/autostart/`).

---

## ⌨️ Key Bindings

> [!TIP]
> **KDE default bindings** (customize anytime in System Settings → Shortcuts;
> they live in `~/.config/kglobalshortcutsrc`).

### 🚀 Apps & system

| Keys | Action |
|---|---|
| `Meta` | KRunner launcher |
| `Meta+Space` (or `Meta+R` / `Alt+F2`) | KRunner launcher |
| `Meta+Return` (or `Ctrl+Alt+T`) | Konsole (terminal) |
| `Meta+S` | Spectacle interactive region screenshot |
| `Print` / `Shift+Print` / `Alt+Print` | Spectacle defaults: full screen / region / window |
| `Meta+E` | dolphin file manager |
| `Meta+W` | Overview |
| `Ctrl+Esc` | system activity |

### 🪟 Windows

| Keys | Action |
|---|---|
| `Alt+Tab` / `Meta+Tab` | switch windows |
| `Alt+Shift+Tab` / `Meta+Shift+Tab` | …backwards |
| `Meta+Q` | close window |
| `Meta+F` | fullscreen |
| `Meta+PgUp` / `Meta+PgDown` | maximize / minimize |
| `Meta+Ctrl+Shift+arrows` | move window to another desktop |
| `Alt+F3` | window operations menu (move to desktop, more) |
| `Meta+D` | peek at desktop |
| `Meta+G` | grid view |
| `Meta+1` … `Meta+6` | switch to desktop 1–6 |
| `Meta+Shift+1` … `Meta+Shift+0` | move window to desktop 1–10 |
| `Meta+W` | overview |

> [!TIP]
> `Meta+N` is desktop **switching**, not task-manager entry activation — the
> default Plasma `Meta+1…9` task-manager binds are unbound (re-enable in
> System Settings → Shortcuts if wanted).

### 🪟 Kröhnkite (dynamic tiling)

> [!NOTE]
> KDE's own binds that overlap Kröhnkite's defaults keep their Plasma
> meaning — KWin registered them first. `Meta+D` (show desktop), `Meta+T`
> (edit tiles) and `Meta+L` (lock session) stay KDE's; the matching
> Kröhnkite actions stay unbound. Everything else is Kröhnkite's:

| Keys | Action |
|---|---|
| `Meta+Left` / `Right` / `Up` / `Down` | focus left / right / up / down |
| `Meta+,` / `Meta+.` | focus previous / next |
| `Meta+Shift+arrows` | move window left / right / up / down |
| `Meta+Ctrl+Left` / `Right` / `Up` / `Down` | shrink width / grow width / shrink height / grow height |
| `Meta+I` | increase ratio |
| `Meta+\,` / `Meta+\` | focus previous window / next layout |
| `Meta+Shift+Space` / `Meta+Shift+F` | toggle float (window) / float all |
| `Meta+Shift+R` | rotate part (rotate is unbound — `Meta+R` is KRunner) |
| `Meta+M` | monocle layout |
| `Meta+Shift+Return` | set master (remapped from the default `Meta+Return`) |

> [!NOTE]
> `Meta+Space` was freed from Kröhnkite's toggle-float (now
> `Meta+Shift+Space`) so KRunner could take it.

All bindings live in `kglobalshortcutsrc` under `[kwin]` (`Krohnkite*`,
tracked in this repo) and are configurable in System Settings → Shortcuts.

### 🔊 Audio & brightness

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume/Lower` | volume ± (plasma-pa) |
| `XF86AudioMute` | mute |
| `XF86AudioNext/Prev/Play/Pause` | media control (KWin MPRIS) |
| `XF86MonBrightnessUp/Down` | brightness ± (powerdevil) |
| `XF86Display` | display config (kscreen) |

### 🔒 Session

| Keys | Action |
|---|---|
| `Meta+L` | lock screen (kscreenlocker) |
| `Meta+Shift+Q` (or `Ctrl+Alt+Del`) | logout — session menu |
| `Ctrl+Alt+F2` | TTY escape hatch |

> [!TIP]
> The fastest way to check what's bound: System Settings → Shortcuts — it
> reads live from the config files this repo tracks.

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
| GL/EGL display stack | `libnvidia-gl-595` | KWin + apps render on the dGPU |
| `nvidia-smi` | `nvidia-utils-595` | monitoring, verification |
| Firmware (GSP for Turing+) | `nvidia-firmware-595` | RTX 2060 is Turing (TU106) |

Verify after install:

```bash
nvidia-smi          # must print a driver table
lsmod | grep nvidia # nvidia, nvidia_drm, nvidia_modeset loaded
```

### 1️⃣ Step 1 — kernel command line: `nvidia-drm.modeset=1` *(already active via modprobe.d)*

> [!NOTE]
> **Status: already on.** The `nvidia-driver-595` package ships
> `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf` (`options nvidia_drm
> modeset=1`) — `/sys/module/nvidia_drm/parameters/modeset` → `Y`. No grub
> edit was ever needed. The classic grub-cmdline route below is only the
> optional early-initramfs variant (NVIDIA console output before boot).

```bash
sudoedit /etc/default/grub
# → GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1"
sudo update-grub
sudo reboot
```

Verify (no reboot needed for the modprobe.d route):

```bash
cat /sys/module/nvidia_drm/parameters/modeset   # should print Y
```

### 2️⃣ Step 2 — VRAM heap reuse fix (required, do not skip)

> [!IMPORTANT]
> The NVIDIA driver has a quirk: compositors that recycle buffers cause the
> driver to hoard VRAM (**1 GiB+** instead of ~100 MiB). The fix is a
> per-process application profile. **The process name must match the
> compositor — `kwin_wayland`.**

```bash
sudo mkdir -p /etc/nvidia/nvidia-application-profiles-rc.d
sudo tee /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json > /dev/null <<'EOF'
{
  "rules": [
    {
      "pattern": { "feature": "procname", "matches": "kwin_wayland" },
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

Restart the session (or reboot) afterwards. Check with
`watch -n 2 nvidia-smi` — should stay near ~100 MiB.

### 3️⃣ Step 3 — user groups

```bash
sudo usermod -aG video,render diskukumber
```

### 🔀 How the two GPUs cooperate

| Piece | Role |
|---|---|
| **Intel iGPU** | the laptop panel (eDP) is wired to it — it always drives the panel (scanout) |
| **NVIDIA dGPU** | KWin renders on it (modeset=1 via modprobe.d, GBM/EGL); compute/games offload here |

This works **without any X11 config** — KWin handles multi-GPU natively.

### 🛠️ Diagnostic commands

| Command | What it tells you |
|---|---|
| `nvidia-smi` | status, VRAM, processes (`kwin_wayland` should appear) |
| `lsmod \| grep nvidia` | module state |
| `cat /sys/module/nvidia_drm/parameters/modeset` | `Y` = modesetting on (**currently Y** — via modprobe.d) |
| `dmesg \| grep -i nvidia` | kernel messages |
| `journalctl -b \| grep -iE "nvidia\|egl\|kwin"` | boot-log mentions |
| `ls /dev/dri/` | `card0` = Intel, `card1` = NVIDIA |

### ⚠️ Known quirks

| Quirk | Status |
|---|---|
| Screencast/window-capture on NVIDIA | works with `xdg-desktop-portal-kde` + KWin (GPU screen recording) |
| Suspend issues on some dual-GPU laptops | if suspend misbehaves: check `nvidia-smi` power state + kernel logs; a reboot usually clears it |
| VRAM heap | the profile must match the process name `kwin_wayland` **exactly** |

---

## 🛠️ Troubleshooting & Known Issues

### 🥇 Golden rules

| # | Rule | Why |
|---|---|---|
| 1 | **Everything logs somewhere** — check logs before touching anything | you avoid blind changes; the log usually names the exact cause |
| 2 | **Plasma reloads fast** — `plasmashell --replace` or re-login is usually enough | only kernel/driver changes need a reboot |
| 3 | **TTY rescue**: `Ctrl+Alt+F2` → log in → full terminal even if the desktop is dead | the escape hatch for every session-level problem |

### 🩺 Symptom → fix table

| Symptom | Likely cause → fix |
|---|---|
| Black screen after login | KWin failed to start. On tty2: `pgrep -a kwin_wayland`, `journalctl --user -b -e \| grep -i kwin`. See [🎮 NVIDIA](#-nvidia) notes. |
| Desktop works, no panels | `plasmashell --replace` from a terminal (or Alt+F2 → krunner → run command). |
| SDDM fails in a loop | `journalctl -u sddm -b -e`. Usually a bad session file or theme. `sudo systemctl restart sddm` after fixing the cause. |
| GPU fans spin, high idle power | `nvidia-smi` — check the dGPU isn't rendering when it shouldn't; VRAM fix missing? See [🎮 NVIDIA](#-nvidia). |
| ~1 GiB VRAM used by kwin_wayland | The GLVidHeapReuseRatio fix isn't applied or the process name changed. Re-check [🎮 NVIDIA](#-nvidia) Step 2 and restart the session. |
| Volume keys do nothing | `wpctl status` — is there a default sink? `systemctl --user status pipewire wireplumber`. plasma-pa applet present? |
| Brightness keys do nothing | powerdevil running? `systemctl --user status powerdevil`. |
| Screenshots save nowhere | `mkdir -p ~/Pictures/Screenshots`; check Spectacle settings. |
| Network applet missing | plasma-nm installed? `systemctl status NetworkManager`. |
| Apps look wrong / huge | Missing fonts → `fc-list \| grep Inter`; install `fonts-inter`. |
| Bluetooth audio glitches | `systemctl --user status pipewire wireplumber`; reboot if needed (bluez not installed). |
| Suspend/resume broken | Known hybrid-GPU quirk. `journalctl -b -1 \| grep -i nvidia`; reboot usually clears it. |
| Global shortcuts dead / `kglobalacceld` exits instantly | **Normal on Wayland, don't chase it.** `kglobalacceld` is a deliberate no-op when `XDG_SESSION_TYPE=wayland` (exits 0 silently, by design — see `src/main.cpp` upstream); **kwin_wayland itself provides `org.kde.kglobalaccel`**. Verify with `pgrep -a kwin_wayland` + `qdbus6 org.kde.kglobalaccel /kglobalaccel allMainComponents`, not the daemon. |

### ⚠️ Known issues

| Issue | Status / workaround |
|---|---|
| 💤 **Suspend/resume** can glitch on this dual-GPU laptop | a reboot usually clears it |
| 🎮 **NVIDIA VRAM heap quirk** (~1 GiB hoarded by compositors) | fixed by the application-profile JSON in [🎮 NVIDIA](#-nvidia); the profile must match `kwin_wayland` |
| 🐧 Some **X11 apps** may misbehave | they run under the rootless Xwayland (KWin default) automatically; native-Wayland apps (helium, konsole) are unaffected |
| 🔎 `baloo` indexer (dolphin's hard dep) | **disabled** — `balooctl6 disable`; re-enable anytime with `balooctl6 enable` |
| 🪟 **"Minimize all other windows"** (Plasma 6.6) conflicts with Kröhnkite | left **unbound** by design; don't bind it (breaks focus/tiling) |
| 🪟 **Squash minimize animation** glitches under Kröhnkite | use *None* or *Magic Lamp* as the minimize effect if windows animate oddly |
| 🔥 **Meta+D / Meta+T / Meta+L** don't tile (KDE won the conflict) | intentional — KDE's show-desktop / edit-tiles / lock-session keep those keys; Kröhnkite's versions stay unbound |
| ⚠️ **`kglobalacceld` can rewrite `kglobalshortcutsrc` while dying** | an X11-connected kglobalacceld that loses Xwayland during a `kwin_wayland --replace` flushes its in-memory state on exit — it can clobber recent binding changes. After any binding edit + kwin restart, re-`cp` the file into the repo |

### 🔬 Checking the whole stack at once

```bash
systemctl status sddm --no-pager | head -3
pgrep -a kwin_wayland
pgrep -a plasmashell
wpctl status | head -10
nvidia-smi | head -10
kscreen-doctor -o
```

### 📁 Log locations

| Component | Where |
|---|---|
| SDDM (login) | `journalctl -u sddm -b` |
| KWin (compositor) | `journalctl --user -b` (grep kwin) |
| plasmashell (panels) | `plasmashell --replace` in a terminal shows errors |
| pipewire / wireplumber | `journalctl --user -u pipewire -b`, `-u wireplumber` |
| kernel (drivers, GPUs) | `dmesg \| grep -iE "nvidia|drm|i915"` |

### 🧯 Recovery recipes

| Situation | The move |
|---|---|
| **Desktop frozen** | `Ctrl+Alt+F2` → log in on tty2 → `loginctl terminate-session $SESSION` or reboot |
| **Panels broken/disappeared** | `plasmashell --replace` (simpler: re-login) |
| **KWin crash loop** | on tty2: `journalctl --user -b -e`; disable the newest effect (kwinrc), re-login |
| **SDDM unresponsive** | `sudo systemctl restart sddm` from tty2 |

### ❓ Still stuck?

KDE userbase (<https://userbase.kde.org/>) and the Plasma docs
(<https://docs.kde.org/>), then **search the exact error line** from the logs.

---

## 🧹 Maintenance & Service Inventory

What's running, what can be trimmed, and the routine care this system needs.

### ⚙️ Service inventory (enabled, system — 29 currently)

**✅ Enabled now:** `NetworkManager` (+dispatcher/wait-online) · `chrony` ·
`systemd-resolved` · `systemd-networkd` (+wait-online, netplan-configure) ·
`apparmor` · `unattended-upgrades` · `thermald` · `gpu-manager` ·
`nvidia-powerd` (power management; suspend/resume/hibernate units ship but are
**not enabled**) · `wpa_supplicant` ·
`accounts-daemon` · `lvm2-monitor` · `blk-availability` · `console-setup` ·
`keyboard-setup` · `setvtrgb` · `e2scrub_reap` · `finalrd` · `grub2-common` ·
`grub-initrd-fallback` · `secureboot-db` · `systemd-pstore` · `getty@` · **`sddm`**

**⏸️ Dormant (not enabled — start on demand):**
`udisks2` (D-Bus, removable media — starts when something mounts a drive) ·
`upower` (D-Bus, battery backend for powerdevil) · `nvidia-persistenced`
(static — starts with the NVIDIA driver when the GPU is used)

**🗑️ Not installed (purged):** `cloud-init` · `snapd` · `apport` · `kdump-tools` ·
`pollinate` · `avahi-daemon` · `networkd-dispatcher` · `unminimize` ·
`nautilus`/`gvfs*` · `xdg-desktop-portal-gnome` · `evolution-data-server` ·
`localsearch` · `multipath-tools` · `open-iscsi` · `ModemManager` ·
`lxd-installer` · `bluez` (never installed) ·
`nala` · `gum` · `fonts-materialdesignicons-webfont`

**⛔ Installed but inert:** `baloo6` (dolphin hard-dep, disabled via
`balooctl6`) — the only daemon on disk that is intentionally off.

### 📄 Dotfiles & config inventory

| Path | Purpose |
|---|---|
| `~/.bashrc` | prompt, history, `ll/la/l` aliases, opencode PATH (all stock Ubuntu) |
| `~/.profile` | stock; sources `.bashrc`, adds `~/bin` + `~/.local/bin` to PATH |
| `~/.bash_aliases` | **in repo** (`home/.bash_aliases`) — plain-apt aliases (`i/r/s/u/up`) |
| `~/.config/kwinrc` | compositor: effects, window rules, screen edges — **in repo** |
| `~/.config/kwinrulesrc` | global `noborder` window rule — **in repo** |
| `~/.config/plasma-org.kde.plasma.desktop-appletsrc` | panel layout + widgets — **in repo** |
| `~/.config/plasmashellrc` | shell settings — **in repo** |
| `~/.config/kglobalshortcutsrc` | key bindings — **in repo** |
| `~/.config/kdeglobals` | colors, fonts, icons, cursor — **in repo** |
| `~/.config/gtk-3.0/` + `~/.config/gtk-4.0/` | GTK theme (Breeze-Dark + Inter) — **in repo** |
| `~/.config/powermanagementprofilesrc` | power/backlight — **in repo** |
| `~/.config/konsole/` + `~/.local/share/konsole/` | terminal — `disubuntu` profile + colorscheme **in repo** (`home/.local/share/konsole/`) + `konsolerc` |
| `~/.config/opencode/opencode.jsonc` | opencode config (currently minimal) |
| `~/.local/share/keyrings` | login keyring (used by libsecret) |
| `~/.ssh/authorized_keys` | SSH keys (password login already off) |

Applied bash aliases (`~/.bash_aliases`, loaded by `.bashrc`):

```bash
alias i='sudo apt install'      # install
alias r='sudo apt remove'       # remove
alias s='apt search'            # search
alias u='sudo apt update'       # refresh package lists
alias up='sudo apt upgrade'     # upgrade
```

### 🔄 Routine maintenance

```bash
sudo apt update && sudo apt upgrade   # weekly — security + updates
sudo apt autoremove                   # monthly — drop orphaned deps
journalctl --vacuum-size=200M         # if the journal grows past 200 MB
nvidia-smi                            # verify GPU health (VRAM, driver)
pgrep -a kwin_wayland                 # compositor health
```

> [!NOTE]
> **What each command watches over:** `apt` keeps the ~1,468 packages patched,
> `journalctl` bounds disk, `nvidia-smi` catches the VRAM quirk, and the
> kwin_wayland process confirms the desktop survived the upgrade. None of
> these take more than a minute.

### ↩️ Reset — back to a clean server

```bash
sudo apt-get remove -y --purge plasma-desktop plasma-session-wayland kwin-wayland \
  sddm sddm-theme-breeze kde-config-sddm systemsettings kscreen kio-extras \
  kde-cli-tools powerdevil plasma-nm plasma-pa ksshaskpass polkit-kde-agent-1 \
  breeze breeze-gtk-theme xdg-desktop-portal-kde kde-config-gtk-style \
  kde-config-screenlocker kactivitymanagerd kmenuedit kde-spectacle kinfocenter \
  helium-bin wl-clipboard pipewire pipewire-pulse wireplumber \
  dolphin konsole kdeconnect ark
balooctl6 disable   # (after dolphin purge, baloo6 is a plain unused lib)
sudo apt-get purge --dry-run nvidia-driver-595   # review, then drop --dry-run
sudo systemctl disable --now sddm network-manager wpa_supplicant
sudo rm -f /etc/apt/sources.list.d/helium.list /usr/share/keyrings/helium.gpg
sudo apt-get update && sudo apt-get autoremove --purge -y
# (kernel + grub + base remain untouched)
```

> [!TIP]
> Dry-run any apt operation first with `--dry-run` / `-s`.

**Not touched by the reset (by design):** `linux-generic` kernel, GRUB/EFI,
Secure Boot · `~/.ssh/authorized_keys` + `.bashrc` PATH line · home data
(`~/Pictures`, etc.) · Plasma configs (`~/.config/kwinrc`, `plasma-*`, …) —
delete manually if you want factory defaults.

---

## 🤖 setup.sh

The reproducible installer for this machine, as **plain bash** with zero
third-party deps (prompts via `read`, styling via `tput`; `--yes`
skips prompts, `--check` dry-runs).

| | |
|---|---|
| **Status** | covers the desktop pass (firewall, firmware, Kröhnkite, configs, de-brand); the dev-tools pass (Docker/Node/Rust/Go) and the full reinstall flow are next |
| **Run it** | `bash setup.sh` (or `bash setup.sh --check` to preview) |
| **Steps** | 1) apt: kpackagetool6, firewalld, plasma-firewall, fwupd, ksystemstats · 2) enable firewalld + allow `ssh` · 3) `fwupdmgr refresh` · 4) copy tracked configs from `home/` into `~/.config` (incl. `kwinrulesrc` + the `disubuntu` Konsole profile into `~/.local/share/konsole`) · 5) install + enable Kröhnkite from `vendor/krohnkite/` and reconfigure KWin · 6) de-brand: remove SDDM `ubuntu-theme`, disable Ubuntu MOTD scripts + `motd-news` (config + timer) |
| **Idempotent** | safe to re-run — packages/script/config already present are skipped |
| **Order matters** | configs land **before** the Kröhnkite enable+reconfigure, so the tracked `kwinrc`/`kglobalshortcutsrc` (with `[Script-krohnkite]` and the `Krohnkite*` binds) apply cleanly |

---

## ❓ FAQ

**"Why not just install Ubuntu Desktop?"** It ships GNOME, snaps, and hundreds
of packages we'd never use. This setup starts from the *minimized server* base
and adds only what we need — **1,468 packages** vs. a stock desktop's several
thousand.

**"Why interim instead of LTS?"** LTS releases stay on old software for 5+
years. The interim cadence (every 6 months) brings current kernels, drivers,
and Plasma — especially relevant for the NVIDIA driver, which improves fast.
`Prompt=normal` in `/etc/update-manager/release-upgrades` is the single switch.
**This machine is on Ubuntu 26.04 LTS today; next stop is the 26.10 interim
release in October 2026** (`sudo do-release-upgrade` when it lands).

**"Why only four KDE apps?"** Plasma is the desktop, not an app bundle —
`dolphin` (files) + `konsole` (terminal) cover the daily needs, `kdeconnect`
(phone) and `ark` (archives) fill the two remaining everyday gaps; everything
else (browser, editor) is a separate, explicit choice.

**"Is this stable enough for daily use?"** Yes — Plasma 6 Wayland on NVIDIA is
a mature, supported combination. The main caveats are the known NVIDIA quirks
(document in [🎮 NVIDIA](#-nvidia)) and the troubleshooting table.

**"Where are the panels/widgets?"** One floating top panel. Right-click a
panel → Edit Mode to move/add widgets; the layout is backed up to this repo.

**"How do I update everything?"** `sudo apt update && sudo apt upgrade`
(weekly, see [🧹 Maintenance](#-maintenance--service-inventory)). For the
distro itself: `sudo do-release-upgrade` every 6 months.

**"How do I reset back to a clean server?"** The [🧹 Maintenance](#-maintenance--service-inventory)
section has the exact reset commands.
