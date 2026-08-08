#!/usr/bin/env bash
set -uo pipefail

systemctl --user disable --now autopushd.timer autopushd-shutdown.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/autopushd.service" \
      "$HOME/.config/systemd/user/autopushd.timer" \
      "$HOME/.config/systemd/user/autopushd-shutdown.service" \
      "$HOME/.local/bin/autopushd"
systemctl --user daemon-reload

if [ -f /usr/lib/systemd/system-sleep/autopushd-sleep ]; then
    sudo rm -f /usr/lib/systemd/system-sleep/autopushd-sleep
fi

echo "autopushd dezinstalat. Config din ~/.config/autopushd ramas neatins (sterge manual daca vrei)."
