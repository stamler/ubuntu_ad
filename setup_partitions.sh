#!/bin/bash
# partition-mint.sh
#
# This script enumerates available disks with human‑readable details and prompts the user
# to select a disk. It then erases the disk, creates a GPT partition table, and partitions as follows:
#   - A 512 MiB EFI system partition formatted as FAT32 and labeled "ESP"
#     with boot and esp flags.
#   - A second partition spanning the rest of the disk intended for Linux Mint.
#
# Usage: sudo ./partition-mint-enhanced.sh

set -euo pipefail

# Check that the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo $0'."
    exit 1
fi

# List available block devices with human‑readable details
# Using lsblk to list only physical disks (ignoring loop devices)
echo "Available disks:"
lsblk -dpno NAME,SIZE,MODEL | grep -v "loop"
echo ""

# Prompt the user to enter the full device name (e.g., /dev/sda or /dev/nvme0n1)
read -rp "Enter the full device name to use (e.g., /dev/sda): " TARGET

# Validate that the input is a valid block device
if [[ ! -b "$TARGET" ]]; then
    echo "Error: $TARGET is not a valid block device."
    exit 1
fi

# Confirm with the user before proceeding
echo ""
echo "WARNING: This will completely erase all data on $TARGET."
read -rp "Are you sure you want to continue? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborting partitioning."
    exit 1
fi

# Unmount any mounted partitions on the target disk (ignore errors)
umount ${TARGET}* 2>/dev/null || true

# Determine partition names based on device type.
# NVMe devices use a 'p' in the partition names (e.g., /dev/nvme0n1p1).
if [[ "$TARGET" =~ nvme ]]; then
    EFI_PART="${TARGET}p1"
    LINUX_PART="${TARGET}p2"
else
    EFI_PART="${TARGET}1"
    LINUX_PART="${TARGET}2"
fi

echo "Creating GPT partition table on $TARGET..."
parted --script "$TARGET" mklabel gpt

echo "Creating EFI partition (512 MiB) for boot..."
# Start at 1MiB for alignment; partition size: 512 MiB (from 1MiB to 513MiB).
parted --script "$TARGET" mkpart primary fat32 1MiB 513MiB

echo "Setting boot and ESP flags on the EFI partition..."
parted --script "$TARGET" set 1 boot on
parted --script "$TARGET" set 1 esp on

echo "Creating Linux Mint partition using remaining disk space..."
parted --script "$TARGET" mkpart primary btrfs 513MiB 100%

echo "Partitioning complete."

echo "Formatting EFI partition ($EFI_PART) as FAT32 with label 'ESP'..."
mkfs.fat -F32 -n ESP "$EFI_PART"

echo "EFI partition formatted."
echo "NOTE: The Linux Mint partition ($LINUX_PART) has been created but not formatted."
echo "You can now use the Linux Mint installer, selecting 'Something else' when prompted, to format the second partition as Btrfs and set it as the root mount (/)."
