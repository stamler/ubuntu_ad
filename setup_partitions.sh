#!/bin/bash
# partition-mint.sh
#
# This script erases an entire disk, creates a GPT partition table with:
#   - A 512 MiB EFI system partition formatted as FAT32 and labeled "ESP"
#     with boot and esp flags.
#   - A second partition spanning the rest of the disk intended for Linux Mint.
#
# Usage: sudo ./partition-mint.sh /dev/sdX
# (Replace /dev/sdX with the target device such as /dev/sda or /dev/nvme0n1)

set -euo pipefail

# Check that the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Try 'sudo $0 /dev/sdX'"
    exit 1
fi

# Check that exactly one argument (the target disk) is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 /dev/sdX"
    exit 1
fi

TARGET="$1"

echo "WARNING: This will completely erase all data on $TARGET!"
read -rp "Are you sure you want to continue? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborting partitioning."
    exit 1
fi

# Unmount any mounted partitions on the target disk (ignore errors)
umount ${TARGET}* 2>/dev/null || true

# Detect if the disk name is for an NVMe device where partitions are named with a 'p' (e.g. /dev/nvme0n1p1)
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
echo "You can now use the Linux Mint installer to format the second partition as Btrfs and set it as the root mount (/)."
