#!/usr/bin/env bash
# Instaleaza autopushd: script + timer systemd (15 min) + hook shutdown.
# Hook-ul de suspend (necesita sudo) e optional, propus separat.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
install -m 755 "$SCRIPT_DIR/bin/autopushd" "$HOME/.local/bin/autopushd"
cp "$SCRIPT_DIR"/systemd/autopushd.service "$SCRIPT_DIR"/systemd/autopushd.timer "$SCRIPT_DIR"/systemd/autopushd-shutdown.service "$HOME/.config/systemd/user/"

systemctl --user daemon-reload
systemctl --user enable --now autopushd.timer
systemctl --user enable --now autopushd-shutdown.service

echo "autopushd instalat. Editeaza ~/.config/autopushd/roots.txt cu directoarele tale de proiecte."
echo

read -r -p "Adaugi si hook de suspend/lid-close (necesita sudo)? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    TMP="$(mktemp)"
    sed "s/__TARGET_USER__/$USER/" "$SCRIPT_DIR/systemd/autopushd-sleep.template" > "$TMP"
    sudo install -m 755 -o root -g root "$TMP" /usr/lib/systemd/system-sleep/autopushd-sleep
    rm -f "$TMP"
    echo "Hook de suspend instalat la /usr/lib/systemd/system-sleep/autopushd-sleep"
fi

echo "Gata. Ruleaza 'autopushd' manual oricand vrei un sync imediat."
