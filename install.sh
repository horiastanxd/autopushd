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

echo
if python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk" 2>/dev/null; then
    read -r -p "Instalezi si tray-ul (icon in system tray cu status live)? [y/N] " ans_tray
    if [[ "$ans_tray" =~ ^[Yy]$ ]]; then
        install -m 755 "$SCRIPT_DIR/bin/autopushd-tray" "$HOME/.local/bin/autopushd-tray"
        cp "$SCRIPT_DIR/systemd/autopushd-tray.service" "$HOME/.config/systemd/user/"
        systemctl --user daemon-reload
        systemctl --user enable --now autopushd-tray.service
        echo "Tray pornit. Pe GNOME e nevoie de extensia 'AppIndicator and KStatusNotifierItem Support' ca sa apara iconita."
    fi
else
    echo "Tray sarit: lipsesc bindings GTK3 pt python3 (pachet python3-gi). Instaleaza-l si ruleaza din nou install.sh daca il vrei."
fi

echo "Gata. Ruleaza 'autopushd' manual oricand vrei un sync imediat."
