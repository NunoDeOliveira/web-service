# Web Server

This project focused on designing, deploying, securing, and validating a Linux web server using official technical documentation.

The project applies Linux system administration, networking, security, service management, monitoring, and recovery practices aligned with LPIC-1 and selected LPIC-2 objectives.

---

## Table of Contents



---

## 1. Technical Goal

Transform a clean Ubuntu Server virtual machine into an operational, secure, maintainable, and verifiable web server.

The final system must:

- Publish web content through NGINX.
- Support secure remote administration.
- Limit network exposure to authorized services.
- Apply appropriate users, groups, permissions, and privileges.
- Record relevant system and web events.
- Support basic backup and recovery procedures.
- Be validated through technical tests.

---

## 2. Scope and Requirements

### Project Scope

| Area | Included work |
|---|---|
| Operating system | Ubuntu Server installation and base configuration |
| System administration | Users, groups, privileges, packages, processes, and systemd |
| Remote administration | OpenSSH configuration and key-based access |
| Networking | Hostname, addressing, DNS resolution, ports, and connectivity |
| Firewall | Cloud firewall and local UFW rules |
| Web service | NGINX installation, configuration, and content publication |
| Transport security | TLS configuration |
| File permissions | Ownership and permissions for configuration and web content |
| Logging | NGINX logs, system logs, and log inspection |
| Updates | Package and security update management |
| Monitoring | CPU, memory and bandwidth usage |
| Backups | Designing a suitable backup schedule |
| Validation | Positive and negative tests with stored evidence |


### Main Requirements

| ID | Requirement | Validation |
|---|---|---|
| WEB-01 | The server shall publish the website through NGINX. | HTTP request test |
| WEB-02 | The public website must be accessible via HTTPS. | TLS and `curl` test |
| SSH-01 | The server must support secure remote administration. | SSH connection test |
| FW-01 | Only explicitly authorized ports shall accept incoming traffic. | UFW, cloud firewall, and port scan |
| IAM-01 | Administrative and web content permissions shall follow least privilege. | User, group, and permission inspection |
| LOG-01 | The server will log web access, errors, and relevant system events. | Log inspection |
| OPS-01 | The required services will start automatically after a restart. | Reboot and systemd test |
| UPD-01 | The operating system shall have a documented update procedure. | Package and update inspection |
| REC-01 | Web content and critical configuration shall be recoverable from backup. | Restoration test |

Detailed requirements and acceptance criteria:

[docs/requirements.md](docs/requirements.md)

---

## 3. Architecture

Internet → UFW → Ubuntu → NGINX → Web page

![Architecture](docs/architecture.png)

---

## 4.  Project Phases

| Phase | Objective | Main deliverable | Status |
|---|---|---|---|
| 0. Design | Define scope, requirements and architecture | Requirements and architecture documents | Completed |
| 1. Operating System | Deploy and configure the Ubuntu Server VM | Operational base system | Pending |
| 2. Network Configuration | Configure hostname, addressing, DNS and connectivity | Functional network configuration | Pending |
| 3. Administration and SSH | Configure users, privileges and secure remote access | Verified administrative access | Pending |
| 4. Security | Configure firewall, permissions and update policy | Reduced attack surface | Pending |
| 5. Web Service and TLS | Deploy NGINX and enable HTTPS | Secure published website | Pending |
| 6. Operations and Recovery | Configure logging, monitoring and backups | Maintainable and recoverable service | Pending |
| 7. Validation | Execute tests and collect evidence | Verified requirements and evidence | Pending |

Detailed project plan: [`docs/project-plan.md`](docs/project-plan.md)

---

## 5. Implemented System


---

## 6. Technical Decisions

This section records the principal decisions and their technical justification.

| Decision                | Selected option         | Source                             |  Reason        |
| ----------------------- | ----------------------- | ---------------------------------- | -------------- |
| Operating system        | Ubuntu Server 24.04 LTS | Ubuntu documentation               |  |
| Web server              | NGINX                   | NGINX documentation                |  |
| Deployment model        | Single virtual machine  | Project constraint                 |  |
| Network filtering       | Cloud firewall and UFW  | Cloud and Ubuntu documentation     |  |
| Administrative access   | OpenSSH                 | OpenSSH and Ubuntu documentation   |  |
| User and group model    | To be defined           | Ubuntu documentation               |  |
| Web directory structure | To be defined           | FHS and Ubuntu/NGINX documentation |  |
| TLS management          | To be defined           | TLS provider documentation         |  |

---

## 7. Tests and Evidence

Each requirement is validated through a reproducible test.

| Requirement | Test                                   | Expected result                       | Evidence             | Status  |
| ----------- | -------------------------------------- | ------------------------------------- | -------------------- | ------- |
| WEB-01      | Request the website with `curl`        | Successful HTTP response              | `evidence/web/`      | Pending |
| WEB-02      | Inspect HTTPS connection               | Valid encrypted connection            | `evidence/tls/`      | Pending |
| SSH-01      | Connect using the authorized method    | Administrative access succeeds        | `evidence/ssh/`      | Pending |
| FW-01       | Inspect rules and scan exposed ports   | Only authorized ports are reachable   | `evidence/firewall/` | Pending |
| LOG-01      | Generate web requests and inspect logs | Access and errors are recorded        | `evidence/logs/`     | Pending |
| OPS-01      | Restart the VM                         | Required services start automatically | `evidence/systemd/`  | Pending |
| REC-01      | Restore configuration and content      | Service returns to its expected state | `evidence/recovery/` | Pending |

---


## 8. Troubleshooting

This section contains only incidents that actually occurred during the implementation and validation of the server.

| Incident         | Symptoms | Diagnosis | Root cause | Resolution | Evidence |
| ---------------- | -------- | --------- | ---------- | ---------- | -------- |
|  |          |           |            |            |          |

Detailed troubleshooting records:

[troubleshooting.md](docs/troubleshooting.md)

---


## References

- Linux Filesystem Hierarchy Standard:
https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf

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



https://www.digitalocean.com/community/tutorials/apache-vs-nginx-practical-considerations

https://docs.oracle.com/en/learn/ol-nginx/#update-the-nginx-configuration-for-tlsssl

https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf










