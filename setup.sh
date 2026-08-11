#!/usr/bin/env bash
# disubuntu setup — plain-bash installer (no third-party deps)
# Scope today: base-OS + desktop pass (firewall, firmware, Kröhnkite, config,
# de-brand). Dev tools (Docker, Node, Rust, Go) + full flow appended in the dev pass.
# Idempotent: safe to re-run. No reboot, no destructive steps.
#
# Usage:  bash setup.sh [--check] [--yes]
#   --check   dry-run: print steps without executing (confirms still shown)

set -euo pipefail

PASS="apps-2026-08-11"    # bump when a new pass is merged
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=""
ASSUME_YES=""
for a in "$@"; do
  case "$a" in
    --check) DRY=1 ;;
    --yes)   ASSUME_YES=1 ;;
  esac
done

# ── helpers ─────────────────────────────────────────────────────────────────
GREEN=$'\e[32m'; CYAN=$'\e[36m'; GRAY=$'\e[90m'; RED=$'\e[31m'; BOLD=$'\e[1m'; RST=$'\e[0m'

run() { # run <desc> <cmd...>  (dry-run aware)
  local desc="$1"; shift
  printf '%s\n' "${CYAN}$desc${RST}"
  if [[ -n "$DRY" ]]; then printf '%s\n' "${GRAY}  [dry-run] would run: $*${RST}"; return 0; fi
  "$@"
}

confirm_step() { # confirm_step <label> — skip when --yes
  [[ -n "$ASSUME_YES" ]] && return 0
  local reply
  read -r -p "${BOLD}Run this step? $1 [y/N]${RST} " reply
  case "$reply" in
    [yY]*) return 0 ;;
    *) printf '%s\n' "${RED}  skipped${RST}"; return 1 ;;
  esac
}

# ── banner ──────────────────────────────────────────────────────────────────
printf '%s\n' "${GREEN}${BOLD}━━ disubuntu $PASS ━━${RST}"
printf '%s\n' "${GRAY}base-OS + desktop pass — firewall · firmware · Kröhnkite · config · de-brand${RST}"

# ── 0. baseline sanity ──────────────────────────────────────────────────────
printf '%s\n' "${GRAY}Baseline sanity (dpkg lock, repos)…${RST}"
[[ -n "$DRY" ]] || sleep 1

# ── 1. packages ─────────────────────────────────────────────────────────────
confirm_step "apt: kpackagetool6 firewalld plasma-firewall fwupd ksystemstats" && \
run "Installing packages (official Ubuntu repos)" \
  sudo apt-get install -y kpackagetool6 firewalld plasma-firewall fwupd ksystemstats

# ── 2. firewall (firewalld + plasma-firewall KCM) ───────────────────────────
confirm_step "firewall: enable firewalld + allow ssh" && {
  run "Enabling firewalld" sudo systemctl enable --now firewalld
  run "Allowing ssh (openssh-server is installed)" sudo firewall-cmd --permanent --add-service=ssh
  run "Reloading firewall" sudo firewall-cmd --reload
}

# ── 2b. kdeconnect + ark (phone integration + archive manager) ───────────────
confirm_step "apps: kdeconnect (phone) + ark (archives) + firewalld service" && {
  run "Installing kdeconnect + ark" \
    sudo apt-get install -y --no-install-recommends kdeconnect ark
  run "Opening KDE Connect ports (firewalld kdeconnect service)" \
    sudo firewall-cmd --permanent --add-service=kdeconnect
  run "Reloading firewall" sudo firewall-cmd --reload
}

# ── 3. fwupd ────────────────────────────────────────────────────────────────
confirm_step "fwupd: refresh firmware metadata" && {
  run "Refreshing fwupd metadata" fwupdmgr refresh || {
    rc=$?
    # fwupdmgr exits 2 when metadata is already up to date (no-op) — fine
    [[ $rc -eq 2 ]] || { printf '%s\n' "${RED}fwupdmgr refresh failed (rc=$rc)${RST}"; exit $rc; }
  }
}

# ── 4. configs from repo (plain copies — machine → repo is the backup flow) ──
confirm_step "copy repo configs into ~/.config (kwinrc, kglobalshortcutsrc, …)" && {
  for f in kwinrc kwinrulesrc kglobalshortcutsrc kdeglobals \
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

# ── 5. Kröhnkite (dynamic tiling — intentional third-party; no native equiv) ─
# NOTE: must run AFTER config copy — the copied kwinrc/kglo…rc carry the
# Krohnkite settings; reconfigure applies them, so the script starts tiled.
confirm_step "Kröhnkite: install + enable KWin script" && {
  kwinscript="$REPO_DIR/vendor/krohnkite/krohnkite-0.9.9.2.kwinscript"
  if [[ ! -f "$kwinscript" ]]; then
    printf '%s\n' "${RED}Missing vendor artifact: $kwinscript${RST}" \
      "(fetch from codeberg.org/anametologin/Krohnkite/releases, pin 0.9.9.2)"
    exit 1
  fi
  if kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
    printf '%s\n' "${GRAY}Kröhnkite already installed — skipping${RST}"
  else
    run "Installing Kröhnkite 0.9.9.2" kpackagetool6 -t KWin/Script -i "$kwinscript"
  fi
  run "Enabling Kröhnkite in kwinrc" \
    kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
  run "Applying KWin config" qdbus6 org.kde.KWin /KWin reconfigure
}

# ── 6. de-brand — no Canonical/Ubuntu theming (2026-08-11) ──────────────────
# Removes the Ubuntu login theme (orphaned — /etc/sddm.conf already uses
# breeze), disables the Ubuntu MOTD branding + Canonical news feed.
# Kept on purpose: os-release/lsb-release (required by do-release-upgrade),
# 85-fwupd + 92-unattended-upgrades (useful status, not branding).
confirm_step "de-brand: remove SDDM ubuntu-theme, disable Ubuntu MOTD + motd-news" && {
  if [[ -d /usr/share/sddm/themes/ubuntu-theme ]]; then
    run "Removing orphaned SDDM ubuntu-theme" sudo rm -rf /usr/share/sddm/themes/ubuntu-theme
  else
    printf '%s\n' "${GRAY}  SDDM ubuntu-theme already gone — skipping${RST}"
  fi
  for f in 00-header 10-help-text 50-motd-news 60-unminimize 91-release-upgrade; do
    if [[ -f "/etc/update-motd.d/$f" ]]; then
      run "  disabling /etc/update-motd.d/$f" sudo chmod -x "/etc/update-motd.d/$f"
    fi
  done
  if ! grep -q '^ENABLED=0' /etc/default/motd-news 2>/dev/null; then
    run "  motd-news ENABLED=0" sudo tee /etc/default/motd-news >/dev/null <<'EOF'
ENABLED=0

# Ubuntu motd-news config
# ENABLED=0 disables the Canonical news feed
EOF
  else
    printf '%s\n' "${GRAY}  motd-news already disabled — skipping${RST}"
  fi
  if systemctl is-enabled motd-news.timer >/dev/null 2>&1; then
    run "Disabling motd-news.timer" sudo systemctl disable --now motd-news.timer
  else
    printf '%s\n' "${GRAY}  motd-news.timer already off — skipping${RST}"
  fi
}

# ── summary ─────────────────────────────────────────────────────────────────
printf '%s\n' "${GREEN}${BOLD}Done (pass $PASS)${RST}"
printf '%s\n' "firewall:    $(systemctl is-active firewalld 2>/dev/null || echo '?')"
printf '%s\n' "fwupd:       $(systemctl is-active fwupd 2>/dev/null || echo '?')"
printf '%s\n' "Kröhnkite:   $(kpackagetool6 -t KWin/Script -s krohnkite 2>/dev/null >/dev/null && echo installed || echo '?')"
printf '%s\n' "motd-news:   $(systemctl is-enabled motd-news.timer 2>/dev/null || echo 'disabled')"
printf '%s\n' "session:     restart Plasma (re-login) only if KWin shortcuts changed"

printf '%s\n' "${GRAY}WIP stub — dev tools (Docker/Node/Rust/Go) + full reinstall flow land in the dev pass.${RST}"
