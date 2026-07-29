# Web Server

This project focused on designing, deploying, securing, and validating a Linux web server using official technical documentation.

The project applies Linux system administration, networking, security, service management, monitoring, and recovery practices aligned with LPIC-1 and selected LPIC-2 objectives.

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

| Component             | Implementation          | Purpose                            |
| --------------------- | ----------------------- | ---------------------------------- |
| Operating system      | Ubuntu Server 24.04 LTS | Base operating environment         |
| Remote administration | OpenSSH                 | Secure administrative access       |
| Host firewall         | UFW                     | Local network traffic filtering    |
| Web server            | NGINX                   | Website publication                |
| Service management    | systemd                 | Service startup and supervision    |
| Logging               | journald and NGINX logs | Audit and troubleshooting          |
| TLS                   | To be documented        | Encrypted web traffic              |
| Backup                | To be documented        | Configuration and content recovery |
| Monitoring            | To be documented        | Availability and resource checks   |


### Main Requirements

| ID | Requirement | Validation |
|---|---|---|
| WEB-01 | The server shall publish the website through NGINX. | HTTP request test |
| WEB-02 | The public website shall be accessible through HTTPS. | TLS and `curl` test |
| SSH-01 | The server shall support secure remote administration. | SSH connection test |
| FW-01 | Only explicitly authorized ports shall accept incoming traffic. | UFW, cloud firewall, and port scan |
| IAM-01 | Administrative and web content permissions shall follow least privilege. | User, group, and permission inspection |
| LOG-01 | The server shall record web access, errors, and relevant system events. | Log inspection |
| OPS-01 | Required services shall start automatically after a reboot. | Reboot and systemd test |
| UPD-01 | The operating system shall have a documented update procedure. | Package and update inspection |
| REC-01 | Web content and critical configuration shall be recoverable from backup. | Restoration test |

Detailed requirements and acceptance criteria:

[`docs/requirements.md`](docs/requirements.md)

---

## 3. Architecture

Internet → Firewall cloud → UFW → Ubuntu → NGINX → Web page

![Architecture](docs/architecture.png)

---

## 4. Implemented System




## 5. Technical Decisions

This section records the principal decisions and their technical justification.

| Decision                | Selected option         | Rationale        | Source                             |
| ----------------------- | ----------------------- | ---------------- | ---------------------------------- |
| Operating system        | Ubuntu Server 24.04 LTS | To be documented | Ubuntu documentation               |
| Web server              | NGINX                   | To be documented | NGINX documentation                |
| Deployment model        | Single virtual machine  | To be documented | Project constraint                 |
| Network filtering       | Cloud firewall and UFW  | To be documented | Cloud and Ubuntu documentation     |
| Administrative access   | OpenSSH                 | To be documented | OpenSSH and Ubuntu documentation   |
| User and group model    | To be defined           | To be documented | Ubuntu documentation               |
| Web directory structure | To be defined           | To be documented | FHS and Ubuntu/NGINX documentation |
| TLS management          | To be defined           | To be documented | TLS provider documentation         |

---

## 6. Tests and Evidence

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


## Troubleshooting

This section contains only incidents that actually occurred during the implementation and validation of the server.

| Incident         | Symptoms | Diagnosis | Root cause | Resolution | Evidence |
| ---------------- | -------- | --------- | ---------- | ---------- | -------- |
|  |          |           |            |            |          |

Detailed troubleshooting records:

docs/troubleshooting.md

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










