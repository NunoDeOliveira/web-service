# Firewall Network Configuration

This document explains how I configure the network of the two Alpine Linux firewalls and connect the web server to the DMZ.

The objective is to create four separated network zones:

- WAN
- DMZ
- Internal
- Management

At this stage, I configure IP addresses, routes and IPv4 forwarding. Firewall filtering and NAT are configured in the next stage.

---

## 1. Network addressing plan

I use the following subnets:

| Network | Subnet | Mask | Usable hosts |
| --- | --- | --- | ---: |
| WAN | `192.168.122.0/24` | `255.255.255.0` | libvirt network |
| Internal | `10.0.0.0/27` | `255.255.255.224` | 30 |
| DMZ | `10.0.0.32/28` | `255.255.255.240` | 14 |
| Management | `10.0.0.48/29` | `255.255.255.248` | 6 |

The final IP plan is:

| Device | Interface | IP |
| --- | --- | --- |
| libvirt gateway | WAN | `192.168.122.1/24` |
| FW1 | WAN | DHCP - `192.168.122.x/24` |
| FW1 | DMZ | `10.0.0.33/28` |
| Web Server | DMZ | `10.0.0.34/28` |
| FW2 | DMZ | `10.0.0.46/28` |
| FW2 | Internal | `10.0.0.1/27` |
| Developer | Internal | `10.0.0.2/27` |
| Database | Internal | `10.0.0.3/27` |
| FW2 | Management | `10.0.0.49/29` |
| Admin | Management | `10.0.0.50/29` |
| Operator | Management | `10.0.0.51/29` |

FW1 controls traffic between the WAN and DMZ.

FW2 controls traffic between the DMZ, Internal and Management networks.

The private libvirt networks are separate Layer 2 networks. VLAN tagging is not used in this version.

---

## 2. Check the libvirt networks

I first check that all required virtual networks exist.

I run these commands on the Ubuntu host:

```bash
virsh net-list --all
```

also ckeck the configurations of every private network:

```bash
virsh net-dumpxml web-dmz
virsh net-dumpxml internal-net
virsh net-dumpxml management-net
```

## 3. Check the firewall NICs

Before assigning IP addresses, I check which virtual network is connected to each firewall NIC.

From the Ubuntu host:

```bash
virsh domiflist fw1
```

The expected design is:

- eth0 → WAN / default
- eth1 → DMZ / web-dmz

I also check FW2:

```bash
virsh domiflist fw2
```

The expected design is:

- eth0 → DMZ / web-dmz
- eth1 → Internal / internal-net
- eth2 → Management / management-net


### 4.1 Check the current configuration

Inside FW1:

```bash
hostname
ip link
ip addr
ip route
```

- hostname confirms that I am working on the correct firewall.
- ip link shows the network interfaces and their MAC addresses.
- ip addr shows the current IP addresses.
- ip route shows the routing table and the default gateway.


### 4.2 Backup the current network configuration

Alpine stores the persistent interface configuration in `/etc/network/interfaces`

Before changing it, I create a backup:

```bash
cp /etc/network/interfaces /etc/network/interfaces.backup
```

I check the original file:

```bash
cat /etc/network/interfaces
```


### 4.3 Configure the FW1 interfaces

I edit:

vi /etc/network/interfaces

I configure FW1 with:

```bash
auto lo
iface lo inet loopback

# WAN
auto eth0
iface eth0 inet dhcp
    hostname fw1

#DMZ
auto eth1
iface eth1 inet static
    address 10.0.0.33
    netmask 255.255.255.240

    # Routes to networks behind FW2
    up ip route add 10.0.0.0/27 via 10.0.0.46 dev eth1
    up ip route add 10.0.0.48/29 via 10.0.0.46 dev eth1
```


FW1 keeps DHCP on the WAN interface because the libvirt default network provides this address.

The DMZ address is static:

10.0.0.33/28

I also add two static routes:

10.0.0.0/27  → 10.0.0.46
10.0.0.48/29 → 10.0.0.46

10.0.0.46 is the DMZ interface of FW2.

FW1 therefore knows that the Internal and Management networks are behind FW2.



### 4.4 Restart networking

I apply the configuration:

rc-service networking restart

Alpine uses the OpenRC networking service to apply /etc/network/interfaces.

I also check that networking starts automatically during boot:

rc-update show | grep networking

If required:

rc-update add networking boot


### 4.5 Verify FW1

I check the interfaces again:

ip addr

I expect to see:

eth0 → 192.168.122.x/24
eth1 → 10.0.0.33/28

I check the routing table:

ip route

I expect routes similar to:

default via 192.168.122.1 dev eth0
10.0.0.32/28 dev eth1
10.0.0.0/27 via 10.0.0.46 dev eth1
10.0.0.48/29 via 10.0.0.46 dev eth1

I test the WAN gateway:

ping -c 3 192.168.122.1

This confirms that FW1 can reach the libvirt gateway.



5. Configure FW2
5.1 Check the current interfaces

Inside FW2:

hostname
ip link
ip addr
ip route

I verify the three interfaces before assigning IP addresses.

The design is:

eth0 → DMZ
eth1 → Internal
eth2 → Management
5.2 Backup the configuration
cp /etc/network/interfaces /etc/network/interfaces.backup

I check the current file:

cat /etc/network/interfaces
5.3 Configure the FW2 interfaces

I edit:

vi /etc/network/interfaces

I configure:

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

FW2 is directly connected to three networks:

DMZ        → 10.0.0.32/28
Internal   → 10.0.0.0/27
Management → 10.0.0.48/29

Its default gateway is FW1:

10.0.0.33

This means that traffic for other networks is sent from FW2 to FW1.

5.4 Restart networking
rc-service networking restart

I verify the service:

rc-service networking status

I also check its boot configuration:

rc-update show | grep networking
5.5 Verify FW2
ip addr

I expect:

eth0 → 10.0.0.46/28
eth1 → 10.0.0.1/27
eth2 → 10.0.0.49/29

I check the routes:

ip route

I expect:

default via 10.0.0.33 dev eth0
10.0.0.32/28 dev eth0
10.0.0.0/27 dev eth1
10.0.0.48/29 dev eth2

These three private routes are automatically created because FW2 is directly connected to these networks.

6. Enable IPv4 forwarding

FW1 and FW2 are not normal end hosts. They must route packets between their network interfaces.

Linux does not forward IPv4 packets between interfaces unless IP forwarding is enabled.

I configure this on both FW1 and FW2.

First I check the current value:

sysctl net.ipv4.ip_forward

A value of 0 means that forwarding is disabled.

I edit:

vi /etc/sysctl.conf

I add:

# Enable IPv4 routing
net.ipv4.ip_forward=1

I load the new kernel setting:

sysctl -p

I verify it:

sysctl net.ipv4.ip_forward

The expected result is:

net.ipv4.ip_forward = 1

I also check that the sysctl service is available at boot:

rc-update show | grep sysctl

If required:

rc-update add sysctl boot

I repeat this configuration on FW1 and FW2.

IPv4 forwarding allows the Linux systems to work as routers.

Firewall rules will later decide which forwarded packets are allowed or blocked.

7. First routing tests

At this point, I test only basic network communication.

Firewall filtering and NAT are not configured yet.

FW1 to FW2

From FW1:

ping -c 3 10.0.0.46

This checks communication between both firewall DMZ interfaces.

FW2 to FW1

From FW2:

ping -c 3 10.0.0.33

This tests the same DMZ path in the opposite direction.






## Resources

[1] Linux Professional Institute, LPIC-2 Objectives, Topic 203, “Advanced Networking Configuration,” Objectives 203.1–203.3.

[2] Linux Professional Institute, LPIC-2 Objectives, Topic 211, “Network Security,” Objective 211.1, “Routing and Packet Filtering.”

[3] Linux Professional Institute, LPIC-1 Learning Materials, Topic 109, “Networking Fundamentals,” Objective 109.2, “Persistent Network Configuration.”

[4] Alpine Linux, “Configure Networking,” Alpine Linux Wiki, sections “Static address configuration” and “Networking service.”

[5] Alpine Linux, “How to configure static routes,” Alpine Linux Wiki, section “Set up routes in /etc/network/interfaces.”

[6] Alpine Linux, “Setting up a Home Router,” Alpine Linux Wiki, section “Enable Routing and Set Up Routes.”

[7] Netplan, “YAML Configuration,” sections “Routing” and “Default routes.”

[8] libvirt Project, “Network XML Format,” sections “Connectivity” and “Isolated network config.”

[9] libvirt Project, “virsh,” commands net-list, net-dumpxml and domiflist.




















Sí. Te lo dejo **listo para pegar en el README secundario** y, al mismo tiempo, para seguirlo como guía de ejecución. Separa esta fase de `nftables/NAT`: primero dejamos **NICs + IPs + rutas + forwarding** correctos; después construiremos la política de firewall.

````markdown
# Firewall Network Configuration

This document explains how I configure the network of the two Alpine Linux firewalls and connect the web server to the DMZ.

The objective is to create four separated network zones:

- WAN
- DMZ
- Internal
- Management

At this stage, I configure IP addresses, routes and IPv4 forwarding. Firewall filtering and NAT are configured in the next stage.

---

## 1. Network addressing plan

I use the following subnets:

| Network | Subnet | Mask | Usable hosts |
| --- | --- | --- | ---: |
| WAN | `192.168.122.0/24` | `255.255.255.0` | libvirt network |
| Internal | `10.0.0.0/27` | `255.255.255.224` | 30 |
| DMZ | `10.0.0.32/28` | `255.255.255.240` | 14 |
| Management | `10.0.0.48/29` | `255.255.255.248` | 6 |

The final IP plan is:

| Device | Interface | IP |
| --- | --- | --- |
| libvirt gateway | WAN | `192.168.122.1/24` |
| FW1 | WAN | DHCP - `192.168.122.x/24` |
| FW1 | DMZ | `10.0.0.33/28` |
| Web Server | DMZ | `10.0.0.34/28` |
| FW2 | DMZ | `10.0.0.46/28` |
| FW2 | Internal | `10.0.0.1/27` |
| Developer | Internal | `10.0.0.2/27` |
| Database | Internal | `10.0.0.3/27` |
| FW2 | Management | `10.0.0.49/29` |
| Admin | Management | `10.0.0.50/29` |
| Operator | Management | `10.0.0.51/29` |

FW1 controls traffic between the WAN and DMZ.

FW2 controls traffic between the DMZ, Internal and Management networks.

The private libvirt networks are separate Layer 2 networks. VLAN tagging is not used in this version.

---

## 2. Check the libvirt networks

I first check that all required virtual networks exist.

I run these commands on the Ubuntu host:

```bash
virsh net-list --all
````

This command shows all libvirt networks and their current state.

The expected networks are:

```text
default
web-dmz
internal-net
management-net
```

I also check the configuration of every private network:

```bash
virsh net-dumpxml web-dmz
virsh net-dumpxml internal-net
virsh net-dumpxml management-net
```

These commands show the XML configuration used by libvirt.

The three private networks must not provide an unwanted route that can bypass FW1 or FW2.

---

## 3. Check the firewall NICs

Before assigning IP addresses, I check which virtual network is connected to each firewall NIC.

From the Ubuntu host:

```bash
virsh domiflist fw1
```

FW1 must have:

```text
default
web-dmz
```

The expected design is:

```text
eth0 → WAN / default
eth1 → DMZ / web-dmz
```

I also check FW2:

```bash
virsh domiflist fw2
```

FW2 must have:

```text
web-dmz
internal-net
management-net
```

The expected design is:

```text
eth0 → DMZ / web-dmz
eth1 → Internal / internal-net
eth2 → Management / management-net
```

I compare the MAC addresses shown by `virsh domiflist` with the MAC addresses inside Alpine:

```bash
ip link
```

This check prevents me from assigning an IP address to the wrong security zone.

---

# 4. Configure FW1

## 4.1 Check the current configuration

Inside FW1:

```bash
hostname
ip link
ip addr
ip route
```

`hostname` confirms that I am working on the correct firewall.

`ip link` shows the network interfaces and their MAC addresses.

`ip addr` shows the current IP addresses.

`ip route` shows the routing table and the default gateway.

FW1 currently receives its WAN address from the libvirt `default` network.

For example:

```text
default via 192.168.122.1 dev eth0
192.168.122.0/24 dev eth0
```

The WAN gateway is therefore:

```text
192.168.122.1
```

The WAN address of FW1 is provided by DHCP.

---

## 4.2 Backup the current network configuration

Alpine stores the persistent interface configuration in:

```text
/etc/network/interfaces
```

Before changing it, I create a backup:

```bash
cp /etc/network/interfaces /etc/network/interfaces.backup
```

I check the original file:

```bash
cat /etc/network/interfaces
```

---

## 4.3 Configure the FW1 interfaces

I edit:

```bash
vi /etc/network/interfaces
```

I configure FW1 with:

```text
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

    # Routes to networks behind FW2
    up ip route add 10.0.0.0/27 via 10.0.0.46 dev eth1
    up ip route add 10.0.0.48/29 via 10.0.0.46 dev eth1
```

FW1 keeps DHCP on the WAN interface because the libvirt `default` network provides this address.

The DMZ address is static:

```text
10.0.0.33/28
```

I also add two static routes:

```text
10.0.0.0/27  → 10.0.0.46
10.0.0.48/29 → 10.0.0.46
```

`10.0.0.46` is the DMZ interface of FW2.

FW1 therefore knows that the Internal and Management networks are behind FW2.

---

## 4.4 Restart networking

I apply the configuration:

```bash
rc-service networking restart
```

Alpine uses the OpenRC networking service to apply `/etc/network/interfaces`.

I also check that networking starts automatically during boot:

```bash
rc-update show | grep networking
```

If required:

```bash
rc-update add networking boot
```

---

## 4.5 Verify FW1

I check the interfaces again:

```bash
ip addr
```

I expect to see:

```text
eth0 → 192.168.122.x/24
eth1 → 10.0.0.33/28
```

I check the routing table:

```bash
ip route
```

I expect routes similar to:

```text
default via 192.168.122.1 dev eth0
10.0.0.32/28 dev eth1
10.0.0.0/27 via 10.0.0.46 dev eth1
10.0.0.48/29 via 10.0.0.46 dev eth1
```

I test the WAN gateway:

```bash
ping -c 3 192.168.122.1
```

This confirms that FW1 can reach the libvirt gateway.

---

# 5. Configure FW2

## 5.1 Check the current interfaces

Inside FW2:

```bash
hostname
ip link
ip addr
ip route
```

I verify the three interfaces before assigning IP addresses.

The design is:

```text
eth0 → DMZ
eth1 → Internal
eth2 → Management
```

---

## 5.2 Backup the configuration

```bash
cp /etc/network/interfaces /etc/network/interfaces.backup
```

I check the current file:

```bash
cat /etc/network/interfaces
```

---

## 5.3 Configure the FW2 interfaces

I edit:

```bash
vi /etc/network/interfaces
```

I configure:

```text
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
```

FW2 is directly connected to three networks:

```text
DMZ        → 10.0.0.32/28
Internal   → 10.0.0.0/27
Management → 10.0.0.48/29
```

Its default gateway is FW1:

```text
10.0.0.33
```

This means that traffic for other networks is sent from FW2 to FW1.

---

## 5.4 Restart networking

```bash
rc-service networking restart
```

I verify the service:

```bash
rc-service networking status
```

I also check its boot configuration:

```bash
rc-update show | grep networking
```

---

## 5.5 Verify FW2

```bash
ip addr
```

I expect:

```text
eth0 → 10.0.0.46/28
eth1 → 10.0.0.1/27
eth2 → 10.0.0.49/29
```

I check the routes:

```bash
ip route
```

I expect:

```text
default via 10.0.0.33 dev eth0
10.0.0.32/28 dev eth0
10.0.0.0/27 dev eth1
10.0.0.48/29 dev eth2
```

These three private routes are automatically created because FW2 is directly connected to these networks.

---

# 6. Enable IPv4 forwarding

FW1 and FW2 are not normal end hosts. They must route packets between their network interfaces.

Linux does not forward IPv4 packets between interfaces unless IP forwarding is enabled.

I configure this on both FW1 and FW2.

First I check the current value:

```bash
sysctl net.ipv4.ip_forward
```

A value of `0` means that forwarding is disabled.

I edit:

```bash
vi /etc/sysctl.conf
```

I add:

```text
# Enable IPv4 routing
net.ipv4.ip_forward=1
```

I load the new kernel setting:

```bash
sysctl -p
```

I verify it:

```bash
sysctl net.ipv4.ip_forward
```

The expected result is:

```text
net.ipv4.ip_forward = 1
```

I also check that the `sysctl` service is available at boot:

```bash
rc-update show | grep sysctl
```

If required:

```bash
rc-update add sysctl boot
```

I repeat this configuration on FW1 and FW2.

IPv4 forwarding allows the Linux systems to work as routers.

Firewall rules will later decide which forwarded packets are allowed or blocked.

---

# 7. First routing tests

At this point, I test only basic network communication.

Firewall filtering and NAT are not configured yet.

## FW1 to FW2

From FW1:

```bash
ping -c 3 10.0.0.46
```

This checks communication between both firewall DMZ interfaces.

## FW2 to FW1

From FW2:

```bash
ping -c 3 10.0.0.33
```

This tests the same DMZ path in the opposite direction.

---

# 8. Configure the Web Server for the DMZ

The web server previously had direct access to the libvirt WAN network with:

```text
192.168.122.236/24
```

This old configuration must not be part of the final architecture.

If the web server keeps this route, traffic can bypass FW1.

The final web server network is:

```text
Web Server
10.0.0.34/28
      |
   web-dmz
      |
 +----+----+
 |         |
FW1       FW2
.33       .46
```

---

## 8.1 Check the web server interfaces

From the Ubuntu host:

```bash
virsh domiflist ubuntu-web-server
```

I check which virtual NIC is connected to:

```text
default
web-dmz
```

Inside the web server:

```bash
ip -br link
ip -br addr
ip route
```

The current interface names are:

```text
enp1s0 → old WAN
enp7s0 → DMZ
```

The final active network interface for the server is:

```text
enp7s0 → 10.0.0.34/28
```

---

## 8.2 Check the current Netplan file

Ubuntu uses Netplan for persistent network configuration.

I first check the files:

```bash
ls -l /etc/netplan/
```

Then:

```bash
sudo cat /etc/netplan/*.yaml
```

I also check the effective configuration:

```bash
sudo netplan get
```

---

## 8.3 Configure the DMZ interface

I edit the current Netplan YAML file in:

```text
/etc/netplan/
```

The final network logic is:

```yaml
network:
  version: 2
  ethernets:
    enp7s0:
      dhcp4: false
      addresses:
        - 10.0.0.34/28
      routes:
        - to: default
          via: 10.0.0.33

        - to: 10.0.0.0/27
          via: 10.0.0.46

        - to: 10.0.0.48/29
          via: 10.0.0.46
```

The web server uses two routers for different destinations.

The default route is:

```text
default → FW1 10.0.0.33
```

This route is used for external traffic.

The routes for Internal and Management are:

```text
10.0.0.0/27  → FW2 10.0.0.46
10.0.0.48/29 → FW2 10.0.0.46
```

This sends internal traffic to FW2.

---

## 8.4 Validate Netplan

Before applying the configuration:

```bash
sudo netplan try
```

This allows me to test the network configuration before making it permanent.

After validation:

```bash
sudo netplan apply
```

I verify:

```bash
ip -br addr
ip route
```

The final routing table must contain:

```text
10.0.0.32/28 → directly connected on enp7s0
default       → 10.0.0.33
10.0.0.0/27  → 10.0.0.46
10.0.0.48/29 → 10.0.0.46
```

The old default route:

```text
default via 192.168.122.1
```

must not be used in the final network design.

---

# 9. Test the complete DMZ network

From the Web Server:

```bash
ping -c 3 10.0.0.33
```

This checks communication with FW1.

```bash
ping -c 3 10.0.0.46
```

This checks communication with FW2.

From FW1:

```bash
ping -c 3 10.0.0.34
ping -c 3 10.0.0.46
```

From FW2:

```bash
ping -c 3 10.0.0.33
ping -c 3 10.0.0.34
```

At this point, these three systems must communicate inside the DMZ:

```text
FW1        10.0.0.33
Web Server 10.0.0.34
FW2        10.0.0.46
```

---

# 10. Final verification

On FW1:

```bash
hostname
ip addr
ip route
sysctl net.ipv4.ip_forward
```

On FW2:

```bash
hostname
ip addr
ip route
sysctl net.ipv4.ip_forward
```

On the Web Server:

```bash
hostname
ip -br addr
ip route
```

From the Ubuntu host:

```bash
virsh domiflist fw1
virsh domiflist fw2
virsh domiflist ubuntu-web-server
```

These checks give evidence of:

* Multi-interface Linux configuration.
* IPv4 subnetting.
* Static addressing.
* Default gateways.
* Static routing.
* Multi-homed routers.
* IPv4 packet forwarding.
* DMZ segmentation.
* Persistent network configuration.
* Network troubleshooting.

---

# 11. Expected routing design

The final routing logic is:

```text
                         WAN
                  192.168.122.0/24
                          |
                 192.168.122.1
                          |
                       FW1 WAN
                          |
                         FW1
                          |
                 10.0.0.33/28
                          |
                         DMZ
                    10.0.0.32/28
                    /           \
                   /             \
       Web Server .34          FW2 .46
                                  |
                    +-------------+-------------+
                    |                           |
                Internal                   Management
              10.0.0.0/27               10.0.0.48/29
                    |                           |
              FW2 10.0.0.1               FW2 10.0.0.49
```

FW1 routes traffic between:

```text
WAN ↔ DMZ
```

FW2 routes traffic between:

```text
DMZ ↔ Internal
DMZ ↔ Management
Internal ↔ Management
```

The routing capability does not mean that all traffic is allowed.

The next stage uses nftables to define which connections are permitted.

---

# 12. Evidence saved for the portfolio

I save evidence of the final network state.

### Host

```bash
virsh net-list --all
virsh domiflist fw1
virsh domiflist fw2
virsh domiflist ubuntu-web-server
```

### FW1

```bash
ip addr
ip route
sysctl net.ipv4.ip_forward
```

### FW2

```bash
ip addr
ip route
sysctl net.ipv4.ip_forward
```

### Web Server

```bash
ip -br addr
ip route
```

The most useful screenshots are the routing tables because they show how each security zone is connected.

---

## Resources

[1] Linux Professional Institute, *LPIC-2 Objectives*, Topic 203, “Advanced Networking Configuration,” Objectives 203.1–203.3.

[2] Linux Professional Institute, *LPIC-2 Objectives*, Topic 211, “Network Security,” Objective 211.1, “Routing and Packet Filtering.”

[3] Linux Professional Institute, *LPIC-1 Learning Materials*, Topic 109, “Networking Fundamentals,” Objective 109.2, “Persistent Network Configuration.”

[4] Alpine Linux, “Configure Networking,” *Alpine Linux Wiki*, sections “Static address configuration” and “Networking service.”

[5] Alpine Linux, “How to configure static routes,” *Alpine Linux Wiki*, section “Set up routes in /etc/network/interfaces.”

[6] Alpine Linux, “Setting up a Home Router,” *Alpine Linux Wiki*, section “Enable Routing and Set Up Routes.”

[7] Netplan, “YAML Configuration,” sections “Routing” and “Default routes.”

[8] libvirt Project, “Network XML Format,” sections “Connectivity” and “Isolated network config.”

[9] libvirt Project, “virsh,” commands `net-list`, `net-dumpxml` and `domiflist`.



