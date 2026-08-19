# Web Server

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420)
![Nginx](https://img.shields.io/badge/NGINX-latest-009639)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-In_Progress...-yellow)

This project involves the deployment and administration of a production-ready Linux web server, provisioned in a virtualized environment and designed for cloud deployment. The server represents part of the infrastructure for a web application.

My role is Systems and Network Administrator. My responsibility consists of provisioning a secure server so that the development team can develop the web application without having to manage the infrastructure.

The work covers everything from operating system installation to monitoring and validating the system in production. The implementation tasks include:

- Operating system installation.
- Management of access, privileges, and system resources.
- System hardening and TLS implementation.
- Setup of monitoring and event logging systems.

Finally, the server is also tested against various failure scenarios, which are diagnosed and resolved using standard systems and network administration procedures.

---


## Table of Contents

1. [Methodology & Source Selection](#1-methodology--source-selection)
2. [Requirements of Web Server](#2-requirements-of-web-server)
3. [Architecture & Design](#3-architecture--design)
4. [Phases of implementation](#5-phases-of-implementation)
5. [Quick Start](#6-quick-start)
6. [Operations, Monitoring, Troubleshooting & Controlled Failure Scenarios](#6-operation-monitoring-troubleshooting--controlled-failure-scenarios)
7. [Automation and Cloud Deployment](#7-automation-and-cloud-deployment)
8. [Official References](#9-official-references)

---


## 1. Methodology & Source Selection

The methodology used in this project is as follows:

1. Relevant technical and security references are selected to identify the requirements for the server.
2. The requirements are extracted, summarised, and linked to their original sources.
3. Based on these requirements, the web server architecture and security controls are designed.
4. The server is implemented using official product documentation and a documented task plan.
5. The implementation is validated through functional, security, and failure-recovery tests. The results are recorded as evidence.
6. Finally, the server is deployed in a cloud IaaS environment and compared with the local implementation to verify its reproducibility.

This approach provides a base for defining the requierements necesary for an Web Server from the selected rsources. It also, provides clear criteria for justify the design decisions. The technologies used are selected to satisfy the defined requirements.

---


## 2. Requirements of Web Server

As a result of the research described in the previous section, a set of system and network requirements was extracted from the selected security references. The complete requirement selected, including and their are available here:

- [System Requirements](docs/sys-requirements.md)
- [Network Requirements](docs/net-requirements.md)

The table below presents the main requirements selected for the design, implementation, and validation of the server. These requirements were selected because they define important security and operational controls and can be verified through reproducible tests. 

| ID  | Reference   | Requirement                                                                                             | Verification                                                                                                                                                                              |
| --- | ----------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R01 | APP.3.2.A1  | The web server process must be assigned to a user account with minimum rights.                          | Inspect NGINX processes with `ps -eo user,group,pid,cmd` and verify that worker processes run under the configured service account. Save the command output.                              |
| R02 | APP.3.2.A2  | Web server files must be protected against unauthorised reading or modification.                        | Inspect ownership and permissions with `stat` and `namei -l`. Attempt to modify a protected file using an unauthorised account and record the `Permission denied` result.                 |
| R03 | SYS.1.5.A12 | A role and permissions model for administration should be implemented.                                  | Document the administrative roles and compare them with `getent group`, `id` and `sudo -l -U <user>`. Save the role matrix and command outputs.                                           |
| R04 | SYS.1.5.A8  | The tasks of administrator groups should be defined and clearly separated.                              | Document the responsibilities assigned to each administrative group and verify group membership with `getent group` and `id`.                                                             |
| R05 | SYS.1.3.A6  | The files `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/sudoers` should not be edited directly. | Review the provisioning playbooks and verify that accounts and permissions are managed with dedicated modules or commands. Validate the files with `pwck -r`, `grpck -r` and `visudo -c`. |
| R06 | NET.1.1.A2  | Complete network documentation, including a network diagram, must be produced and maintained. | Compare the network diagram and addressing plan with the actual output of `ip -br addr`, `ip route` and `ss -lntup`. Store the diagram and outputs.                                  |
| R07 | SYS.1.5.A11 | The virtual infrastructure should be administered through a separate management network.      | Verify the management interface or subnet using `ip -br addr` and `ip route`. Confirm with firewall tests that administrative access is accepted only from the management network.   |
| R08 | SYS.1.5.A9  | The required network segments should be planned.                                              | Document each segment, subnet, purpose and permitted communication flow. Compare the plan with the deployed interfaces, routes and firewall rules.                                   |
| R09 | SYS.1.5.A4  | Virtual networks must not allow firewalls or monitoring systems to be bypassed                | Attempt direct communication between restricted network segments. Record the failed connection, firewall logs and an `nmap` scan showing that the protected path cannot be bypassed. |
| R10 | APP.3.2.A11                | The web server must provide secure TLS encryption for connections passing through untrusted networks.                                                  | Verify the certificate and TLS negotiation with `openssl s_client`, inspect supported protocols with `nmap --script ssl-enum-ciphers`, test the service with `curl` and capture traffic with Wireshark to confirm that HTTP content is encrypted. |
| R11 | SYS.1.3.A8                 | Only SSH should be used to establish encrypted and authenticated interactive connections.                                                              | Perform a successful SSH connection using public-key authentication. Use `nmap` to confirm that insecure remote-access services are not exposed and capture the SSH session with Wireshark to confirm encrypted traffic.                          |
| R12 | NET.3.2.A2                 | Firewall rules must clearly define the permitted communication links and data flows. All other connections must be blocked using a whitelist approach. | Record `ufw status numbered` and the cloud firewall rules. Run an external `nmap -Pn -p-` scan and verify that only explicitly authorised ports are reachable.                                                                                    |
| R13 | CCN-STIC-812, sections 4.5 | Protection against denial-of-service attacks and resource exhaustion.                                                                                  | Perform a controlled load test against the local test environment. Record configured connection or request limits, returned status codes and CPU, memory and connection metrics during the test.                                                  |
| R14 | CCN-STIC-812, section 4.5  | Mandatory use of HTTPS throughout the website.                                                                                                         | Run `curl -I http://<domain>` and verify an HTTP redirect to HTTPS. Run `curl -I https://<domain>` and verify a successful response through TLS.                                                                                                  |
| R15 | SYS.1.5.A26                | A PKI should be used for certificate-protected communications.                                                                                         | Inspect the certificate chain, issuer, subject, validity dates and fingerprint with `openssl s_client` and `openssl x509`. Record the certificate-renewal test.                                                                                   |
| R16 | APP.3.2.A4                              | The web server must log general errors.                                                                                                             | Generate a controlled NGINX failure, such as an inaccessible file or unavailable upstream. Record the request, the resulting error and the related entries from `/var/log/nginx/error.log` and `journalctl -u nginx`.                      |
| R17 | APP.3.2.A18                             | The web server should be monitored continuously.                                                                                                    | Stop NGINX or exceed a defined resource threshold. Record the monitoring event, timestamp, affected metric and generated alert.                                                                                                            |
| R18 | NET.1.2.A25                             | Network performance and availability should be monitored continuously.                                                                              | Monitor latency, packet loss and service availability. Generate a controlled connectivity interruption and retain the metric history and alert showing its detection.                                                                      |
| R19 | NET.3.2.A32                             | Firewall diagnosis and troubleshooting should be planned in advance. Actions for typical failure scenarios should be defined and regularly updated. | Execute a documented scenario in which an incorrect firewall rule blocks an authorised service. Save the failed test, firewall logs, diagnosis, corrective action and successful final test.                                               |
| R20 | SYS.1.5.A17                             | Configuration files should be regularly checked for unauthorised modifications                                                                      | Create a configuration-integrity baseline using checksums or an integrity-monitoring tool. Modify a controlled test file and retain the report that detects the change.                                                                    |
| R21 | APP.3.2.A18                             | The web server should be monitored continuously.                                                                                                    | Use an external availability check to detect a controlled service outage. Record the failed probe, alert and successful recovery check.                                                                                                    |
| R22 | CCN-STIC-812, section 5. and NET.1.2.A6 | Protection of backups. Network management data and configurations must be included in backups.                                                      | Back up web content, critical server configuration and network configuration. Delete or modify a controlled test file, restore it and compare its checksum with the original. Save the backup log, restoration output and matching hashes. |

---


## 3. Architecture & Design

Internet → UFW → Ubuntu → NGINX → Web page

![Architecture](docs/architecture.png)

This section records the principal decisions and their technical justification.

| Decision                | Selected option         | Source                             |  Reason        |
| ----------------------- | ----------------------- | ---------------------------------- | -------------- |
| Operating system        | Ubuntu Server 24.04 LTS | Ubuntu documentation               |  |
| Web server              | NGINX                   | NGINX documentation                |  |
| Deployment model        | Single virtual machine  | Project constraint                 |  |
| Network filtering       | Cloud firewall and UFW  | Cloud and Ubuntu documentation     |  |
| Administrative access   | OpenSSH                 | OpenSSH and Ubuntu documentation   |  |
| User and group model    | Admin, developers       | Ubuntu documentation               |  |
| Web directory structure |            | FHS and Ubuntu/NGINX documentation |  |
| TLS management          |           | TLS provider documentation         |  |

---


## 4. Implementation Phases

### Operating System Installation

The web server was deployed on a Linux virtual machine with the following specifications:

- Operating System: Ubuntu Server 24.04 LTS
- Virtual processors: 2 vCPU
- RAM: 4 GiB
- Storage: 25 GiB virtual disk
- Firmware: BIOS

The virtual machine runs on a KVM hypervisor and is managed through virt-manager, a graphical interface for libvirt. This platform was selected because of its integration with the Ubuntu 24.04 LTS host system. The installed operating system, kernel, architecture and virtualization environment were verified using `hostnamectl`.

![hostnamectl.png](screenshots/hostnamectl.png)

The Static hostname mean that the identity of server y persistent. 

During installation, the 25 GiB virtual disk /dev/vda was manually partitioned using GPT. A 1 MiB BIOS boot partition was created for GRUB, followed by a separate 1 GiB ext4 partition mounted at /boot.

The remaining disk space was assigned to an LVM physical volume. LVM was used to create logical volumes for the root filesystem /, the variable-data directory /var and swap. Separating /var limits the impact that uncontrolled growth of logs and other variable data could have on the root filesystem. Approximately 4 GiB were left free in the volume group for future expansion. 

![lsblk main comand.png](screenshots/lsblk-main-comand.png)


### Base System Configuration

The objective of this phase was to prepare controlled Linux base before installing network and web services. The configuration focused on package maintenance, system identity, time settings, user roles, privileges and filesystem permissions. These controls are important because services such as SSH and NGINX depend on a correctly configured operating system and a clear access model.


**1. Package update and package-management validation.**
APT uses the package information from the configured repositories to install and update software. Updating this information before installing the services helps to avoid versioning issues during the installation of the services. The utility used is:

```bash
sudo apt-get update && sudo apt-get upgrade
```

The folloing command is used to check for the new updates; in this case, 4 updates are pending.

![List packets](screenshots/list-packets.png)

Fix these conflicts by running `sudo apt-get dist-upgrade` Checking again:

![list upgradable](screenshots/list-upgradable.png)


**2. System identity, timezone and locale configuration**

The server was configured with a clear system identity and the correct time settings. The hostname selected for the server is:

```bash

```

Correct time configuration is important for system administration because logs, SSH connections, security events and troubleshooting depend on accurate timestamps. A clear hostname is also important because it allows administrators to identify the system correctly in logs and remote sessions.

The command used to list the complete horarie zone and for change the correct region are:

```bash
timedatectl list-timezones
```
The command used to set up the region is:

```bash
timedatectl set-timezone Europe/Madrid
```
The final configuration was checked with

![timedatectl-locale-a](screenshots/timedatectl-locale-a2.png)

**3. Account defaults and role design.**

The server uses separate accounts and groups for different responsibilities.

| User | Gropup | Responsibility |
| ---- | ------ | -------------- |
| nuno | admin  | System administration |
| dev | developers | Application development |
| ops | operators | Monitoring |

The purpose of this design is to separate responsibilities instead of giving the same permissions to every user.

Linux controls access to files and system resources through users, groups, ownership and read, write and execute permissions. This provides the base for applying the principle of least privilege.

The administrator account was checked before creating the additional roles.

Checking the identity and privilege of current user:

![check-curent-user](screenshots/check-current-user.png)

Creating the groups and checking. The GID identify the number asigned automatly

![creating-groups](screenshots/creating-groups.png)

Now modify the admin acounto to add the administrator to admin group and add the users to theis respective group:

![add-admin-add-users](screenshots/add-admin-add-users.png)

The parámeters used are:

- -a: 
- -G: add the group
- -m: create automatly the personal directory of user and copy the file from /etc/skel.
- -U: create a privete group with the same name of user.
- -s: asign a user to a asign directoy 

The final parameter instructs the system that this user should be logged in directly to Bash upon logging in. This configuration is stored in the /etc/passwd directory. This is used for service accounts that should not have access to the terminal.

now asigne passwords to users:

![add-passwd-to-users](screenshots/add-passwd-to-users.png)

Finally, chech the .... and check the state of passwords of users

![check-groups-and-users](screenshots/check-groups-and-users.png)

![chage-l-dev-ops](screenshots/chage-l-dev-ops.png)

![checking-the-permitss](screenshots/checking-the-permits.png)




**4. User, group and credential management.**
Crear usuarios y grupos, asignar shell, directorios personales y pertenencia a grupos. Gestionar contraseñas, caducidad, bloqueo y desbloqueo. 107.1



**5. Sudo privilege delegation and filesystem permissions.**
Delegar privilegios con sudo y /etc/sudoers.d/. Crear directorios compartidos y aplicar chown, chgrp, chmod, umask y SGID. 110.1, 104.5

**6. Systemd service review and final validation.**
Revisar el target y los servicios habilitados con systemctl. Validar usuarios, grupos, permisos, sudo, hora, locale y servicios. 101.3


### Network Configuration

Requirements:

- R07 - the infrastructure must be managed via a separate management network.
- NET.1.1.A4: The network must be separated into a three parts: an internal network, a DMZ, and external connections. --> important
- NET.1.1.A10: Services accessible from the Internet must be placed in an external DMZ.
- NET.1.1.A11: Access from the Internet to the internal network must use a secure communication channel.
- NET.1.1.A23: Systems with different protection needs should be placed in different network segments.

Según los requisitos NET.1.1.A10 indican que todos los servicios accesibles desde Internet deben ubicarse obligatoriamente en una DMZ externa. Según el requisito NET.1.1.A4,  [[[ NET.1.1.A4 Network Separation into Zones (B)
The overall network at hand MUST be physically separated into at least the following three zones: internal network, demilitarised zone (DMZ), and external connections (including to the Internet and other untrusted networks). The transitions between the zones MUST be protected by a firewall. This method of control MUST follow the principle of local communication so that firewalls allow only authorised communications (whitelisting). 

NET.1.1.A3 Specification of Network Requirements (B)
A requirements specification MUST be created based on the security policy for the network in question. The specification MUST be consistently maintained. It MUST be possible to derive all the essential elements of network architecture and design from these requirements.

NET.1.1.A18 P-A-P Structure for the Internet Connection (S)
An organisation’s network SHOULD be connected to the Internet via a firewall with a P-A-P structure (see NET.1.1.A4 Network Separation into Zones).
A proxy-based application layer gateway (ALG) MUST be implemented between the two firewall levels. The ALG MUST be connected via its own transfer network (dual-homed) to both the external packet filter and the internal packet filter. The transfer network MUST NOT be occupied with tasks other than those performed for the ALG. 
]]]. Por tanto, se segmentará la red del siguiente modo:

---
flowchart TD

    INTERNET([Internet])

    FW1["Firewall 1"]

    subgraph DMZ["DMZ"]
        direction TB
        WEB["Web Server"]
    end

    FW2["Firewall 2"]

    subgraph INTERNAL["Internal Network"]
        direction TB
        APP["Application Server"]
        DB["Database Server"]
    end

    INTERNET --> FW1
    FW1 --> WEB
    WEB --> FW2
    FW2 --> APP
    FW2 --> DB

    style DMZ stroke-dasharray: 8 5,stroke-width:2px
    
---


1. Check the virtual network in host.



2. Configure netplan

![network-created.png](screenshots/network-created.png)

3. Configure firewall

![ufw-rules.png](screenshots/ufw-rules.png)

4. Create count ssh for admin and deployment

For more details:
![configure-ssh.md](docs/configure-ssh.md)


Fuentes:
- LPIC-2 Study Guide — Chapter 6, Navigating Network Services: interfaces, routing y separación de redes.
- R07, R08 y R09: red de administración separada, planificación de segmentos y prevención de bypass del firewall.


### Remote Administration and Server Hardening

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


### Web Service Deployment and TLS



---


## 5. Quick Start



---


## 6. Operation, Monitoring, Troubleshooting & Controlled Failure Scenarios

This section contains only incidents that actually occurred during the implementation and validation of the server.

| Incident         | Symptoms | Diagnosis | Root cause | Resolution | Evidence |
| ---------------- | -------- | --------- | ---------- | ---------- | -------- |
|  |          |           |            |            |          |

Detailed troubleshooting records:

![troubleshooting.md](docs/troubleshooting.md)

---


### 7. Automation and Cloud Deployment



---


## 8. Official References

- IT-Grundschutz Compendium of the 2022 edition: 
https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Grundschutz/Internationa?__blob=publicationFile&v=2 

- Guía de Seguridad de las TIC CCN-STIC-673. GUÍA DE CONFIGURACIÓN SEGURA EN SERVIDORES WEB. 
https://www.ccn-cert.cni.es/es/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6861-ccn-stic-673-guia-de-configuracion-segura-en-servidores-web/file?format=html

- Guía de Seguridad de las TIC CCN-STIC-812. GUÍA DE SEGURIDAD EN ENTORNOS Y APLICACIONES WEB:
https://imaginecloud.es/media/attachments/2024/06/16/812-entornos_y_aplicaciones_web.pdf

- LPI-Learning-Material-101-500: 


- LPI-Learning-Material-102-500:


- https://wiki.libvirt.org/VirtualNetworking.html


- https://wiki.libvirt.org/Networking.html


- https://help.ubuntu.com/community/UFW





- Ubuntu Server documentation:
https://ubuntu.com/server/docs/

- NGINX official documentation:
https://nginx.org/en/docs/

- OpenSSH manuals:
https://www.openssh.org/manual.html

- CIS Ubuntu Linux Benchmark.

- CIS NGINX Benchmark.

- OWASP TLS guidance.

- OWASP HTTP Security Response Headers guidance.

- Ubuntu installation documentation. Creating autoinstall configuration: 
https://canonical-subiquity.readthedocs-hosted.com/en/latest/tutorial/creating-autoinstall-configuration.html



- Linux Filesystem Hierarchy Standard:
https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf

- Ubuntu installation documentation. Autoinstall quick start. Available in: https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-quickstart.html   

https://www.digitalocean.com/community/tutorials/apache-vs-nginx-practical-considerations

https://docs.oracle.com/en/learn/ol-nginx/#update-the-nginx-configuration-for-tlsssl

https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf










