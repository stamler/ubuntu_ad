#!/bin/bash
# =============================================================================
# Script Name: setup_ad_integration.sh
# Description: This script updates a fresh Linux Mint install, installs
#              necessary dependencies, joins an Active Directory domain,
#              and configures the system so that domain users can mount SMB
#              shares using Kerberos authentication (sec=krb5) without needing
#              to enter their credentials again.
#
# Requirements: Must be run as root.
#
# Usage:
#   sudo ./setup_ad_integration.sh
# =============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the domain name from the user input
read -p "Enter the domain name: " DOMAIN_NAME

# Prompt for AD admin credentials
read -p "Enter your AD admin username without domain (e.g., admin): " AD_USER
read -s -p "Enter your AD admin password: " AD_PASSWORD

# Check if running as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try: sudo $0"
    exit 1
fi
apt update && apt upgrade -y

# Install necessary packages:
# - realmd: for discovering and joining domains.
# - sssd, sssd-tools, libnss-sss, libpam-sss: for integrating Linux login with AD.
# - adcli: for AD domain join.
# - samba-common-bin: for Samba-related utilities.
# - oddjob & oddjob-mkhomedir: for home directory creation on login.
# - packagekit: required for some domain join processes.
# - cifs-utils: for mounting Windows SMB (CIFS) shares.
apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli \
  samba-common-bin oddjob oddjob-mkhomedir packagekit cifs-utils

# rename the computer
SERIAL_NUMBER=$(dmidecode -s system-serial-number)
CHASSIS_TYPE=$(dmidecode -s chassis-type)
# if SERIAL_NUMBER is 'Not Specified', then use a random 8 character string, otherwise prepend with linux-
if [[ $SERIAL_NUMBER == "Not Specified" ]]; then
    NEW_HOSTNAME="$CHASSIS_TYPE-$(openssl rand -hex 4)"
else
    NEW_HOSTNAME="$CHASSIS_TYPE-${SERIAL_NUMBER}"
fi
hostnamectl set-hostname "$NEW_HOSTNAME"
sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts

# Discover the AD domain to verify connectivity and settings.
realm discover $DOMAIN_NAME

# Extract realm-name from realm discover output
REALM_NAME=$(realm discover $DOMAIN_NAME | grep 'realm-name' | awk '{print $2}')

# Join the domain.
# Note: Depending on your environment, you might be prompted again for the password.
echo $AD_PASSWORD | realm join --user="$AD_USER@$REALM_NAME" $DOMAIN_NAME

# Verify if the domain join was successful.
if [ $? -ne 0 ]; then
    echo "Domain join failed. Please check your credentials and network settings."
    exit 1
fi

# Overwrite /etc/krb5.conf with the desired configuration.
KRB5_CONF="/etc/krb5.conf"
cat > "$KRB5_CONF" <<EOF
[libdefaults]
default_realm = $REALM_NAME
  dns_lookup_realm = false
  dns_lookup_kdc = true
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true

[domain_realm]
  .$DOMAIN_NAME = $REALM_NAME
  $DOMAIN_NAME = $REALM_NAME
  .tbte.ca = $REALM_NAME
  tbte.ca = $REALM_NAME
EOF

# Overwrite /etc/sssd/sssd.conf with the desired configuration.
SSSD_CONF="/etc/sssd/sssd.conf"
cat > "$SSSD_CONF" <<EOF
[sssd]
domains = $DOMAIN_NAME
config_file_version = 2
services = nss, pam

[domain/$DOMAIN_NAME]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = $REALM_NAME
realmd_tags = manages-system joined-with-adcli
id_provider = ad
fallback_homedir = /home/%u@%d
ad_domain = $DOMAIN_NAME
use_fully_qualified_names = True
ldap_id_mapping = True
access_provider = ad
EOF

# Set secure permissions for sssd.conf to protect sensitive data.
chmod 600 "$SSSD_CONF"

# Restart the sssd service so changes take effect.
systemctl restart sssd

# Ensure that PAM is configured to automatically create home directories
# for domain users when they log in. This adds a line to /etc/pam.d/common-session
# if it does not already exist.
if ! grep -q "pam_mkhomedir.so" /etc/pam.d/common-session; then
    echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session
fi

# Configure LightDM to allow manual login (typing username)
LIGHTDM_CONF_DIR="/etc/lightdm/lightdm.conf.d"
LIGHTDM_MANUAL_LOGIN_CONF="$LIGHTDM_CONF_DIR/90-allow-manual-login.conf"

mkdir -p "$LIGHTDM_CONF_DIR"
cat > "$LIGHTDM_MANUAL_LOGIN_CONF" <<EOF
[Seat:*]
greeter-show-manual-login=true
greeter-hide-users=true
EOF

echo "======================================================"
echo "Setup Complete!"
echo "Your machine is now joined to the AD domain '$DOMAIN_NAME'."
echo "----------------------------------------------"
echo "Next steps for mounting SMB shares using Kerberos:"
echo "1. Ensure you have a valid Kerberos ticket by running: klist"
echo "2. Mount an SMB share using the following example command:"
echo "   sudo mount -t cifs //server/sharename /mnt/sharename -o sec=krb5,cruid=\$(id -u),uid=\$(id -u),gid=\$(id -g)"
echo "   (Replace //server/sharename and /mnt/sharename with your server/share and mount point.)"
echo "----------------------------------------------"
echo "Now, domain users logging into this machine should be able to mount network shares"
echo "without needing to enter their credentials again, just like on Windows."
echo "----------------------------------------------"
echo "A REBOOT IS REQUIRED for login screen changes to take effect."
