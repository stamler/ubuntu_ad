# Setup Linux Mint

## 0. Prerequisites

This machine should be running Linux Mint or Ubuntu on a btrfs filesystem with Timeshift enabled. If it is not, first partition the disk.

```
curl -sLo setup_partitions.sh https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_partitions.sh
chmod +x setup_partitions.sh
./setup_partitions.sh
```

Then install Linux on the btrfs partition. Finally enable timeshift in btrfs.

```
sudo timeshift --btrfs
```

## 1. Restore an existing snapshot

Skip this step if you just installed linux in step 0. Otherwise, if this machine has Timeshift enabled on btrfs and was previously setup, restore the snapshot first. If you haven't already done so, now is the time to remove the machine from Active Directory as well. After restoring the snapshot, delete any old user directories from the `/home` directory.

```
timeshift --list
timeshift --restore --snapshot '<Name>'
```

## 2. Setup the software

Run the following command to install the software. If you're not running as root you will be prompted for your password. This will install the current software suite, remove software that's not specified, and run updates.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_software.sh | sudo bash
```

## 3. Create or update snapshot

Create a Timeshift shapshot. This will be the new restore state the next time you need to restore the machine. If this is machine that came back from the field and has previously been joined to the domain, delete the old snapshot after creating a new one.

```
timeshift --create --comments "Fresh update before joining domain" --tags O
```

## 4. Join the domain

Download the domain join script and make it executable

```
curl -sLo setup_ad_integration.sh https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_ad_integration.sh
chmod +x setup_ad_integration.sh
```

Run the script. You'll be prompted for the domain name (FQDN) and the username (without domain) at the beginning of the script. Later on during domain join you'll be prompted for the password of the account with domain admin privileges.
```
sudo ./setup_ad_integration.sh
```

## 5. Setup the shares

Run the following command to setup the shares. If you're not running as root you will be prompted for your password.
```
curl -sL https://raw.githubusercontent.com/stamler/ubuntu_ad/refs/heads/main/setup_shares.sh | sudo bash
```
