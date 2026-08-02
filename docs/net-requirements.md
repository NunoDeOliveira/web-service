## network requirements

### Network architecture and management requirements

| Source      | Extracted requirement                                                                                       |
| ----------- | ----------------------------------------------------------------------------------------------------------- |
| NET.1.1.A2  | Complete network documentation, including a network diagram, must be produced and maintained.               |
| NET.1.1.A2  | Subnets, zones, segmentation, and network changes must be documented.                                       |
| NET.1.1.A3  | A network requirements specification must be created and maintained.                                        |
| NET.1.1.A4  | The network must be separated into an internal network, a DMZ, and external connections.                    |
| NET.1.1.A4  | Transitions between zones must be protected by firewalls.                                                   |
| NET.1.1.A4  | Firewalls must allow only authorised communications.                                                        |
| NET.1.1.A5  | Clients and servers must be placed in different network segments.                                           |
| NET.1.1.A5  | Communication between client and server segments must be controlled by at least a stateful packet filter.   |
| NET.1.1.A7  | Sensitive information must be transmitted using secure protocols.                                           |
| NET.1.1.A7  | When secure protocols cannot be used, encryption and authentication must be implemented.                    |
| NET.1.1.A8  | Internet traffic must pass through a firewall structure.                                                    |
| NET.1.1.A8  | Traffic must be restricted to the required protocols and communication relationships.                       |
| NET.1.1.A9  | The trust level of every network must be defined.                                                           |
| NET.1.1.A9  | Untrusted networks must be treated like the Internet.                                                       |
| NET.1.1.A10 | Services accessible from the Internet must be placed in an external DMZ.                                    |
| NET.1.1.A11 | Access from the Internet to the internal network must use a secure communication channel.                   |
| NET.1.1.A11 | Access must be restricted to trusted IT systems and users.                                                  |
| NET.1.1.A13 | The network must be planned in a suitable, comprehensive, and transparent manner.                           |
| NET.1.1.A13 | The planning must include topology, zones, capacity, protocols, addressing, administration, and monitoring. |
| NET.1.1.A13 | Network plans must be reviewed regularly.                                                                   |
| NET.1.1.A14 | The planned network must be implemented properly and verified.                                              |
| NET.1.1.A15 | Regular checks must be conducted to compare the actual state with the target state.                         |
| NET.1.1.A16 | The architecture should specify the secure connection between the local network and cloud environments.     |
| NET.1.1.A21 | The management area should be separated from the other networks.                                            |
| NET.1.1.A21 | Management communication should be restricted to defined protocols and endpoints.                           |
| NET.1.1.A23 | Systems with different protection needs should be placed in different network segments.                     |
| NET.1.1.A23 | It must not be possible to bypass network segments or zones.                                                |

### Network management and monitoring requirements

| Source      | Extracted requirement                                                               |
| ----------- | ----------------------------------------------------------------------------------- |
| NET.1.2.A6  | Network management data and configurations must be included in backups.             |
| NET.1.2.A7  | Unauthorised access, failures, and availability problems must be logged.            |
| NET.1.2.A8  | All network components must maintain synchronised system time.                      |
| NET.1.2.A9  | Secure protocols must be used for network administration.                           |
| NET.1.2.A9  | External administrative access must use secure authentication and encryption.       |
| NET.1.2.A11 | A network management security policy should be created and continuously maintained. |
| NET.1.2.A11 | Its implementation should be regularly reviewed and documented.                     |
| NET.1.2.A12 | Network management documentation should be kept complete and up to date.            |
| NET.1.2.A22 | Enabled management functions should be limited to those actually required.          |
| NET.1.2.A25 | Network performance and availability should be monitored continuously.              |
| NET.1.2.A25 | Performance and availability thresholds should be defined in advance.               |
| NET.1.2.A26 | Important events should be sent to and logged by a central management system.       |
| NET.1.2.A26 | The responsible persons should be alerted automatically.                            |
| NET.1.2.A27 | Network management should be integrated into contingency and recovery planning.     |


### Firewall requirements

| Source                                                            | Extracted requirements                                                                                                                                                                          |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NET.3.2.A1                                                        | A firewall security policy must be created. It must describe the requirements for secure firewall operation. Its implementation must be reviewed regularly, and the results must be documented. |
| NET.3.2.A2                                                        | All communications between different networks must pass through a firewall. Unauthorised incoming and outgoing connections must be prevented.                                                   |
| NET.3.2.A2                                                        | Firewall rules must clearly define the permitted communication links and data flows. All other connections must be blocked using a whitelist approach.                                          |
| NET.3.2.A2                                                        | Firewall rule decisions, changes, and their reasons must be documented.                                                                                                                         |
| NET.3.2.A3                                                        | Appropriate packet-filtering rules must be defined and configured.                                                                                                                              |
| NET.3.2.A3                                                        | Invalid TCP flag combinations must be discarded. Filtering must be stateful, including for UDP and ICMP.                                                                                        |
| NET.3.2.A3                                                        | ICMP and ICMPv6 traffic must be filtered restrictively.                                                                                                                                         |
| NET.3.2.A4                                                        | The firewall must be securely configured before use.                                                                                                                                            |
| NET.3.2.A4                                                        | All firewall configuration changes must be documented.                                                                                                                                          |
| NET.3.2.A4                                                        | The integrity of firewall configuration files must be protected.                                                                                                                                |
| NET.3.2.A4                                                        | Firewall credentials must be protected using an up-to-date cryptographic method.                                                                                                                |
| NET.3.2.A4                                                        | Only strictly necessary firewall services must be available. Unnecessary services and extensions must be disabled or removed.                                                                   |
| NET.3.2.A4                                                        | Information about internal configurations and operating status must be hidden from third parties whenever possible.                                                                             |
| NET.3.2.A6                                                        | Firewall administration access must be restricted to specific source IP addresses or address ranges.                                                                                            |
| NET.3.2.A6                                                        | Firewall administration interfaces must not be accessible from untrusted networks.                                                                                                              |
| NET.3.2.A6                                                        | Only secure protocols must be used for firewall administration and monitoring, or a dedicated administration network must be used.                                                              |
| NET.3.2.A6                                                        | Appropriate session time limits must be configured for administration interfaces.                                                                                                               |
| NET.3.2.A7                                                        | Direct local access to the firewall must remain possible even if the network fails.                                                                                                             |
| NET.3.2.A8                                                        | Dynamic routing must be disabled unless the firewall operates as a perimeter router.                                                                                                            |
| NET.3.2.A9                                                        | The firewall must log rejected connections, failed access attempts, firewall service errors, system errors, and configuration changes.                                                          |
| NET.3.2.A1, fragmentation requirement as identified in the source | Protection mechanisms against IPv4 and IPv6 fragmentation attacks must be enabled.                                                                                                              |
| NET.3.2.A14                                                       | Firewall operational tasks, configuration changes, security-related tasks, services, and rule-set changes must be documented.                                                                   |
| NET.3.2.A14                                                       | Firewall operational documentation must be protected against unauthorised access.                                                                                                               |
| NET.3.2.A17                                                       | IPv4 or IPv6 should be disabled on firewall interfaces where the protocol is not required.                                                                                                      |
| NET.3.2.A18                                                       | The firewall should be administered through a separate management network.                                                                                                                      |
| NET.3.2.A18                                                       | In-band administration interfaces should be disabled. Management communication should be limited to defined protocols, origins, and destinations.                                               |
| NET.3.2.A18                                                       | Authentication, integrity, and encryption mechanisms should be enabled. Insecure management protocols should be disabled.                                                                       |
| NET.3.2.A19                                                       | Suitable limits should be configured for semi-open and open connections to services exposed to untrusted networks.                                                                              |
| NET.3.2.A19                                                       | Rate limits should be configured for UDP traffic from untrusted networks.                                                                                                                       |
| NET.3.2.A22                                                       | The firewall system time should be synchronised with an NTP server. External time synchronisation should not be permitted.                                                                      |
| NET.3.2.A23                                                       | The firewall and its services should be continuously monitored.                                                                                                                                 |
| NET.3.2.A23                                                       | Operational personnel should be alerted when errors occur or thresholds are exceeded.                                                                                                           |
| NET.3.2.A23                                                       | Logs and status messages should only be transmitted through secure communication paths.                                                                                                         |
| NET.3.2.A24                                                       | The firewall should be regularly checked for known security issues. Penetration tests and audits should be performed regularly.                                                                 |
| NET.3.2.A32                                                       | Firewall diagnosis and troubleshooting should be planned in advance. Actions for typical failure scenarios should be defined and regularly updated.                                             |
| NET.3.2.A32                                                       | The firewall contingency procedure should be tested regularly.                                                                                                                                  |


### VPN requirements

| Source      | Extracted requirements                                                                                                                               |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| NET.3.3.A1  | The introduction of the VPN must be carefully planned.                                                                                               |
| NET.3.3.A1  | Responsibilities for operating the VPN must be defined.                                                                                              |
| NET.3.3.A1  | VPN user groups and their authorisations must be planned.                                                                                            |
| NET.3.3.A1  | The procedure for documenting granted, modified, and withdrawn access authorisations must be defined.                                                |
| NET.3.3.A2  | If a VPN service provider is used, service level agreements must be negotiated and documented in writing.                                            |
| NET.3.3.A2  | Compliance with the agreed service level agreements must be checked regularly.                                                                       |
| NET.3.3.A3  | VPN components must be installed only by qualified personnel.                                                                                        |
| NET.3.3.A3  | The installation of VPN components and deviations from the plan should be documented.                                                                |
| NET.3.3.A3  | VPN functions and selected security mechanisms must be checked before the VPN is put into operation.                                                 |
| NET.3.3.A4  | Secure configurations must be established for all VPN components.                                                                                    |
| NET.3.3.A4  | VPN configurations should be documented appropriately.                                                                                               |
| NET.3.3.A4  | VPN configurations must be regularly checked and adapted when necessary.                                                                             |
| NET.3.3.A5  | It must be regularly checked that only authorised users and IT systems can access the VPN.                                                           |
| NET.3.3.A5  | VPN access that is no longer required must be disabled promptly.                                                                                     |
| NET.3.3.A5  | VPN access must be limited to the required usage time.                                                                                               |
| NET.3.3.A6  | A VPN requirements analysis should be performed.                                                                                                     |
| NET.3.3.A6  | The requirements analysis should consider access routes, authentication procedures, users, authorisations, responsibilities, and reporting channels. |
| NET.3.3.A7  | The technical implementation of the VPN should be carefully planned.                                                                                 |
| NET.3.3.A7  | VPN encryption methods and endpoints should be specified.                                                                                            |
| NET.3.3.A7  | Permitted access protocols, services, and resources should be specified.                                                                             |
| NET.3.3.A7  | The subnets accessible through the VPN should be defined.                                                                                            |
| NET.3.3.A8  | A security policy for VPN usage should be created.                                                                                                   |
| NET.3.3.A8  | Relevant users should be informed about the VPN security policy.                                                                                     |
| NET.3.3.A8  | VPN security safeguards should be explained through training.                                                                                        |
| NET.3.3.A8  | VPN users should be required to comply with the security policy.                                                                                     |
| NET.3.3.A10 | An operational concept should be created for the VPN.                                                                                                |
| NET.3.3.A10 | The operational concept should include monitoring, maintenance, training, quality management, and authorisation.                                     |
| NET.3.3.A11 | VPN connections should only be established between the intended IT systems and services.                                                             |
| NET.3.3.A11 | The VPN tunnel protocols should be suitable for their intended use.                                                                                  |
| NET.3.3.A12 | Central and consistent user and access management should be implemented for remote-access VPNs.                                                      |
| NET.3.3.A13 | VPN components should be integrated into a firewall.                                                                                                 |
| NET.3.3.A13 | The integration of VPN components into the firewall should be documented.                                                                            |


