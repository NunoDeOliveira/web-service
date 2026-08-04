# Web Server

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420)
![Nginx](https://img.shields.io/badge/NGINX-latest-009639)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-In_Progress-yellow)

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
2. [Requirements](#2-requirements)
3. [Architecture & Design](#3-architecture--design)
4. [Technical Decisions](#4-technical-decisions)
5. [Phases of implementation](#5-phases-of-implementation)
6. [Quick Start](#6-quick-start)
7. [Troubleshooting & Controlled Failure Scenarios](#7-troubleshooting--controlled-failure-scenarios)
8. [Lessons Learned](#8-lessons-learned)
9. [Official References](#9-official-references)

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


## 2. Requirements Web Server

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

### 1. Operating System Installation

The web server was deployed on a Linux virtual machine with the following specifications:

- Operating System: Ubuntu Server 24.04 LTS
- Virtual processors: 2 vCPU
- RAM: 4 GiB
- Storage: 25 GiB virtual disk
- Firmware: BIOS

The virtual machine runs on a KVM hypervisor and is managed through virt-manager, a graphical interface for libvirt. This platform was selected because of its integration with the Ubuntu 24.04 LTS host system. The installed operating system, kernel, architecture and virtualization environment were verified using `hostnamectl`.

![Show characteristcs.png](docs/hostnamectl.png)

During installation, the 25 GiB virtual disk /dev/vda was manually partitioned using GPT. A 1 MiB BIOS boot partition was created for GRUB, followed by a separate 1 GiB ext4 partition mounted at /boot.

The remaining disk space was assigned to an LVM physical volume. LVM was used to create logical volumes for the root filesystem /, the variable-data directory /var and swap. Separating /var limits the impact that uncontrolled growth of logs and other variable data could have on the root filesystem. Approximately 4 GiB were left free in the volume group for future expansion. 

![Show partitions.png](docs/lsblk-main-comand.png)



### 2. Base System Administration and Access Control

### 3. Network Configuration

### 4. Remote Administration and Server Hardening

### 5. Web Service Deployment and TLS

### 6. Operations, Monitoring and Recovery

### 7. Automation and Cloud Deployment

---


## 5. Quick Start



---


## 7. Troubleshooting & Controlled Failure Scenarios

This section contains only incidents that actually occurred during the implementation and validation of the server.

| Incident         | Symptoms | Diagnosis | Root cause | Resolution | Evidence |
| ---------------- | -------- | --------- | ---------- | ---------- | -------- |
|  |          |           |            |            |          |

Detailed troubleshooting records:

![troubleshooting.md](docs/troubleshooting.md)

---


## 7. Official References

- IT-Grundschutz Compendium of the 2022 edition: 
https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Grundschutz/Internationa?__blob=publicationFile&v=2 

- Guía de Seguridad de las TIC CCN-STIC-673. GUÍA DE CONFIGURACIÓN SEGURA EN SERVIDORES WEB. 
https://www.ccn-cert.cni.es/es/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6861-ccn-stic-673-guia-de-configuracion-segura-en-servidores-web/file?format=html

- Guía de Seguridad de las TIC CCN-STIC-812. GUÍA DE SEGURIDAD EN ENTORNOS Y APLICACIONES WEB:
https://imaginecloud.es/media/attachments/2024/06/16/812-entornos_y_aplicaciones_web.pdf

- LPI-Learning-Material-101-500: 


- LPI-Learning-Material-102-500:


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



- Linux Filesystem Hierarchy Standard:
https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf

- Ubuntu installation documentation. Autoinstall quick start. Available in: https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-quickstart.html   

https://www.digitalocean.com/community/tutorials/apache-vs-nginx-practical-considerations

https://docs.oracle.com/en/learn/ol-nginx/#update-the-nginx-configuration-for-tlsssl

https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf










