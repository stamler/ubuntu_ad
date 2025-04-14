#!/bin/bash

# update and upgrade packages
apt update && apt upgrade -y

# Install necessary packages for AD integration
# - realmd: for discovering and joining domains.
# - sssd, sssd-tools, libnss-sss, libpam-sss: for integrating Linux login with AD.
# - adcli: for AD domain join.
# - samba-common-bin: for Samba-related utilities.
# - oddjob & oddjob-mkhomedir: for home directory creation on login.
# - packagekit: required for some domain join processes.
# - cifs-utils: for mounting Windows SMB (CIFS) shares.
apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli \
  samba-common-bin oddjob oddjob-mkhomedir packagekit cifs-utils

# Add Tailscale Repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt update

# install other software
apt install -y evolution evolution-ews tailscale xrdp xorgxrdp pdfarranger librecad

# Enable xrdp
systemctl enable xrdp

# remove software
apt remove thunderbird

# Users who wish to connect via RDP must configure cinnamon
# NOTE: AD users will *not* be able to RDP by default https://c-nergy.be/blog/?p=16274
# echo "cinnamon-session" > ~/.xsession
# chmod +x ~/.xsession
# sudo systemctl restart xrdp

# Configure Evolution to use Microsoft Exchange as follows:
# Open Evolution and go to Edit -> Preferences -> Mail Accounts -> Add
# Press Next, enter your name and email address
# Uncheck "Look up mail server details", click Next
# Select "Exchange Web Services" from Server Type
# Enter https://outlook.office365.com/EWS/Exchange.asmx for Host URL
# Select OAuth2 as Authentication Method
# Next -> Next -> Next -> Apply
