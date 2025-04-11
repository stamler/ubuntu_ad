# Setup Linux Mint for domain join

## Restore an existing snapshot

If this machine has Timeshift enabled on btrfs and was previously setup, restore the snapshot before continuing.

## Setup the Software

Run the following command to install the software. If you're not running as root you will be prompted for your password. This will install the current software suite, remove software that's not specified, and run updates.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_software.sh | sudo bash
```

## Snapshot

Create a Timeshift shapshot. If this is machine that came back from the field and has previously been joined to the domain, delete the old snapshot after creating a new one.

## Join the domain

Download the domain join script and make it executable

```
curl -sLo setup_ad_integration.sh https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_ad_integration.sh
chmod +x setup_ad_integration.sh
```

Run the script. You'll be prompted for the domain name (FQDN) and the username (without domain) at the beginning of the script. Later on during domain join you'll be prompted for the password of the account with domain admin privileges.
```
sudo ./setup_ad_integration.sh
```

## Setup the Shares

Run the following command to setup the shares. If you're not running as root you will be prompted for your password.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_shares.sh | sudo bash
```
