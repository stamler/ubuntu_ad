# Setup Linux Mint for domain join

## Join the domain

From an elevated command prompt (`sudo su -`) run the following commands:
```
# Download the script locally. This is required because the script is interactive.
curl -sLo setup_ad_integration.sh https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_ad_integration.sh

# Make the script executable.
chmod +x setup_ad_integration.sh

# Run the script.
./setup_ad_integration.sh
```

## Setup the Software

Run the following command to install the software. If you're not running as root you will be prompted for your password.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_software.sh | sudo bash
```

## Setup the Shares

Run the following command to setup the shares. If you're not running as root you will be prompted for your password.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_shares.sh | sudo bash
```
