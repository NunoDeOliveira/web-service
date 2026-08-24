## Virtual Network Configuration

### 1. Objective

The objective of this configuration is to create separate virtual network segments for the infrastructure.

The network is divided into:

- **DMZ** for the public Web Server.
- **Management Network** for administration.
- **Internal Network** for developers and internal systems.

The virtual networks are created on the Ubuntu host with KVM/QEMU and libvirt.

The planned IPv4 addressing is:

| Network | Subnet | Prefix | Required hosts | Usable IPs |
|---|---|---:|---:|---:|
| Internal | `10.0.0.0` | `/27` | 16 | 30 |
| DMZ | `10.0.0.32` | `/28` | 8 | 14 |
| Management | `10.0.0.48` | `/29` | 4 | 6 |

The external connection uses the default libvirt network:

```text
192.168.122.0/24
```

### 2. Create the directory for the network configuration

The libvirt network definitions are stored in the project repository:

```bash
mkdir -p ~/projects/web-server/network/libvirt
cd ~/projects/web-server/network/libvirt
```

the files used are:

- web-dmz.xml
- management-net.xml
- internal-net.xml

Keeping these files inside the repository makes the virtual network design easier to document and reproduce.

### 3. Create the DMZ network

```bash
nano ~/Projects/web-server/network/libvirt/web-dmz.xml
```
![]()


### 4. Create de management Network

```bash
nano ~/Projects/web-server/network/libvirt/management-net.xml
```
![]()

The planned addressing is:

| interface | Address |
| Network | 10.0.0.48/29 |
| FW2 | 10.0.0.49/29 |
| Admin | 10.0.0.50/29 |
| Operator | 10.0.0.51/29 |



### 5. Create the Internal Network

```bash
nano ~/Projects/web-server/network/libvirt/internal-net.xml
```

![]()

the planned addressing is:

| interface | address |
| Network | 10.0.0.0/27 |
| FW2 | 10.0.0.1/27 |
| Developer | 10.0.0.2/27 |
| Database | 10.0.0.3/27 |

This network is used for development and internal systems. It is separated from the DMZ and Management Network.


### 6. Define the networks in libvirt

The XML files are the project configuration files. They must now be registered in libvirt

```bash
sudo virsh net-define ~/projects/web-server/network/libvirt/web-dmz.xml
sudo virsh net-define ~/projects/web-server/network/libvirt/management-net.xml
sudo virsh net-define ~/projects/web-server/network/libvirt/internal-net.xml
```

net-define creates a persistent libvirt network from an XML configuration file.



### 7. Start Networks

```bash
sudo virsh net-start web-dmz
sudo virsh net-start management-net
sudo virsh net-start internal-net
```

### 8. Enable the automatic startup

```bashsudo virsh net-autostart web-dmz
sudo virsh net-autostart management-net
sudo virsh net-autostart internal-net
```

This makes the virtual networks available automatically after the KVM/libvirt host starts.

### 9. Validate the network state

Check all libvirt networks:

```bash
virsh net-list --all
```

and the results expected are:

![]()


### 10. Check the network definitions:

The active configuration can be checked with:

```bash
virsh net-dumpxml web-dmz
```
```bash
virsh net-dumpxml management-net
```
```bash
virsh net-dumpxml internal-net
```

This is useful because it shows the configuration that libvirt is really using.


## Resouces

- LPIC-1 Learning Materials — Topic 109: Networking Fundamentals, IPv4 addressing, subnet masks and routing.

- LPIC-2 Study Guide — Topic 205: Networking Configuration, Objective 205.1, network interfaces and IP configuration.
 
- LPIC-2 Study Guide — Topic 212: System Security, Objective 212.1, NAT, IP forwarding, port redirection and filtering rules.

- LPIC-2 Study Guide — Objective 212.3: Secure Shell, SSH configuration and secure administrative access


## Utilities 

```bash
hostname
```
```bash
ip -br link
```
```bash
ip -br addr
```
```bash
ip route
```




