### System requirements

| Source                                                                  | Extracted requirements                                                                                                      |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| APP.3.2.A1                                                              | The web server must have a secure basic configuration.                                                                      |
| APP.3.2.A1                                                              | The web server process must be assigned to a user account with minimum rights.                                              |
| APP.3.2.A1                                                              | The web server must run in an encapsulated environment when supported by the operating system.                              |
| APP.3.2.A1                                                              | If encapsulation is not possible, each web server should run on its own physical or virtual server.                         |
| APP.3.2.A1                                                              | The web server service must have no unnecessary write permissions.                                                          |
| APP.3.2.A1                                                              | Unnecessary web server modules and functions must be disabled.                                                              |
| APP.3.2.A2                                                              | Web server files must be protected against unauthorised reading or modification.                                            |
| APP.3.2.A2                                                              | The web server must serve only files located within the WWW root directory.                                                 |
| APP.3.2.A2                                                              | Unnecessary directory-listing functions must be disabled.                                                                   |
| APP.3.2.A2                                                              | Confidential data must be protected against unauthorised access.                                                            |
| APP.3.2.A2                                                              | Confidential files must not be stored in public directories.                                                                |
| APP.3.2.A2                                                              | Public directories must be regularly checked for confidential files.                                                        |
| APP.3.2.A3                                                              | Published files must be checked for malware in advance.                                                                     |
| APP.3.2.A3                                                              | A maximum size for file uploads must be specified.                                                                          |
| APP.3.2.A3                                                              | Sufficient storage space must be reserved for file uploads.                                                                 |
| APP.3.2.A4                                                              | The web server must log successful access to resources.                                                                     |
| APP.3.2.A4                                                              | The web server must log failed access attempts.                                                                             |
| APP.3.2.A4                                                              | The web server must log general errors.                                                                                     |
| APP.3.2.A4                                                              | Logs should be analysed regularly.                                                                                          |
| APP.3.2.A5                                                              | Passwords must be stored in a cryptographically secure manner and protected against unauthorised access.                    |
| APP.3.2.A11                                                             | The web server must provide secure TLS encryption for connections passing through untrusted networks.                       |
| APP.3.2.A11                                                             | Obsolete procedures should be limited to as few cases as possible.                                                          |
| APP.3.2.A11                                                             | All content must be delivered through HTTPS when HTTPS is used.                                                             |
| APP.3.2.A12                                                             | The web server must serve only files located within the defined web root directory.                                         |
| APP.3.2.A12                                                             | Error messages should not display the web server product name or version.                                                   |
| APP.3.2.A12                                                             | Error messages should not reveal system or configuration information.                                                       |
| APP.3.2.A12                                                             | The web server should display only general error messages.                                                                  |
| APP.3.2.A12                                                             | Each error should allow administrators to trace it.                                                                         |
| APP.3.2.A12                                                             | An unexpected error should not leave the server in a vulnerable state.                                                      |
| APP.3.2.A13                                                             | Web crawler access should be regulated according to the robots exclusion standard.                                          |
| APP.3.2.A14                                                             | The integrity of the configuration and published files should be checked regularly.                                         |
| APP.3.2.A14                                                             | Files intended for publication should be regularly checked for malware.                                                     |
| APP.3.2.A16                                                             | Audits should be performed regularly.                                                                                       |
| APP.3.2.A16                                                             | Audit results should be documented and adequately protected.                                                                |
| APP.3.2.A16                                                             | Detected deviations should be investigated.                                                                                 |
| APP.3.2.A15                                                             | Web servers should be designed with redundancy.                                                                             |
| APP.3.2.A15                                                             | The Internet connection should be designed with redundancy.                                                                 |
| APP.3.2.A18                                                             | The web server should be monitored continuously.                                                                            |
| APP.3.2.A18                                                             | Measures against DDoS attacks should be defined and implemented.                                                            |
| SYS.1.3.A2                                                              | Every user must belong to at least one group.                                                                               |
| SYS.1.3.A2                                                              | Every GID specified in `/etc/passwd` must be defined in `/etc/group`.                                                       |
| SYS.1.3.A2                                                              | Every group should contain only the users that are strictly necessary.                                                      |
| SYS.1.3.A2                                                              | UIDs, GIDs, and user and group names must be assigned consistently across connected systems.                                |
| SYS.1.3.A4                                                              | ASLR and DEP/NX must be enabled in the kernel and used by applications.                                                     |
| SYS.1.3.A4                                                              | Kernel and standard-library security functions must not be disabled.                                                        |
| SYS.1.3.A5                                                              | Software compiled from source code must be unpacked, configured, and compiled using an unprivileged account.                |
| SYS.1.3.A5                                                              | Compiled software must not be installed in the root file system in an uncontrolled manner.                                  |
| SYS.1.3.A6                                                              | The files `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/sudoers` should not be edited directly.                     |
| SYS.1.3.A8                                                              | Only SSH should be used to establish encrypted and authenticated interactive connections.                                   |
| SYS.1.3.A8                                                              | Other protocols whose functions are covered by SSH should be completely disabled.                                           |
| SYS.1.3.A8                                                              | Users should primarily use certificates instead of passwords for authentication.                                            |
| SYS.1.3.A10                                                             | Services and applications should be protected using an individual security architecture, such as AppArmor or SELinux.       |
| SYS.1.3.A10                                                             | Chroot environments and LXC or Docker containers should be considered.                                                      |
| SYS.1.3.A10                                                             | The provided standard profiles and rules should be enabled.                                                                 |
| SYS.1.3.A14                                                             | Information displayed about the operating system should be limited to the required minimum.                                 |
| SYS.1.3.A14                                                             | User access to logs and configuration files should be limited to the required minimum.                                      |
| SYS.1.3.A14                                                             | Confidential information should not be included as command parameters.                                                      |
| SYS.1.3.A16                                                             | System calls should be limited to those strictly necessary, especially for exposed services.                                |
| SYS.1.3.A16                                                             | SELinux or AppArmor profiles and rules should be reviewed manually.                                                         |
| SYS.1.3.A16                                                             | Profiles and rules should be adapted to the security policies when necessary.                                               |
| SYS.1.3.A16                                                             | New rules and profiles should be created when necessary.                                                                    |
| SYS.1.3.A17                                                             | For increased protection needs, hardened kernels and memory or file-system protection measures should be used.              |
| SYS.1.5.A2                                                              | Administrator access rights must be limited to those strictly necessary.                                                    |
| SYS.1.5.A4                                                              | Virtual networks must not allow firewalls or monitoring systems to be bypassed.                                             |
| SYS.1.5.A4                                                              | Systems connected to multiple networks must not allow undesired network connections.                                        |
| SYS.1.5.A4                                                              | Connections between virtual and physical systems should be configured according to the security policy.                     |
| SYS.1.5.A5                                                              | All administrative and management access must be restricted.                                                                |
| SYS.1.5.A5                                                              | Administration interfaces must not be accessible from untrusted networks.                                                   |
| SYS.1.5.A5                                                              | Secure protocols should be used for administration and monitoring.                                                          |
| SYS.1.5.A5                                                              | If insecure protocols are used, a separate administration network must be used.                                             |
| SYS.1.5.A6                                                              | The operating condition, usage, and network connections must be logged continuously.                                        |
| SYS.1.5.A6                                                              | The correct assignment of virtual networks must be monitored.                                                               |
| SYS.1.5.A7                                                              | The system time of all virtual systems in production must remain synchronised.                                              |
| SYS.1.5.A8                                                              | The structure of the virtual infrastructure should be planned in detail.                                                    |
| SYS.1.5.A8                                                              | The tasks of administrator groups should be defined and clearly separated.                                                  |
| SYS.1.5.A8                                                              | The persons responsible for each component should be defined.                                                               |
| SYS.1.5.A9                                                              | The virtual network structure should be planned in detail.                                                                  |
| SYS.1.5.A9                                                              | The required network segments should be planned.                                                                            |
| SYS.1.5.A9                                                              | The method for separating and protecting network segments should be determined.                                             |
| SYS.1.5.A9                                                              | The production network should be separated from the management network.                                                     |
| SYS.1.5.A9                                                              | Network availability requirements should be met.                                                                            |
| SYS.1.5.A10                                                             | Processes for commissioning, inventory, operation, and decommissioning should be defined.                                   |
| SYS.1.5.A10                                                             | The processes should be documented and updated regularly.                                                                   |
| SYS.1.5.A10                                                             | Test and development environments should not share a virtualisation server with production systems.                         |
| SYS.1.5.A11                                                             | The virtual infrastructure should be administered through a separate management network.                                    |
| SYS.1.5.A11                                                             | Authentication, integrity, and encryption mechanisms should be enabled.                                                     |
| SYS.1.5.A11                                                             | Insecure administration protocols should be disabled.                                                                       |
| SYS.1.5.A12                                                             | A role and permissions model for administration should be implemented.                                                      |
| SYS.1.5.A12                                                             | Virtual machine administrators should be differentiated from virtual infrastructure administrators.                         |
| SYS.1.5.A12                                                             | The two types of administrators should have different access rights.                                                        |
| SYS.1.5.A13                                                             | The hardware should be compatible with the virtualisation solution.                                                         |
| SYS.1.5.A14                                                             | Uniform configuration standards should be defined. Virtual systems should be configured according to these standards.       |
| SYS.1.5.A15                                                             | Systems with different protection needs should be sufficiently isolated and encapsulated.                                   |
| SYS.1.5.A16                                                             | Copy-and-paste functions between virtual machines should be disabled.                                                       |
| SYS.1.5.A17                                                             | The operating condition of the virtual infrastructure should be monitored.                                                  |
| SYS.1.5.A17                                                             | The availability of sufficient resources should be checked.                                                                 |
| SYS.1.5.A17                                                             | Shared resources should be checked for conflicts.                                                                           |
| SYS.1.5.A17                                                             | Configuration files should be regularly checked for unauthorised modifications.                                             |
| SYS.1.5.A17                                                             | Configuration changes should be checked and tested before implementation.                                                   |
| SYS.1.5.A19                                                             | Regular audits of the virtual infrastructure should be performed.                                                           |
| SYS.1.5.A20                                                             | The virtual infrastructure should be designed for high availability.                                                        |
| SYS.1.5.A20                                                             | Virtualisation servers should be grouped into clusters.                                                                     |
| SYS.1.5.A22                                                             | Mandatory access controls should be used to improve isolation.                                                              |
| SYS.1.5.A23                                                             | Interfaces that reveal host information should be disabled.                                                                 |
| SYS.1.5.A23                                                             | Virtual machines should not share main-memory pages.                                                                        |
| SYS.1.5.A25                                                             | Direct access to virtual consoles should be reduced to a minimum.                                                           |
| SYS.1.5.A25                                                             | Virtual machines should be administered over the network whenever possible.                                                 |
| SYS.1.5.A26                                                             | A PKI should be used for certificate-protected communications.                                                              |
| SYS.1.5.A27                                                             | Virtualisation software certified as EAL4 or higher should be used.                                                         |
| SYS.1.5.A28                                                             | All virtual systems should be encrypted.                                                                                    |
| CCN-STIC-673, Annex A, a)                                               | Controlled location of web content.                                                                                         |
| CCN-STIC-673, A.5.SEC-MSEWL1                                            | Limited service user.                                                                                                       |
| CCN-STIC-673, A.5.SEC-MSEWL2                                            | Configuration of authentication modules.                                                                                    |
| CCN-STIC-673, A.6.SEC-MSEWL2                                            | Network and IP restrictions.                                                                                                |
| CCN-STIC-673, A.15.SEC-MSEWL2                                           | Certificates and certificate renewal.                                                                                       |
| CCN-STIC-673, A.7.SEC-MSEWL2                                            | Secure TLS protocols.                                                                                                       |
| CCN-STIC-673, A.7.SEC-MSEWL3                                            | Request filtering.                                                                                                          |
| CCN-STIC-673, A.3.SEC-MSEWL1                                            | Log retention.                                                                                                              |
| CCN-STIC-673, A.11.SEC-MSEWL1                                           | Connection, request, and timeout limits.                                                                                    |
| CCN-STIC-812, section 4.4 and checklist                                 | Updating all components of the web environment.                                                                             |
| CCN-STIC-812, sections 5.3 and 5.3.2                                    | Exclusive exposure of the required services and ports.                                                                      |
| CCN-STIC-812, section 4.5 and checklist, pp. 29–30                      | Mandatory use of HTTPS throughout the website.                                                                              |
| CCN-STIC-812, checklist                                                 | Filtering of incoming and outgoing traffic.                                                                                 |
| CCN-STIC-812, sections 4.5 and 5.4.2 and checklist                      | Protection against denial-of-service attacks and resource exhaustion.                                                       |
| CCN-STIC-812, section 4.6.3                                             | Absence of confidential information in published content.                                                                   |
| CCN-STIC-812, section 4.6.3                                             | Removal of source code and unnecessary default content from production.                                                     |
| CCN-STIC-812, section 5,                                                                | Protection of backups.                                                                                                      |
| CCN-STIC-812, section 4.5,                                             | The web application must have network-level detection and protection mechanisms, firewalls, or intrusion detection systems. |

