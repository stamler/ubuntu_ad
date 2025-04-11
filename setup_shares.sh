#!/bin/bash

HELPER_SCRIPT_PATH="/usr/local/bin/mount-domain-shares.sh"
AUTOSTART_FILE_PATH="/etc/xdg/autostart/mount-domain-shares.desktop"

# If the HELPER_SCRIPT_PATH exists, delete it. This means that
# the actual mounts will be updated if the script is run again.
if [ -f "${HELPER_SCRIPT_PATH}" ]; then
    rm "${HELPER_SCRIPT_PATH}"
fi

cat > "${HELPER_SCRIPT_PATH}" << EOF
#!/bin/bash

# This script is executed by the .desktop file after graphical login.
# It mounts the specified SMB shares using gio mount, leveraging GVfs
# and the user's Kerberos credentials obtained during login.

# delay to ensure the network is ready
sleep 5

# mount shares
gio mount smb://file01.main.tbte.ca/projects
gio mount smb://file03.main.tbte.ca/library
gio mount smb://nas2.main.tbte.ca/archive

# Exit cleanly
exit 0
EOF

chmod 755 "${HELPER_SCRIPT_PATH}"

cat > "${AUTOSTART_FILE_PATH}" << EOF
[Desktop Entry]
# Type of entry
Type=Application
# Name (for informational purposes, not usually displayed)
Name=Mount Domain Shares (GIO)
# Comment (for informational purposes)
Comment=Automatically mount network shares using GIO/GVfs for domain users
# Command to execute (our helper script)
Exec=${HELPER_SCRIPT_PATH}
# Don't run it in a visible terminal window
Terminal=false
# Don't show this in user-facing "Startup Applications" GUI tools
NoDisplay=true
# Standard flag to ensure it's treated as an enabled autostart item
X-GNOME-Autostart-enabled=true
# Limit which desktop environments this should run in.
# Add or remove as needed, but these cover common Mint DEs.
OnlyShowIn=Cinnamon;MATE;XFCE;GNOME;
EOF

chmod 644 "${AUTOSTART_FILE_PATH}"
exit 0
