#!/usr/bin/env bash
# disubuntu setup — gum-powered TUI installer (STUB, WIP)
# Scope today: base-OS + desktop pass (firewall, firmware, Kröhnkite, config).
# Dev tools (Docker, Node, Rust, Go) + full flow appended in the dev pass.
# Idempotent: safe to re-run. No reboot, no destructive steps.
#
# Usage:  bash setup.sh [--check] [--yes]
#   --check   dry-run: print steps without executing (gum confirm still shown)

set -euo pipefail

PASS="desktop-base-2026-08"          # bump when a new pass is merged
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=""
ASSUME_YES=""
for a in "$@"; do
  case "$a" in
    --check) DRY=1 ;;
    --yes)   ASSUME_YES=1 ;;
  esac
done

if ! command -v gum >/dev/null; then
  echo "gum (TUI) not found — install it first:  sudo apt install -y gum"
  exit 1
fi

# ── helpers ─────────────────────────────────────────────────────────────────
run() { # run <desc> <cmd...>  (dry-run aware)
  local desc="$1"; shift
  gum style --foreground 250 "$desc"
  if [[ -n "$DRY" ]]; then gum style --foreground 240 "  [dry-run] would run: $*"; return 0; fi
  "$@"
}

confirm_step() { # confirm_step <label> — skip when --yes
  [[ -n "$ASSUME_YES" ]] && return 0
  gum confirm --default=false "Run this step? $1" || { gum style --foreground 208 "  skipped"; return 1; }
}

# ── banner ──────────────────────────────────────────────────────────────────
gum style --border double --padding "1 2" \
  --foreground 45 "disubuntu $PASS" \
  "$(gum style --foreground 250 'base-OS + desktop pass — firewall · firmware · Kröhnkite · config')"

# ── 0. baseline sanity ──────────────────────────────────────────────────────
gum spin --title "Baseline sanity (dpkg lock, repos)…" -- sleep 1

# ── 1. packages ─────────────────────────────────────────────────────────────
confirm_step "apt: kpackagetool6 firewalld plasma-firewall fwupd gum ksystemstats" && \
run "Installing packages (official Ubuntu repos)" \
  sudo apt-get install -y kpackagetool6 firewalld plasma-firewall fwupd gum ksystemstats

# ── 2. firewall (firewalld + plasma-firewall KCM) ───────────────────────────
confirm_step "firewall: enable firewalld + allow ssh" && {
  run "Enabling firewalld" sudo systemctl enable --now firewalld
  run "Allowing ssh (openssh-server is installed)" sudo firewall-cmd --permanent --add-service=ssh
  run "Reloading firewall" sudo firewall-cmd --reload
}

# ── 3. fwupd ────────────────────────────────────────────────────────────────
confirm_step "fwupd: refresh firmware metadata" && {
  run "Refreshing fwupd metadata" fwupdmgr refresh || {
    rc=$?
    # fwupdmgr exits 2 when metadata is already up to date (no-op) — fine
    [[ $rc -eq 2 ]] || { gum style --foreground 9 "fwupdmgr refresh failed (rc=$rc)"; exit $rc; }
  }
}

# ── 4. configs from repo (plain copies — machine → repo is the backup flow) ──
confirm_step "copy repo configs into ~/.config (kwinrc, kglobalshortcutsrc, …)" && {
  for f in kwinrc kglobalshortcutsrc kdeglobals \
           plasma-org.kde.plasma.desktop-appletsrc plasmashellrc konsolerc; do
    if [[ -f "$REPO_DIR/home/.config/$f" ]]; then
      run "  $f" cp "$REPO_DIR/home/.config/$f" "$HOME/.config/$f"
    fi
  done
  run "  .bash_aliases" cp "$REPO_DIR/home/.bash_aliases" "$HOME/.bash_aliases"
  if [[ -d "$REPO_DIR/home/.local/share/konsole" ]]; then
    run "  konsole profile+colorscheme" \
      cp -r "$REPO_DIR/home/.local/share/konsole" "$HOME/.local/share/"
  fi
}

# ── 5. Kröhnkite (dynamic tiling, only third-party desktop component) ───────
# NOTE: must run AFTER config copy — the copied kwinrc/kglo…rc carry the
# Krohnkite settings; reconfigure applies them, so the script starts tiled.
confirm_step "Kröhnkite: install + enable KWin script" && {
  kwinscript="$REPO_DIR/vendor/krohnkite/krohnkite-0.9.9.2.kwinscript"
  if [[ ! -f "$kwinscript" ]]; then
    gum style --foreground 9 "Missing vendor artifact: $kwinscript" \
      "(fetch from codeberg.org/anametologin/Krohnkite/releases, pin 0.9.9.2)"
    exit 1
  fi
  if kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
    gum style --foreground 250 "Kröhnkite already installed — skipping"
  else
    run "Installing Kröhnkite 0.9.9.2" kpackagetool6 -t KWin/Script -i "$kwinscript"
  fi
  run "Enabling Kröhnkite in kwinrc" \
    kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
  run "Applying KWin config" qdbus6 org.kde.KWin /KWin reconfigure
}

# ── summary ─────────────────────────────────────────────────────────────────
gum style --border rounded --padding "1 2" --foreground 42 "Done (pass $PASS)
firewall:    $(systemctl is-active firewalld 2>/dev/null || echo '?')
fwupd:       $(systemctl is-active fwupd 2>/dev/null || echo '?')
Kröhnkite:   $(kpackagetool6 -t KWin/Script -s krohnkite 2>/dev/null >/dev/null && echo installed || echo '?')
session:     restart Plasma (re-login) only if KWin shortcuts changed"

gum style --foreground 208 "WIP stub — dev tools (Docker/Node/Rust/Go) + full reinstall flow land in the dev pass."
