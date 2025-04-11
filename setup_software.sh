#!/bin/bash

# Add Tailscale Repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt update

# install software
apt install -y evolution evolution-ews tailscale xrdp xorgxrdp

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
