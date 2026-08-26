# Firewall Security Policy

## 1. Purpose

This file explains how I defined and applied the security policies for the two firewalls.

I use FW1 as the configuration example. FW2 follows the same process, but it has different interfaces and security rules.

The firewall design uses:

- network segmentation;
- default deny policies;
- stateful filtering;
- controlled administrative access;
- NAT only on FW1;
- rules based on source, destination and service.

FW1 protects the DMZ from the External network.

FW2 protects the Internal and Management networks from the DMZ.

---

# 2. Firewall policy

Before writing firewall rules, I first defined which traffic must be allowed.

## FW1 — External ↔ DMZ

| Source | Destination | Service | Action | Reason |
|---|---|---|---|---|
| External | Web Server | HTTPS/443 | ALLOW | Public web service |
| External | Internal | ANY | DROP | No direct access |
| External | Management | ANY | DROP | Management must be isolated |
| Web Server | External | DNS 53 | ALLOW | DNS resolution |
| Web Server | External | NTP 123 | ALLOW | Time synchronisation |
| Web Server | External | HTTP/HTTPS | ALLOW | Updates and repositories |
| Management | FW1 | SSH 22 | ALLOW | Firewall administration |
| Established/Related | — | — | ALLOW | Valid return traffic |

The firewall uses a **default DROP policy**. Traffic is only allowed when there is a clear reason.

---

## FW2 — DMZ ↔ Internal / Management

| Source | Destination | Service | Action | Reason |
|---|---|---|---|---|
| DMZ | Management | ANY | DROP | Management must be protected |
| DMZ | Internal | ANY | DROP | A compromised DMZ server must not enter Internal |
| Management | Web Server | SSH 22 | ALLOW | Web Server administration |
| Management | FW1 | SSH 22 | ALLOW | FW1 administration |
| Management | FW2 | SSH 22 | ALLOW | FW2 administration |
| Management | Internal | Required admin services | ALLOW | System administration |
| Established/Related | — | — | ALLOW | Valid return traffic |

---

# 3. Prepare the Management workstation

Before enabling the firewall rules, I prepared my Ubuntu host as an **administration workstation**.

This was important because SSH access to FW1 must come from the Management network, not from the External network.

The Management network is:

```text
10.0.0.48/29
````

FW2 uses:

```text
10.0.0.49
```

The Admin workstation uses:

```text
10.0.0.50
```

The path to FW1 is:

```text
Admin workstation
10.0.0.50
      |
      | Management
      v
FW2 10.0.0.49
      |
      | routing
      v
FW2 DMZ 10.0.0.46
      |
      | DMZ
      v
FW1 10.0.0.33
```

## 3.1 Find the Management bridge

I checked which Linux bridge is used by the libvirt Management network:

```bash
virsh net-dumpxml management-net | grep bridge
```

Result:

```text
<bridge name='virbr50' stp='on' delay='0'/>
```

The Management network therefore uses `virbr50`.

---

## 3.2 Assign the Admin IP

I added the Admin address to the Management bridge:

```bash
sudo ip addr add 10.0.0.50/29 dev virbr50
```

I checked the result:

```bash
ip -br addr show virbr50
```

The bridge now has the Management address:

```text
10.0.0.50/29
```

This does not change the normal default route of my laptop.

---

## 3.3 Add routes through FW2

The DMZ and Internal networks are behind FW2.

I added a route to the DMZ:

```bash
sudo ip route add 10.0.0.32/28 via 10.0.0.49 dev virbr50
```

I added a route to the Internal network:

```bash
sudo ip route add 10.0.0.0/27 via 10.0.0.49 dev virbr50
```

I checked the routing table:

```bash
ip route
```

The important routes were:

```text
10.0.0.0/27 via 10.0.0.49 dev virbr50
10.0.0.32/28 via 10.0.0.49 dev virbr50
10.0.0.48/29 dev virbr50
```

My normal Internet default route was not changed.

---

## 3.4 Test Management routing

First, I tested the Management interface of FW2:

```bash
ping -c 3 10.0.0.49
```

Then I tested FW1 through FW2:

```bash
ping -c 3 10.0.0.33
```

I also tested the Web Server:

```bash
ping -c 3 10.0.0.34
```

All tests returned `0% packet loss`.

This confirmed that the Admin workstation could reach the DMZ through FW2.

---

# 4. Test SSH from Management

I connected to FW1 using its DMZ address:

```bash
ssh root@10.0.0.33
```

At this stage, root and password access were still temporary. They are used only while the firewall and secure management path are being built.

Inside FW1, I checked the source address of my SSH connection:

```bash
echo "$SSH_CLIENT"
```

Result:

```text
10.0.0.50 41258 22
```

This proved that FW1 received the SSH connection from the Admin workstation:

```text
10.0.0.50 → FW2 → FW1
```

This check was important before enabling a default DROP policy.

---

# 5. Install nftables on FW1

FW1 uses Alpine Linux.

I first updated the package index:

```bash
apk update
```

Then I installed nftables:

```bash
apk add nftables
```

This installed both:

* `nftables`;
* `nftables-openrc`.

I checked the installed version:

```bash
nft --version
```

Result:

```text
nftables v1.1.6
```

I also checked the configuration files:

```bash
ls -l /etc/nftables*
```

The main Alpine configuration file is:

```text
/etc/nftables.nft
```

---

# 6. Create the FW1 firewall configuration

I stored the rules in:

```text
/etc/nftables.nft
```

I opened the file:

```bash
vi /etc/nftables.nft
```

The configuration is:

```nft
#!/usr/sbin/nft -f

flush ruleset

define EXT_IF   = "eth0"
define DMZ_IF   = "eth1"

define EXT_IP   = 192.168.122.2
define WEB_IP   = 10.0.0.34
define ADMIN_IP = 10.0.0.50


table inet fw1_filter {

    chain input {
        type filter hook input priority 0;
        policy drop;

        # Local traffic
        iifname "lo" accept

        # Stateful firewall
        ct state invalid counter drop
        ct state { established, related } counter accept

        # FW1 receives its External address using DHCP
        iifname $EXT_IF udp sport 67 udp dport 68 counter accept

        # Management -> FW1 SSH
        iifname $DMZ_IF ip saddr $ADMIN_IP \
            tcp dport 22 ct state new counter accept
    }


    chain forward {
        type filter hook forward priority 0;
        policy drop;

        # Stateful firewall
        ct state invalid counter drop
        ct state { established, related } counter accept

        # External -> Internal: DENY
        iifname $EXT_IF ip daddr 10.0.0.0/27 counter drop

        # External -> Management: DENY
        iifname $EXT_IF ip daddr 10.0.0.48/29 counter drop

        # External -> Web Server HTTPS
        iifname $EXT_IF oifname $DMZ_IF \
            ip daddr $WEB_IP \
            tcp dport 443 ct state new counter accept

        # Web Server -> External DNS
        iifname $DMZ_IF oifname $EXT_IF \
            ip saddr $WEB_IP \
            meta l4proto { tcp, udp } th dport 53 \
            ct state new counter accept

        # Web Server -> External NTP
        iifname $DMZ_IF oifname $EXT_IF \
            ip saddr $WEB_IP \
            udp dport 123 ct state new counter accept

        # Web Server -> External HTTP/HTTPS
        iifname $DMZ_IF oifname $EXT_IF \
            ip saddr $WEB_IP \
            tcp dport { 80, 443 } \
            ct state new counter accept
    }
}


table ip fw1_nat {

    chain prerouting {
        type nat hook prerouting priority -100;

        # Publish Web Server HTTPS
        iifname $EXT_IF \
            ip daddr $EXT_IP \
            tcp dport 443 \
            counter dnat to 10.0.0.34:443
    }


    chain postrouting {
        type nat hook postrouting priority 100;

        # Dynamic PAT equivalent
        oifname $EXT_IF \
            ip saddr { 10.0.0.0/27, 10.0.0.32/28, 10.0.0.48/29 } \
            counter snat to $EXT_IP
    }
}
```

---

# 7. How the firewall rules work

## 7.1 Clear previous rules

```nft
flush ruleset
```

I clear the previous nftables configuration before loading the new rules.

This avoids keeping old or unknown rules.

---

## 7.2 Variables

```nft
define EXT_IF   = "eth0"
define DMZ_IF   = "eth1"

define EXT_IP   = 192.168.122.2
define WEB_IP   = 10.0.0.34
define ADMIN_IP = 10.0.0.50
```

I use variables to make the configuration easier to read and change.

---

# 8. INPUT chain

The `input` chain controls traffic whose destination is FW1 itself.

For example:

```text
Admin → FW1 SSH
```

The chain starts with:

```nft
policy drop;
```

This means traffic is blocked unless I allow it.

---

## 8.1 Local traffic

```nft
iifname "lo" accept
```

This allows local loopback communication inside FW1.

---

## 8.2 Invalid connections

```nft
ct state invalid counter drop
```

Packets that do not belong to a valid connection are dropped.

---

## 8.3 Established and related traffic

```nft
ct state { established, related } counter accept
```

This provides **stateful filtering**.

A valid response to an allowed connection can return through the firewall.

For example:

```text
Admin → FW1 SSH = NEW and allowed
FW1 → Admin SSH response = ESTABLISHED and allowed
```

A new connection in the opposite direction is not automatically allowed.

---

## 8.4 DHCP traffic

```nft
iifname $EXT_IF udp sport 67 udp dport 68 counter accept
```

FW1 receives its External address using DHCP.

This rule allows the required DHCP reply traffic.

---

## 8.5 Management SSH

```nft
iifname $DMZ_IF ip saddr $ADMIN_IP \
    tcp dport 22 ct state new counter accept
```

Only the Admin workstation `10.0.0.50` can start a new SSH connection to FW1.

The packet reaches FW1 through its DMZ interface because the Admin network is behind FW2.

---

# 9. FORWARD chain

The `forward` chain controls packets that **cross FW1**.

For example:

```text
External → Web Server
Web Server → External
```

It also uses:

```nft
policy drop;
```

Traffic that is not explicitly allowed is blocked.

---

## 9.1 Stateful forwarded traffic

```nft
ct state invalid counter drop
ct state { established, related } counter accept
```

Invalid traffic is dropped.

Valid return traffic from an allowed connection is accepted automatically.

---

## 9.2 Block External access to Internal

```nft
iifname $EXT_IF ip daddr 10.0.0.0/27 counter drop
```

The External network cannot directly access the Internal network.

---

## 9.3 Block External access to Management

```nft
iifname $EXT_IF ip daddr 10.0.0.48/29 counter drop
```

The External network cannot directly access Management.

---

## 9.4 Publish HTTPS

```nft
iifname $EXT_IF oifname $DMZ_IF \
    ip daddr $WEB_IP \
    tcp dport 443 ct state new counter accept
```

FW1 allows new HTTPS connections to the Web Server.

Only TCP port `443` is allowed for the public web service.

---

## 9.5 Allow DNS from the Web Server

```nft
iifname $DMZ_IF oifname $EXT_IF \
    ip saddr $WEB_IP \
    meta l4proto { tcp, udp } th dport 53 \
    ct state new counter accept
```

The Web Server can use DNS over TCP or UDP port `53`.

---

## 9.6 Allow NTP

```nft
iifname $DMZ_IF oifname $EXT_IF \
    ip saddr $WEB_IP \
    udp dport 123 ct state new counter accept
```

The Web Server can synchronise its clock using NTP.

---

## 9.7 Allow package and web access

```nft
iifname $DMZ_IF oifname $EXT_IF \
    ip saddr $WEB_IP \
    tcp dport { 80, 443 } \
    ct state new counter accept
```

The Web Server can use HTTP and HTTPS for updates and repositories.

It does not receive general unrestricted access to the External network.

---

# 10. NAT configuration

FW1 is also the NAT device.

FW2 does not perform NAT.

The NAT design has two functions:

1. publish the Web Server HTTPS service;
2. translate private addresses when systems access the External network.

---

## 10.1 HTTPS DNAT

The `prerouting` chain contains:

```nft
iifname $EXT_IF \
    ip daddr $EXT_IP \
    tcp dport 443 \
    counter dnat to 10.0.0.34:443
```

A connection sent to:

```text
192.168.122.2:443
```

is translated to:

```text
10.0.0.34:443
```

The External client does not connect directly to the private DMZ address.

The traffic path is:

```text
External client
      |
192.168.122.2:443
      |
     FW1
      |
      | DNAT
      v
10.0.0.34:443
Web Server
```

---

## 10.2 Outbound SNAT / PAT

The `postrouting` chain contains:

```nft
oifname $EXT_IF \
    ip saddr { 10.0.0.0/27, 10.0.0.32/28, 10.0.0.48/29 } \
    counter snat to $EXT_IP
```

Private addresses are translated to the FW1 External address:

```text
192.168.122.2
```

This provides the equivalent of **Dynamic PAT** used by routed firewalls.

Many private hosts can share the same External IPv4 address.

---

# 11. Validate the configuration before applying it

Before changing the active firewall, I checked the syntax:

```bash
nft -c -f /etc/nftables.nft
```

The `-c` option checks the configuration without applying it.

No error was returned.

This step reduces the risk of loading an invalid firewall configuration.

---

# 12. Apply the firewall

After the syntax check passed, I loaded the configuration:

```bash
nft -f /etc/nftables.nft
```

I did not close my existing SSH session immediately.

This is important when changing firewall rules remotely.

---

# 13. Check the active rules

I displayed the active ruleset:

```bash
nft list ruleset
```

The output showed:

* `policy drop` on `input`;
* `policy drop` on `forward`;
* stateful filtering;
* Management SSH;
* Web Server outbound rules;
* HTTPS DNAT;
* outbound SNAT.

The rules also use `counter`.

Counters show how many packets and bytes match each rule.

For example, DNS and NTP rules already showed packet matches after the firewall was loaded.

---

# 14. Test a second SSH connection

I kept the first SSH session open.

From another terminal on the Admin workstation, I started a new connection:

```bash
ssh root@10.0.0.33
```

The second SSH connection worked.

This was an important test because it proved that this rule was working:

```text
Admin 10.0.0.50 → FW1 TCP/22 = ALLOW
```

It also proved that I could still manage FW1 after enabling the default DROP policy.

LPIC-2 also recommends using more than one connection when making remote SSH changes, because this reduces the risk of losing access to the remote system. 

---

# 15. Make nftables persistent

The rules were first loaded manually.

I then enabled the nftables OpenRC service at boot:

```bash
rc-update add nftables default
```

I checked the boot configuration:

```bash
rc-update show | grep nftables
```

The firewall configuration is stored in:

```text
/etc/nftables.nft
```

After a later reboot, I can verify that the rules were restored with:

```bash
nft list ruleset
```

---

# 16. Security validation

The firewall must be tested from different network positions.

## Management → FW1 SSH

Expected result:

```text
ALLOW
```

Test:

```bash
ssh root@10.0.0.33
```

---

## External → FW1 SSH

Expected result:

```text
DROP
```

The External network must not be used for firewall administration.

---

## External → Web Server HTTPS

Expected result:

```text
ALLOW
```

The connection enters FW1 on:

```text
192.168.122.2:443
```

FW1 translates it to:

```text
10.0.0.34:443
```

---

## External → Internal

Expected result:

```text
DROP
```

---

## External → Management

Expected result:

```text
DROP
```

---

## Web Server → External

Only these services are allowed:

```text
DNS     TCP/UDP 53
NTP     UDP 123
HTTP    TCP 80
HTTPS   TCP 443
```

Other new connections are blocked by the default DROP policy.

---

# 17. Why I used stateful filtering

The firewall keeps information about active connections.

For example:

```text
Admin → Web Server SSH
```

is a new connection.

If this connection is allowed, the reply:

```text
Web Server → Admin
```

is part of the existing connection and can return.

However:

```text
Web Server → Admin NEW SSH connection
```

is a different connection.

It must have its own firewall rule or it is dropped.

This gives more control than simple packet filtering.

LPIC-2 describes this behaviour as connection tracking or stateful firewalling. 

---

# 18. INPUT, FORWARD and NAT

I used different chains for different jobs.

| Chain         | Purpose                           | Example                      |
| ------------- | --------------------------------- | ---------------------------- |
| `input`       | Traffic to FW1 itself             | Admin → FW1 SSH              |
| `forward`     | Traffic crossing FW1              | External → Web Server        |
| `prerouting`  | Change destination before routing | External HTTPS → Web Server  |
| `postrouting` | Change source before leaving      | Private IP → FW1 External IP |

LPIC-2 explains the same Netfilter model: INPUT controls packets for the firewall, FORWARD controls routed packets, and the NAT table uses PREROUTING and POSTROUTING for address translation.

---

# 19. FW2

FW2 follows the same general process:

1. define the traffic policy;
2. install nftables;
3. create the ruleset;
4. use default DROP;
5. allow established and related traffic;
6. allow only required Management traffic;
7. block DMZ access to Internal and Management;
8. validate with `nft -c`;
9. apply with `nft -f`;
10. test from a second SSH session;
11. enable nftables at boot;
12. validate the active rules and counters.

FW2 does **not** require NAT.

Its main role is network segmentation between:

```text
DMZ
Internal
Management
```

---

# 20. Result

FW1 is now a routed and stateful Linux firewall.

It provides:

* default deny filtering;
* stateful connection tracking;
* External to DMZ filtering;
* protected Management SSH access;
* HTTPS publishing with DNAT;
* outbound SNAT/PAT;
* traffic counters;
* persistent nftables configuration.

The important point is not only that nftables is installed.

The firewall rules are based on a defined traffic policy, each allowed service has a reason, and the configuration can be tested from different network zones.



### Sources

- **LPIC-2 Exam Prep — Topic 212: System Security, Objective 212.1 — Configuring a Router; section 54.3 “The Linux firewall, an overview”**. Includes filtering chains, NAT and stateful connection tracking. 
- **LPIC-2 Exam Prep — Objective 212.3 — Secure Shell (SSH), sections 56.1–56.4**. Includes SSH administration and the use of multiple connections during remote configuration changes. :contentReference[oaicite:6]{index=6}
- **LPIC-2 Exam Prep — Topic 205: Networking Configuration, Objectives 205.1–205.3**. Routing, network configuration and troubleshooting. :contentReference[oaicite:7]{index=7}
- **LPIC-1 102 — Objective 110.3: Securing Data with Encryption**. OpenSSH remote administration and secure connections. :contentReference[oaicite:8]{index=8}

One technical distinction is worth keeping clear in the project: **LPIC-2 material explains these concepts mainly with iptables/Netfilter, while your implementation uses nftables.** The underlying concepts—INPUT, FORWARD, NAT and connection tracking—are the part being applied here.

                      |

