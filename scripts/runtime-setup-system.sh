#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/runtime-backup.sh"

echo "🛠️  System Setup Guide for Domoticz (Debian Stable)"
echo "====================================================="
echo ""
echo "Follow these steps to configure your Debian production machine."
echo ""

echo "1️⃣  INSTALL DOCKER"
echo "-------------------"
echo "Run these commands to install Docker and a modern Compose plugin:"
echo ""
echo "  sudo apt update"
echo "  sudo apt install docker.io docker-compose-v2"
echo ""
echo "Note: Using docker.io ensures stability on Debian Stable."
echo ""

echo "1️⃣  SETUP SYSTEMD SERVICE"
echo "--------------------------"
echo "Create a service to start/stop the Docker stack automatically at boot."
echo ""
echo "Run this command to create the service file:"
echo "----------------------------------------------------------------"
cat <<EOF
sudo bash -c 'cat <<SERVICE > /etc/systemd/system/domoticz.service
[Unit]
Description=Domoticz Home Automation Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$BASE_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE'
EOF
echo "----------------------------------------------------------------"
echo ""
echo "After creating the file, run these commands to enable it:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable domoticz.service"
echo "  sudo systemctl start domoticz.service"
echo ""

echo "2️⃣  SETUP AUTOMATIC BACKUPS (CRON)"
echo "-----------------------------------"
echo "Schedule a backup every night at 3:00 AM."
echo ""
echo "Run 'crontab -e' and add this line at the end:"
echo "----------------------------------------------------------------"
echo "0 3 * * * $BACKUP_SCRIPT > /dev/null 2>&1"
echo "----------------------------------------------------------------"
echo ""
echo "Done! Your system will now be persistent and backed up automatically. ✨"
