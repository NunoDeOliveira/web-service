#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

FW2_IP="10.0.0.49"
ADMIN_IP="10.0.0.50"
NFT_FILE="$REPO_ROOT/components/fw2/nftables/nftables.conf"

echo "========================================"
echo " FW2 firewall deployment"
echo "========================================"


# 0. Check Admin workstation route
echo
echo "=== Checking Management access ==="

if ! ip route get "$FW2_IP" | grep -q "src $ADMIN_IP"; then
    echo "ERROR: Ubuntu is not reaching FW2 from Admin IP $ADMIN_IP."
    echo "Check the Management workstation configuration."
    exit 1
fi

echo "Admin workstation: OK"



# 1. Create nftables configuration in the repository
mkdir -p "$REPO_ROOT/components/fw2/nftables"

cat > "$NFT_FILE" <<'NFT'
#!/usr/sbin/nft -f

flush ruleset

define DMZ_IF    = "eth0"
define INT_IF    = "eth1"
define MGMT_IF   = "eth2"

define FW1_IP    = 10.0.0.33
define WEB_IP    = 10.0.0.34
define ADMIN_IP  = 10.0.0.50

define DMZ_NET   = 10.0.0.32/28
define INT_NET   = 10.0.0.0/27
define MGMT_NET  = 10.0.0.48/29


table inet fw2_filter {

    chain input {
        type filter hook input priority 0;
        policy drop;

        # Local traffic
        iifname "lo" accept

        # Stateful firewall
        ct state invalid counter drop
        ct state { established, related } counter accept

        # Admin -> FW2 SSH
        iifname $MGMT_IF \
            ip saddr $ADMIN_IP \
            tcp dport 22 \
            ct state new counter accept

        # Admin -> FW2 ICMP
        iifname $MGMT_IF \
            ip saddr $ADMIN_IP \
            icmp type echo-request \
            counter accept
    }


    chain forward {
        type filter hook forward priority 0;
        policy drop;

        # Stateful firewall
        ct state invalid counter drop
        ct state { established, related } counter accept


        # -------------------------------------------------
        # DMZ isolation
        # -------------------------------------------------

        # DMZ -> Management
        iifname $DMZ_IF oifname $MGMT_IF \
            counter drop

        # DMZ -> Internal
        iifname $DMZ_IF oifname $INT_IF \
            counter drop


        # -------------------------------------------------
        # Management administration
        # -------------------------------------------------

        # Admin -> Web Server SSH
        iifname $MGMT_IF oifname $DMZ_IF \
            ip saddr $ADMIN_IP \
            ip daddr $WEB_IP \
            tcp dport 22 \
            ct state new counter accept

        # Admin -> FW1 SSH
        iifname $MGMT_IF oifname $DMZ_IF \
            ip saddr $ADMIN_IP \
            ip daddr $FW1_IP \
            tcp dport 22 \
            ct state new counter accept

        # Admin -> DMZ ICMP
        iifname $MGMT_IF oifname $DMZ_IF \
            ip saddr $ADMIN_IP \
            ip daddr $DMZ_NET \
            icmp type echo-request \
            counter accept

        # Admin -> Internal SSH
        iifname $MGMT_IF oifname $INT_IF \
            ip saddr $ADMIN_IP \
            ip daddr $INT_NET \
            tcp dport 22 \
            ct state new counter accept

        # Admin -> Internal ICMP
        iifname $MGMT_IF oifname $INT_IF \
            ip saddr $ADMIN_IP \
            ip daddr $INT_NET \
            icmp type echo-request \
            counter accept


        # -------------------------------------------------
        # Internal isolation
        # -------------------------------------------------

        # Internal -> DMZ
        iifname $INT_IF oifname $DMZ_IF \
            ip daddr $DMZ_NET \
            counter drop


        # -------------------------------------------------
        # Internal -> External through FW1
        # Only required services are allowed
        # -------------------------------------------------

        # DNS UDP
        iifname $INT_IF oifname $DMZ_IF \
            ip saddr $INT_NET \
            udp dport 53 \
            ct state new counter accept

        # DNS TCP
        iifname $INT_IF oifname $DMZ_IF \
            ip saddr $INT_NET \
            tcp dport 53 \
            ct state new counter accept

        # NTP
        iifname $INT_IF oifname $DMZ_IF \
            ip saddr $INT_NET \
            udp dport 123 \
            ct state new counter accept

        # HTTP / HTTPS
        iifname $INT_IF oifname $DMZ_IF \
            ip saddr $INT_NET \
            tcp dport { 80, 443 } \
            ct state new counter accept
    }
}
NFT

echo "[1/7] nftables.conf created"


# ------------------------------------------------------------
# 2. Copy configuration to FW2
# ------------------------------------------------------------

echo
echo "=== Copying firewall configuration ==="

scp "$NFT_FILE" root@"$FW2_IP":/tmp/fw2.nftables.nft

echo "[2/7] Configuration copied"


# ------------------------------------------------------------
# 3. Configure FW2
# ------------------------------------------------------------

ssh root@"$FW2_IP" 'sh -s' <<'REMOTE'

set -eu

echo
echo "========================================"
echo " FW2 remote configuration"
echo "========================================"


# ------------------------------------------------------------
# Network verification
# ------------------------------------------------------------

echo
echo "=== Network configuration ==="

ip addr
ip route
sysctl net.ipv4.ip_forward

if [ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]; then
    echo "ERROR: IPv4 forwarding is disabled."
    exit 1
fi


# ------------------------------------------------------------
# DNS
# ------------------------------------------------------------

echo
echo "=== Configuring DNS ==="

if [ ! -f /etc/resolv.conf.before-firewall ]; then
    cp /etc/resolv.conf /etc/resolv.conf.before-firewall 2>/dev/null || true
fi

cat > /etc/resolv.conf <<'DNS'
nameserver 1.1.1.1
nameserver 8.8.8.8
DNS

cat /etc/resolv.conf


# ------------------------------------------------------------
# Test real repository connectivity
# ------------------------------------------------------------

echo
echo "=== Testing DNS and repository access ==="

if ! apk update; then
    echo
    echo "ERROR: apk update failed."
    echo "FW2 cannot reach Alpine repositories."
    echo
    echo "Check FW1 rules for:"
    echo "  10.0.0.46 -> DNS 53"
    echo "  10.0.0.46 -> HTTP 80"
    echo "  10.0.0.46 -> HTTPS 443"
    exit 1
fi

echo "DNS and repository access: OK"


# ------------------------------------------------------------
# Install nftables
# ------------------------------------------------------------

echo
echo "=== Installing nftables ==="

apk add nftables

echo
nft --version


# ------------------------------------------------------------
# Validate before applying
# ------------------------------------------------------------

echo
echo "=== Validating nftables configuration ==="

nft -c -f /tmp/fw2.nftables.nft

echo "nftables syntax: OK"


# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

echo
echo "=== Creating backup ==="

if [ -s /etc/nftables.nft ]; then
    cp /etc/nftables.nft /etc/nftables.nft.bak
    echo "Backup: /etc/nftables.nft.bak"
else
    echo "No previous active configuration to back up."
fi


# ------------------------------------------------------------
# Install final configuration
# ------------------------------------------------------------

echo
echo "=== Installing firewall configuration ==="

cp /tmp/fw2.nftables.nft /etc/nftables.nft


# ------------------------------------------------------------
# Apply firewall
# ------------------------------------------------------------

echo
echo "=== Applying FW2 firewall ==="

nft -f /etc/nftables.nft


# ------------------------------------------------------------
# Persistence
# ------------------------------------------------------------

echo
echo "=== Enabling nftables at boot ==="

rc-update add nftables boot

echo
rc-update show | grep nftables || true


# ------------------------------------------------------------
# Show active firewall
# ------------------------------------------------------------

echo
echo "=== Active FW2 rules ==="

nft list ruleset


echo
echo "========================================"
echo " FW2 FIREWALL APPLIED"
echo "========================================"

REMOTE


echo "[3/7] DNS and repository access checked"
echo "[4/7] nftables installed"
echo "[5/7] Configuration validated"
echo "[6/7] Firewall applied and enabled at boot"


# ------------------------------------------------------------
# 4. Test a completely NEW SSH connection
# ------------------------------------------------------------

echo
echo "========================================"
echo " Testing NEW Management SSH connection"
echo "========================================"

ssh root@"$FW2_IP" '
echo
echo "New SSH connection: OK"
echo "SSH source:"
echo "$SSH_CLIENT"
echo
echo "Firewall:"
nft list table inet fw2_filter >/dev/null
echo "FW2 nftables: ACTIVE"
'

echo "[7/7] New Management SSH connection: OK"


echo
echo "========================================"
echo " FW2 DEPLOYMENT FINISHED SUCCESSFULLY"
echo "========================================"
echo
echo "Expected architecture:"
echo
echo " Admin 10.0.0.50"
echo "        |"
echo " Management"
echo "        |"
echo " FW2 10.0.0.49"
echo "   /          \\"
echo "Internal      DMZ"
echo
echo "FW2:"
echo "  DMZ -> Internal       DROP"
echo "  DMZ -> Management     DROP"
echo "  Internal -> DMZ       DROP"
echo "  Admin -> FW1/Web      controlled"
echo "  Internal -> Internet  DNS/NTP/HTTP/HTTPS"
echo "  Default policy        DROP"
echo
