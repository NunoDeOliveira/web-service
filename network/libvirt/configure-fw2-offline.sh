#!/usr/bin/env bash

set -euo pipefail

DOMAIN="fw2"
DISK="/var/lib/libvirt/images/fw2.qcow2"

NBD="/dev/nbd0"
ROOT_PART="/dev/nbd0p3"
MOUNT_POINT="/mnt/fw2"

# Expected NICs
DMZ_MAC="52:54:00:c3:9f:74"
INTERNAL_MAC="52:54:00:b7:9c:39"
MANAGEMENT_MAC="52:54:00:73:8b:2e"

echo "=== FW2 offline network configuration ==="

# ---------------------------------------------------------
# 1. Basic checks
# ---------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

for cmd in virsh qemu-nbd partprobe udevadm openssl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd"
        exit 1
    fi
done

if [[ ! -f "$DISK" ]]; then
    echo "ERROR: FW2 disk not found: $DISK"
    exit 1
fi

# ---------------------------------------------------------
# 2. Verify the libvirt NIC topology
# ---------------------------------------------------------

echo "[1/9] Checking FW2 NIC topology..."

IFLIST=$(virsh -c qemu:///system domiflist "$DOMAIN")

echo "$IFLIST"

check_nic() {
    local source="$1"
    local mac="$2"

    echo "$IFLIST" |
        awk -v source="$source" -v mac="$mac" \
        '$3 == source && $5 == mac {found=1} END {exit !found}'
}

if ! check_nic "web-dmz" "$DMZ_MAC"; then
    echo "ERROR: DMZ NIC does not match the expected MAC."
    exit 1
fi

if ! check_nic "internal-net" "$INTERNAL_MAC"; then
    echo "ERROR: Internal NIC does not match the expected MAC."
    exit 1
fi

if ! check_nic "management-net" "$MANAGEMENT_MAC"; then
    echo "ERROR: Management NIC does not match the expected MAC."
    exit 1
fi

echo "FW2 NIC topology is correct."

# ---------------------------------------------------------
# 3. Ask for the permanent root password
# ---------------------------------------------------------

echo
echo "The password is NOT stored in this script."

read -rsp "Enter the permanent FW2 root password: " FW_PASSWORD
echo
read -rsp "Repeat the permanent FW2 root password: " FW_PASSWORD_2
echo

if [[ "$FW_PASSWORD" != "$FW_PASSWORD_2" ]]; then
    echo "ERROR: Passwords do not match."
    exit 1
fi

unset FW_PASSWORD_2

# ---------------------------------------------------------
# 4. Stop FW2
# ---------------------------------------------------------

echo "[2/9] Checking FW2 state..."

STATE=$(virsh -c qemu:///system domstate "$DOMAIN" 2>/dev/null || true)

if [[ "$STATE" == "running" ]]; then
    echo "Stopping FW2..."
    virsh -c qemu:///system destroy "$DOMAIN"
else
    echo "FW2 is already stopped."
fi

# ---------------------------------------------------------
# 5. Check that NBD is free
# ---------------------------------------------------------

echo "[3/9] Preparing NBD..."

modprobe nbd max_part=8

if [[ -s /sys/block/nbd0/pid ]]; then
    echo "ERROR: /dev/nbd0 is already being used."
    exit 1
fi

# ---------------------------------------------------------
# 6. Connect and mount FW2
# ---------------------------------------------------------

echo "[4/9] Mounting FW2 disk..."

qemu-nbd \
    --connect="$NBD" \
    "$DISK"

partprobe "$NBD"
udevadm settle

mkdir -p "$MOUNT_POINT"
mount "$ROOT_PART" "$MOUNT_POINT"

cleanup() {

    sync || true

    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT"
    fi

    qemu-nbd --disconnect "$NBD" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

if ! grep -q '^ID=alpine' "$MOUNT_POINT/etc/os-release"; then
    echo "ERROR: Alpine Linux root filesystem was not found."
    exit 1
fi

echo "Alpine Linux root filesystem found."

# ---------------------------------------------------------
# 7. Create backup
# ---------------------------------------------------------

echo "[5/9] Creating configuration backup..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$MOUNT_POINT/root/config-backup/$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

cp -a \
    "$MOUNT_POINT/etc/network/interfaces" \
    "$BACKUP_DIR/interfaces"

cp -a \
    "$MOUNT_POINT/etc/sysctl.conf" \
    "$BACKUP_DIR/sysctl.conf"

cp -a \
    "$MOUNT_POINT/etc/ssh/sshd_config" \
    "$BACKUP_DIR/sshd_config"

cp -a \
    "$MOUNT_POINT/etc/shadow" \
    "$BACKUP_DIR/shadow"

echo "Backup created in:"
echo "/root/config-backup/$TIMESTAMP"

# ---------------------------------------------------------
# 8. Configure the three FW2 interfaces
# ---------------------------------------------------------

echo "[6/9] Writing FW2 network configuration..."

cat > "$MOUNT_POINT/etc/network/interfaces" <<'EOF'
auto lo
iface lo inet loopback

# DMZ
auto eth0
iface eth0 inet static
    address 10.0.0.46
    netmask 255.255.255.240
    gateway 10.0.0.33

# Internal
auto eth1
iface eth1 inet static
    address 10.0.0.1
    netmask 255.255.255.224

# Management
auto eth2
iface eth2 inet static
    address 10.0.0.49
    netmask 255.255.255.248
EOF

# ---------------------------------------------------------
# 9. Enable IPv4 forwarding permanently
# ---------------------------------------------------------

mkdir -p "$MOUNT_POINT/etc/sysctl.d"

cat > "$MOUNT_POINT/etc/sysctl.d/99-router.conf" <<'EOF'
# FW2 works as an IPv4 router
net.ipv4.ip_forward = 1
EOF

# ---------------------------------------------------------
# 10. Set the permanent root password
# ---------------------------------------------------------

echo "[7/9] Setting permanent root password..."

ROOT_HASH=$(printf '%s\n' "$FW_PASSWORD" | openssl passwd -6 -stdin)

unset FW_PASSWORD

SHADOW="$MOUNT_POINT/etc/shadow"
SHADOW_TMP="$MOUNT_POINT/etc/shadow.new"

awk -F: \
    -v OFS=: \
    -v hash="$ROOT_HASH" \
    '$1 == "root" {$2 = hash} {print}' \
    "$SHADOW" > "$SHADOW_TMP"

chown --reference="$SHADOW" "$SHADOW_TMP"
chmod --reference="$SHADOW" "$SHADOW_TMP"

mv "$SHADOW_TMP" "$SHADOW"

unset ROOT_HASH

# ---------------------------------------------------------
# 11. Preserve temporary SSH administration
# ---------------------------------------------------------

echo "[8/9] Preparing SSH..."

SSHD_CONFIG="$MOUNT_POINT/etc/ssh/sshd_config"

sed -i \
    -e '/^[#[:space:]]*PermitRootLogin[[:space:]]/d' \
    -e '/^[#[:space:]]*PasswordAuthentication[[:space:]]/d' \
    "$SSHD_CONFIG"

{
    echo "PermitRootLogin yes"
    echo "PasswordAuthentication yes"
    cat "$SSHD_CONFIG"
} > "$SSHD_CONFIG.new"

chown --reference="$SSHD_CONFIG" "$SSHD_CONFIG.new"
chmod --reference="$SSHD_CONFIG" "$SSHD_CONFIG.new"

mv "$SSHD_CONFIG.new" "$SSHD_CONFIG"

# Ensure SSH and networking start automatically

mkdir -p "$MOUNT_POINT/etc/runlevels/default"
mkdir -p "$MOUNT_POINT/etc/runlevels/boot"

ln -sf /etc/init.d/sshd \
    "$MOUNT_POINT/etc/runlevels/default/sshd"

ln -sf /etc/init.d/networking \
    "$MOUNT_POINT/etc/runlevels/boot/networking"

echo
echo "Final FW2 network configuration:"
echo "----------------------------------------"
cat "$MOUNT_POINT/etc/network/interfaces"
echo "----------------------------------------"

echo
echo "IPv4 forwarding:"
cat "$MOUNT_POINT/etc/sysctl.d/99-router.conf"

echo
echo "SSH configuration:"
grep -E \
    '^(PermitRootLogin|PasswordAuthentication)' \
    "$SSHD_CONFIG"

# ---------------------------------------------------------
# 12. Safely close the disk
# ---------------------------------------------------------

sync

umount "$MOUNT_POINT"
qemu-nbd --disconnect "$NBD"

trap - EXIT INT TERM

# ---------------------------------------------------------
# 13. Start FW2
# ---------------------------------------------------------

echo "[9/9] Starting FW2..."

virsh -c qemu:///system start "$DOMAIN"

echo "Waiting for Alpine to boot..."
sleep 20

echo
echo "FW2 state:"
virsh -c qemu:///system domstate "$DOMAIN"

echo
echo "FW2 interfaces:"
virsh -c qemu:///system domiflist "$DOMAIN"

echo
echo "======================================"
echo "FW2 offline configuration completed"
echo "======================================"
echo
echo "DMZ:        10.0.0.46/28"
echo "Gateway:    10.0.0.33"
echo "Internal:   10.0.0.1/27"
echo "Management: 10.0.0.49/29"
echo "Forwarding: enabled"
echo
echo "The next step is connectivity testing."
