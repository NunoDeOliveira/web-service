#!/usr/bin/env bash
set -euo pipefail

DOMAIN="fw1"
DISK="/var/lib/libvirt/images/fw1.qcow2"

NBD="/dev/nbd0"
ROOT_PART="/dev/nbd0p3"
MOUNT_POINT="/mnt/fw1"

LIBVIRT_NETWORK="default"

WAN_MAC="52:54:00:94:d2:72"
WAN_IP="192.168.122.2"

echo "=== FW1 offline network configuration ==="

# ---------------------------------------------------------
# 1. This script must run as root
# ---------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

# ---------------------------------------------------------
# 2. Stop FW1 before modifying its QCOW2 disk
# ---------------------------------------------------------

echo "[1/8] Checking FW1 state..."

STATE=$(virsh -c qemu:///system domstate "$DOMAIN" 2>/dev/null || true)

if [[ "$STATE" == "running" ]]; then
    echo "Stopping FW1..."
    virsh -c qemu:///system destroy "$DOMAIN"
else
    echo "FW1 is already stopped."
fi

# ---------------------------------------------------------
# 3. Check that 192.168.122.2 is not used by another VM
# ---------------------------------------------------------

echo "[2/8] Checking WAN address..."

CONFLICT=$(
    virsh -c qemu:///system net-dhcp-leases "$LIBVIRT_NETWORK" |
    awk -v ip="${WAN_IP}/24" -v mac="$WAN_MAC" \
        '$5 == ip && $3 != mac {print}'
)

if [[ -n "$CONFLICT" ]]; then
    echo "ERROR: $WAN_IP is already used by another MAC:"
    echo "$CONFLICT"
    exit 1
fi

# ---------------------------------------------------------
# 4. Create persistent DHCP reservation for FW1
# ---------------------------------------------------------

echo "[3/8] Checking FW1 DHCP reservation..."

EXISTING_HOST=$(
    virsh -c qemu:///system net-dumpxml "$LIBVIRT_NETWORK" |
    grep -F "$WAN_MAC" || true
)

if [[ -n "$EXISTING_HOST" ]]; then

    if echo "$EXISTING_HOST" | grep -F "$WAN_IP" >/dev/null; then
        echo "DHCP reservation already correct:"
        echo "$WAN_MAC -> $WAN_IP"
    else
        echo "ERROR: FW1 MAC already has another static DHCP definition:"
        echo "$EXISTING_HOST"
        exit 1
    fi

else

    virsh -c qemu:///system net-update "$LIBVIRT_NETWORK" \
        add ip-dhcp-host \
        "<host mac='$WAN_MAC' name='fw1' ip='$WAN_IP'/>" \
        --live --config

    echo "DHCP reservation created:"
    echo "$WAN_MAC -> $WAN_IP"
fi

# ---------------------------------------------------------
# 5. Connect and mount the Alpine QCOW2 disk
# ---------------------------------------------------------

echo "[4/8] Mounting FW1 disk..."

modprobe nbd max_part=8

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

# Verify that this is really Alpine
if ! grep -q 'ID=alpine' "$MOUNT_POINT/etc/os-release"; then
    echo "ERROR: Alpine Linux root filesystem was not found."
    exit 1
fi

echo "Alpine Linux root filesystem found."

# ---------------------------------------------------------
# 6. Backup the current configuration
# ---------------------------------------------------------

echo "[5/8] Creating configuration backup..."

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

echo "Backup created in:"
echo "/root/config-backup/$TIMESTAMP"

# ---------------------------------------------------------
# 7. Write the final FW1 network configuration
# ---------------------------------------------------------

echo "[6/8] Writing FW1 network configuration..."

cat > "$MOUNT_POINT/etc/network/interfaces" <<'EOF'
auto lo
iface lo inet loopback

# WAN
auto eth0
iface eth0 inet dhcp
    hostname fw1

# DMZ
auto eth1
iface eth1 inet static
    address 10.0.0.33
    netmask 255.255.255.240

    # Networks behind FW2
    up ip route replace 10.0.0.0/27 via 10.0.0.46 dev eth1
    up ip route replace 10.0.0.48/29 via 10.0.0.46 dev eth1
EOF

# ---------------------------------------------------------
# 8. Enable IPv4 forwarding permanently
# ---------------------------------------------------------

mkdir -p "$MOUNT_POINT/etc/sysctl.d"

cat > "$MOUNT_POINT/etc/sysctl.d/99-router.conf" <<'EOF'
# FW1 works as an IPv4 router
net.ipv4.ip_forward = 1
EOF

# ---------------------------------------------------------
# Check SSH configuration before starting the VM
# ---------------------------------------------------------

echo "[7/8] Checking SSH configuration..."

if ! grep -q '^PermitRootLogin yes' \
    "$MOUNT_POINT/etc/ssh/sshd_config"; then

    echo "ERROR: PermitRootLogin yes is not configured."
    exit 1
fi

if ! grep -q '^PasswordAuthentication yes' \
    "$MOUNT_POINT/etc/ssh/sshd_config"; then

    echo "ERROR: PasswordAuthentication yes is not configured."
    exit 1
fi

echo "SSH configuration is correct."

echo
echo "Final persistent network configuration:"
echo "----------------------------------------"
cat "$MOUNT_POINT/etc/network/interfaces"
echo "----------------------------------------"

# ---------------------------------------------------------
# 9. Safely close the QCOW2 image
# ---------------------------------------------------------

sync

umount "$MOUNT_POINT"
qemu-nbd --disconnect "$NBD"

trap - EXIT INT TERM

# ---------------------------------------------------------
# 10. Start FW1
# ---------------------------------------------------------

echo "[8/8] Starting FW1..."

virsh -c qemu:///system start "$DOMAIN"

echo "Waiting for Alpine to boot..."
sleep 20

echo
echo "DHCP lease:"
virsh -c qemu:///system net-dhcp-leases "$LIBVIRT_NETWORK" |
    grep -F "$WAN_MAC" || true

echo
echo "Testing $WAN_IP..."

if ping -c 2 -W 2 "$WAN_IP"; then

    echo
    echo "======================================"
    echo "FW1 network configuration SUCCESSFUL"
    echo "======================================"
    echo
    echo "WAN:        192.168.122.2/24"
    echo "Gateway:    192.168.122.1"
    echo "DMZ:        10.0.0.33/28"
    echo "Internal:   via 10.0.0.46"
    echo "Management: via 10.0.0.46"
    echo "Forwarding: enabled"
    echo

else

    echo
    echo "WARNING: FW1 did not answer ping."
    echo "Check the DHCP lease shown above."
fi
