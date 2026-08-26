# Secure Web Server Infrastructure

![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-24.04_LTS-E95420?logo=ubuntu&logoColor=white)
![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-3.24-0D597F?logo=alpinelinux&logoColor=white)
![NGINX](https://img.shields.io/badge/Web_Server-NGINX-009639?logo=nginx&logoColor=white)
![Firewall](https://img.shields.io/badge/Firewall-nftables-4B5563)
![Virtualization](https://img.shields.io/badge/Virtualization-KVM%2Flibvirt-6B7280)
![Automation](https://img.shields.io/badge/Automation-Packer-02A8EF?logo=packer&logoColor=white)
![Status](https://img.shields.io/badge/Status-Validation_in_progress-yellow)


This project involves the design, implementation and administration of a Linux Web Server operating and its network infrastructure. The web server runs on a DMZ architecture bounded by two firewalls, both of which also run on the Alpine Linux operating system and use nftables as their service.

For this project, I assumed the role of Systems and Network Administrator. I am
responsible for designing, provisioning, securing and validating the systems and network infrastructure used by the web service.

The objective is to provide the development team with a secure deployment target while retaining administrative control and isolating the public-facing service from protected networks.


1. Linux system provisioning: preparing of Ubuntu Server 24.04 on KVM/libvirt, including GPT/LVM storage, package management, system identity, time synchronisation and persistent network configuration.
2. System administration: management of users, groups, sudo privileges, filesystem ownership and permissions, SSH public-key authentication, system services and host firewall rules.
3. Network segmentation and firewalling: define a router-gateway, DMZ, Internal and Management zones, together with static addressing, routing, IPv4 forwarding and two Alpine Linux firewalls using nftables for stateful packet filtering, default-deny policies, DNAT and SNAT. 
4. Services and Security: configuration of NGINX, controlled permissions for web content deployment, HTTP-to-HTTPS redirection, TLS 1.2 and TLS 1.3, and HTTP security headers.
5. Validation, operations and reproducibility — Verification of service availability, permitted and denied network flows, TLS configuration, firewall isolation, logging, monitoring and recovery procedures. This phase also includes the development of Packer templates and shell scripts for the automated Quick Start deployment.


> **Note:** The core Linux, networking, firewall and HTTPS components have been implemented. Security validation, operational testing, monitoring and the automated Quick Start deployment are currently in progress.

---


## Table of Contents

1. [Methodology & Source Selection](#1-methodology--source-selection)
2. [Requirements of Web Server](#2-requirements-of-web-server)
3. [Architecture & Design](#3-architecture--design)
4. [Phases of implementation](#5-phases-of-implementation)
- [Install operating system for Web Server](4.1-install-operating-system-for-Web-Server)
- Base System Administration
5. [Quick Start](#6-quick-start)
6. [Operations, Monitoring, Troubleshooting & Controlled Failure Scenarios](#6-operation-monitoring-troubleshooting--controlled-failure-scenarios)
7. [Automation and Cloud Deployment](#7-automation-and-cloud-deployment)
8. [Official References](#9-official-references)

---


## 1. Requirements of Web Server

As a result of the research described in the previous section, a set of system and network requirements was extracted from the selected security references. The complete requirement selected, including and their are available here:

- [System Requirements](docs/sys-requirements.md)
- [Network Requirements](docs/net-requirements.md)

## 1. Project Approach and Requirements

The project uses security and operational requirements from recognised security guides and official product documentation. These requirements cover Linux system security, network segmentation, web and TLS security, monitoring, backups and recovery.

Each requirement is linked to a design decision, an implemented control and a validation test. Completed test results are stored as project evidence.

The complete requirements and their links to the implemented controls and tests are available in the [Web Server Requirements](docs/web-server-requirements.md).

---


## 2. Design and Topology 

After defining the system and security requirements, I designed the network to separate public services, internal systems and administration traffic. The design also allows the infrastructure to grow without changing the main network structure.

### 2.1 Network Design

I used VLSM to give each network enough addresses for its expected number of hosts, without using unnecessary address space.

| Network | Subnet | Required hosts | Usable addresses | Purpose |
|---|---|---:|---:|---|
| Internal | `10.0.0.0/27` | 16 | 30 | Internal servers and future services |
| DMZ | `10.0.0.32/28` | 8 | 14 | Internet-facing services |
| Management | `10.0.0.48/29` | 4 | 6 | Infrastructure administration |

This plan creates three separate security zones. The DMZ contains public services, the Internal network is reserved for backend systems, and the Management network is used only for administration.

### 2.2 Topology

The VLSM plan was then applied to a segmented topology with two firewalls and separate security zones.

![Web Server Topology](docs/web-server-topology.png)

> **Note:** Faded devices represent external or planned components that are not implemented in the current version of the project.

The External network connects the environment to the libvirt NAT gateway at `192.168.122.1`. FW1 separates this External network from the DMZ.

The Web Server is placed in the DMZ because it provides the public HTTPS service. FW2 separates the DMZ from the Internal and Management networks.

The Management network is isolated from the DMZ and External network. Administrative access to FW1, FW2 and other systems must come from the Admin station.

The Internal network is protected behind FW2. It is prepared for future backend services such as an application server and database server. These systems will not need direct access from the External network.

---


## 4. Implementation Phases

### 4.1 Install operating system for Web Server

The web server was deployed on a Linux virtual machine with the following specifications:

- Operating System: Ubuntu Server 24.04 LTS
- Virtual processors: 2 vCPU
- RAM: 4 GiB
- Storage: 25 GiB virtual disk
- Firmware: BIOS

The virtual machine runs on QEMU/KVM and is managed with virt-manager through libvirt. This platform was selected because it integrates well with the Ubuntu 24.04 LTS host system. The operating system, kernel, architecture, hostname and virtualisation environment were verified using `hostnamectl`.

![hostnamectl.png](screenshots/hostnamectl.png)

The static hostname provides a persistent identity for the server across reboots.

During installation, the 25 GiB virtual disk `/dev/vda` was manually partitioned using GPT. A 1 MiB BIOS boot partition was created for GRUB, followed by a separate 1 GiB ext4 partition mounted at `/boot`.

The remaining disk space was assigned to an LVM physical volume. LVM was used to create logical volumes for `/`, `/var` and swap. Separating `/var` reduces the risk that uncontrolled growth of logs and other variable data could fill the root filesystem. Approximately 4 GiB were left free in the volume group for future expansion.

![lsblk main comand.png](screenshots/lsblk-main-comand.png) 

For more details:
![Installing & particions](docs/partitions-configuration.md)


### 4.2 Base System Administration

Before installing network and web services, I prepared the base Linux system. This phase covered package maintenance, system identity, time configuration, user roles and access control.

These tasks provide a controlled operating system before installing hte services and other configuration.

**1. Package maintenance**
APT uses the package information from the configured repositories to install and update software. Updating this information before installing the services helps to avoid versioning issues during the installation of the services. The utility used is:

```bash
sudo apt-get update && sudo apt-get upgrade
```

To fix conflicts when the packets is running I use this command `sudo apt-get dist-upgrade`. Now checking again:

![list upgradable](screenshots/list-upgradable.png)


**2. System identity, timezone and locale configuration**

The server hostname, timezone and locale were configured before deploying services. Is important that time is set correctly, to ensure the consistency of logs, SSH sessions and security events that rely of timestamps.

The final configuration was validated with timedatectl and locale information.

![timedatectl-locale-a](screenshots/timedatectl-locale-a2.png)


**3. User and group administration**

The server use separate users and groups were created for different responsibilities:

| User | Gropup | Responsibility |
| ---- | ------ | -------------- |
| nuno | admin  | System administration |
| dev | developers | Application development |
| ops | operators | Monitoring |

This design separates responsibilities instead of giving the same permissions to every account.

Linux stores user and group information in /etc/passwd, /etc/shadow and /etc/group. LPIC-1 Objective 107.1 covers the creation, modification and administration of these accounts.

The final account configuration was validated with:

![check-groups-and-users](screenshots/check-groups-and-users.png)

Password ageing and account status were also checked:

![chage-l-dev-ops](screenshots/chage-l-dev-ops.png)

![checking-the-permitss](screenshots/checking-the-permits.png)



### 4.3 Network Administration

After preparing the base Linux system, the next phase was to configure and validate the network connectivity required by the design defined in Section 2.

This phase focused on interface configuration, static addressing, routing, DNS resolution and connectivity tests. The objective was to ensure that each system could communicate only through the correct network path before applying firewall security policies.



**1. Create the virtual network segments**

The required network segments were created on the KVM/libvirt host before configuring the Web Server.

Three separate virtual networks were defined:

- `web-dmz` for Internet-facing services.
- `management-net` for administration.
- `internal-net` for internal systems.

The networks were configured as persistent and enabled at system startup. This provides the virtual network structure required to separate systems with different security needs.

The configuration was verified with:

![Virtual network validation](screenshots/.png)


**2. Persistent network configuration with Netplan**

The Web Server uses Netplan to keep its network configuration persistent after a reboot. A static IP address was assigned to the DMZ interface because a server must have a predictable address for firewall rules, SSH administration and web services.

The Web Server was assigned the address `10.0.0.34/28` in the DMZ network `10.0.0.32/28`.

The Web Server uses only its DMZ interface. Its default route points to FW1 at 10.0.0.33, while routes to the Internal and Management networks use FW2 at 10.0.0.46

The final configuration was checked to confirm the assigned interfaces, addresses and routes.

![Netplan network configuration](screenshots/network-created.png)

**3. Web Server local firewall**

UFW was configured as the local firewall of the Web Server. The objective is to expose only the services required by the server and block all other incoming traffic.

The firewall uses a default-deny policy for incoming connections and allows only:

- `80/tcp` for HTTP.
- `443/tcp` for HTTPS.
- `22/tcp` from the Management Network (`10.0.0.48/29`) for administration.
- `22/tcp` from the authorised developer host (`10.0.0.2`) for application deployment.

This reduces the exposed network surface and applies a whitelist model: traffic is blocked unless it is explicitly required.

![UFW firewall rules](screenshots/ufw-rules.png)

For more details:
![configure-network.md](docs/configure-network-web-server.md)



### 4.4 Web Services NGINX

**1. NGINX installation**

![Nginx initial page](screenshot/page-nginx.png)

---

Before install Nginx, the next step will be to set the directory permissions of `/var/www/northtech-ops` for deploying the web service code. This directory must remain under root administrative control root, while the group of developers must be able to modify web content. Enabling SGID on the directory allow new files and subdirectories automatically get the 'developers' group. 

![Developers permissions configure](screenshoot/developers-permissions-access-var-directory.png)

In the capture is checked the permissions of configuration directories to confirm that they remain under `root` control. Then, `/var/www/northtech-ops` was assigned to the `developers` group, group access was enabled, and then SGID was applied so new files and directories inherit the `developers` group. The final check confirms the `root:developers` ownership and the SGID permission.

---

It was created a NGINX server block for **NorthTech Operations** instead of using the default Ubuntu website. The site configuration is stored in `/etc/nginx/sites-available/northtech` and enabled through `/etc/nginx/sites-enabled/`.

The configuration separates the global NGINX settings from the application-specific settings and maps the website to `/var/www/northtech`. This makes the service easier to maintain, audit and later extend with HTTPS and reverse-proxy functions.

Before applying any configuration change, `nginx -t` is used to validate the configuration. The service is reloaded only after a successful test, reducing the risk of an outage caused by a configuration error.

![NorthTech NGINX validation](screenshots/final-nginx-content.png)

![Final Web Site](screenshots/final-web-site.png)



**2. HTTP/HTTPS configuration**

The NorthTech Operations website was configured to use HTTPS on TCP port `443`.

HTTP traffic on port `80` is redirected to HTTPS. This ensures that the website is accessed using an encrypted connection.

A self-signed X.509 certificate was created with OpenSSL for the local laboratory environment. The certificate uses `northtech.test` as the server name and is valid for one year.

NGINX was configured to use TLS 1.2 and TLS 1.3. The private key is protected with restricted file permissions.

The implementation was validated with `curl` and OpenSSL. The tests confirm:

- HTTP requests are redirected to HTTPS.
- HTTPS returns `HTTP/1.1 200 OK`.
- A TLS connection is established correctly.
- NGINX presents the expected NorthTech Operations certificate.
- The certificate validity dates and identity are correct.

![TLS validation](screenshots/TLS-version-cipher-certificate_verification.png)


Detailed implementation: 
![NGINX Service Setup](docs/nginx-service-setup.md)




### 4.5 Installing and configure the firewalls of DMZ

The DMZ firewall design is inspired by the **Cisco ASA model**, a traditional stateful firewall used to combine routing, NAT and traffic filtering between different security zones.

For this project, Alpine Linux + nftables was selected to reproduce this model with a lightweight and auditable Linux solution. The firewalls provide stateful filtering, routing and network segmentation between the WAN, DMZ, Internal and Management networks.

**1. Firewall FW1**



NAT is used on FW1 to allow private networks to access external networks through the firewall WAN address. It also allows controlled publication of DMZ services, such as HTTPS, without exposing the internal addressing directly.


![Fireall fw1 network configuration](screenshots/firewalls/net-conf-fw1.png)



**2. Firewall FW2**


![Fireall fw2 network configuration](screenshots/firewalls/net-conf-fw2.png)


![Conectivity between firewalls](screenshots/conectivity-between-fw1-fw2.png)





### Installing and configuring the DMZ firewalls

The DMZ firewall design is inspired by the **Cisco ASA model**, where different network zones are connected through routed firewall interfaces.

For this project, Alpine Linux was selected as a lightweight operating system. FW1 and FW2 are configured first as Linux routers. Packet filtering, stateful rules and NAT are configured and validated later with nftables.

---

#### 1. Firewall FW1

FW1 is the network boundary between the WAN and the DMZ.

Its two interfaces are:

- `eth0` — WAN: `192.168.122.2/24`
- `eth1` — DMZ: `10.0.0.33/28`

The default route uses the libvirt gateway `192.168.122.1`. FW1 also has static routes to the Internal (`10.0.0.0/27`) and Management (`10.0.0.48/29`) networks through FW2 at `10.0.0.46`.

These routes are required because FW2 is the router connected to both networks. IPv4 forwarding is enabled with `net.ipv4.ip_forward = 1`, allowing FW1 to route packets between its interfaces [1], [2].

![Firewall FW1 network configuration](screenshots/firewalls/net-conf-fw1.png)

The capture verifies the WAN and DMZ addresses, the default gateway, the routes to the networks behind FW2, and IPv4 forwarding.

---

#### 2. Firewall FW2

FW2 separates the DMZ from the Internal and Management networks.

Its three interfaces are:

- `eth0` — DMZ: `10.0.0.46/28`
- `eth1` — Internal: `10.0.0.1/27`
- `eth2` — Management: `10.0.0.49/29`

Because FW2 is directly connected to these three networks, Linux creates a route for each network automatically. Its default route points to FW1 at `10.0.0.33`, which is used to reach networks outside these local segments.

IPv4 forwarding is also enabled on FW2 so that it can work as a multi-homed Linux router between the DMZ, Internal and Management networks [1], [2].

![Firewall FW2 network configuration](screenshots/firewalls/net-conf-fw2.png)

The capture verifies the three network interfaces, the directly connected routes, the default route through FW1 and IPv4 forwarding.

---

#### 3. Connectivity between FW1 and FW2

After configuring both routers, bidirectional ICMP tests were performed across the DMZ network.

- FW1 (`10.0.0.33`) successfully reached FW2 (`10.0.0.46`).
- FW2 (`10.0.0.46`) successfully reached FW1 (`10.0.0.33`).
- Both tests completed with `0% packet loss`.

![Connectivity between firewalls](screenshots/conectivity-between-fw1-fw2.png)

This evidence confirms **Layer 3 connectivity between both firewall routers over the DMZ**. It validates the addressing and basic routing configuration before packet filtering rules are introduced.

These tests do not prove firewall filtering or NAT. Those controls are validated separately after the nftables configuration.


#### 4. Configuration de firewalls

Cisco defines the ASA as a stateful firewall that can operate in Layer 3 routed mode. In this mode, the firewall acts as a router, in exactly the same way as the FW1 and FW2 firewalls. Cisco explains that the ASA can operate according to the Outside – DMZ – Inside model, whereby public services can be placed in a DMZ to allow limited access from outside without directly exposing internal networks.




### 4.6 Remote Administration and Server Hardening

Remote administration of the Web Server is provided through OpenSSH. SSH was selected because it provides encrypted and authenticated remote access to the Linux system.

The administration account `nuno` uses public-key authentication. The private key remains on the administrator machine, while only the public key is stored on the Web Server in `~/.ssh/authorized_keys`. LPIC-1 describes public-key authentication as the preferred method for remote SSH access and explains the use of `ssh-keygen`, `ssh-copy-id` for  to generate and copy the public key and `authorized_keys` as the file in which to store it.

SSH access has been secured using a specific configuration file:

`/etc/ssh/sshd_config.d/10-web-server-security.conf`

The following controls were applied:

- Direct SSH login as `root` is disabled.
- Public-key authentication is enabled.
- Password authentication is disabled.
- SSH access is limited to the authorised accounts `nuno` and `dev`.

These controls reduce the use of passwords, prevent direct remote access with the root account, and limit which local users can open an SSH session.

The final network design allows the administrator to access SSH only from the Management Network. The developer account will use the their public-key authentication to deploy the web server code.

![evidence-ssh-working.png](screenshots/evidence-ssh-working.png)

For more details:
![configure-ssh.md](docs/configure-ssh.md)














---


## 5. Operation, Monitoring, Troubleshooting & Controlled Failure Scenarios

This section contains only incidents that actually occurred during the implementation and validation of the server.

| Incident         | Symptoms | Diagnosis | Root cause | Resolution | Evidence |
| ---------------- | -------- | --------- | ---------- | ---------- | -------- |
|  |          |           |            |            |          |

Detailed troubleshooting records:

![troubleshooting.md](docs/troubleshooting.md)

---

## 6. Quick Start



---


### 7. Future work:

Automation and Cloud Deployment



---


## 8. References

- IT-Grundschutz Compendium of the 2022 edition: 
https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Grundschutz/Internationa__blob=publicationFile&v=2 

- Guía de Seguridad de las TIC CCN-STIC-673. GUÍA DE CONFIGURACIÓN SEGURA EN SERVIDORES WEB. 
https://www.ccn-cert.cni.es/es/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6861-ccn-stic-673-guia-de-configuracion-segura-en-servidores-web/file?format=html

- Guía de Seguridad de las TIC CCN-STIC-812. GUÍA DE SEGURIDAD EN ENTORNOS Y APLICACIONES WEB:
https://imaginecloud.es/media/attachments/2024/06/16/812-entornos_y_aplicaciones_web.pdf

- LPI-Learning-Material-101-500: 

- LPI-Learning-Material-102-500:

- https://wiki.libvirt.org/VirtualNetworking.html

- https://wiki.libvirt.org/Networking.html

- https://help.ubuntu.com/community/UFW

- The LPIC2 Exam Prep. Implementing Nginx as a web server and a reverse proxy (208.4): 
https://lpic2book.github.io/src/lpic2.208.4/

- Ubuntu Server documentation. How to install nginx: 
https://ubuntu.com/server/docs/how-to/web-services/install-nginx/

- Ubuntu Server documentation. How to configure nginx: 
https://ubuntu.com/server/docs/how-to/web-services/configure-nginx/

- Medium. Enable SSL in Nginx Server to access the application on HTTPS (Port 443): 
https://medium.com/@charanv369/enable-ssl-in-nginx-server-to-access-the-application-on-https-port-443-1bcd52667b08



- NGINX. Module ngx_http_ssl_module: 
https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate

- NGINX. Module ngx_http_ssl_module: 
https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key

- NGINX. Module ngx_http_ssl_module: 
https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_protocols

- OpenSSL Documentation. openssl-req: 
https://docs.openssl.org/3.4/man1/openssl-req/

- OWASP Cheat Sheet Series. HTTP Security Response Headers Cheat Sheet: 
https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html

- Cisco Secure Firewall ASA: 
https://www.cisco.com/c/en_in/products/security/adaptive-security-appliance-asa-software/index.html

- CLI Book 2: Cisco Secure Firewall ASA Firewall CLI Configuration Guide, 9.20: 
https://www.cisco.com/c/en/us/td/docs/security/asa/asa920/configuration/firewall/asa-920-firewall-config/nat-basics.html

- Alpine wiki. Using an answerfile with setup-alpine: 
https://wiki.alpinelinux.org/wiki/Using_an_answerfile_with_setup-alpine

- HashiCorp. Packer examples: 
https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu


- The Perfect Nginx Server - Ubuntu (24.04) Edition: 
https://www.udemy.com/course/the-perfect-nginx-server-ubuntu-2404-edition/

- Ubuntu installation documentation. Autoinstall quick start. Available in: https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-quickstart.html

- Ubuntu installation documentation. Creating autoinstall configuration: 
https://canonical-subiquity.readthedocs-hosted.com/en/latest/tutorial/creating-autoinstall-configuration.html

[1] *The LPIC2 Exam Prep*, Topic 205, “Networking Configuration,” Objectives 205.1–205.3.

[2] *The LPIC2 Exam Prep*, Topic 212, “System Security,” Objective 212.1, “Configuring a Router.”

- Chapter: Introduction to the Secure Firewall ASA : 
https://www.cisco.com/c/en/us/td/docs/security/asa/asa920/configuration/general/asa-920-general-config/intro-intro.html

- Chapter: Access Rules: 
https://www.cisco.com/c/en/us/td/docs/security/asa/asa920/configuration/firewall/asa-920-firewall-config/access-rules.html

- Chapter: Network Address Translation (NAT): 
https://www.cisco.com/c/en/us/td/docs/security/asa/asa920/configuration/firewall/asa-920-firewall-config/nat-basics.html

- NIST SP 800-41 Rev.1. Guidelines on Firewalls and Firewall Policy. Chapter 4 - Firewall Policy: https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-41r1.pdf





- CIS Ubuntu Linux Benchmark.

- CIS NGINX Benchmark.

- Linux Filesystem Hierarchy Standard:
https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf

- https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf










