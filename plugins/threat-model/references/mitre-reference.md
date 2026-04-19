# MITRE ATT&CK Quick Reference

Common techniques for infrastructure and Kubernetes security.

## Initial Access (TA0001)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1078 | Valid Accounts | Default creds, leaked tokens, service account abuse |
| T1190 | Exploit Public-Facing App | Unpatched CVEs, injection flaws |
| T1133 | External Remote Services | Exposed SSH, RDP, VNC, API endpoints |

## Execution (TA0002)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1059 | Command/Script Interpreter | Shell exec, eval, unsanitized input to commands |
| T1609 | Container Admin Command | kubectl exec, docker exec, crictl |
| T1610 | Deploy Container | Malicious container images, privileged pods |

## Persistence (TA0003)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1053 | Scheduled Task/Job | CronJobs, systemd timers |
| T1098 | Account Manipulation | Adding users, modifying RBAC |
| T1543 | Create/Modify System Process | Systemd services, init scripts |
| T1136 | Create Account | New ServiceAccounts, local users |

## Privilege Escalation (TA0004)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1068 | Exploitation for Privilege Escalation | CVE exploits, kernel vulns |
| T1548 | Abuse Elevation Control | sudo, setuid, capabilities |
| T1611 | Escape to Host | Container breakout, hostPID, hostNetwork |

## Defense Evasion (TA0005)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1070 | Indicator Removal | Log deletion, history clearing |
| T1562 | Impair Defenses | Disabling SELinux, seccomp, audit |
| T1036 | Masquerading | Renamed binaries, fake processes |

## Credential Access (TA0006)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1552 | Unsecured Credentials | Hardcoded secrets, env vars, config files |
| T1528 | Steal Application Access Token | Token theft, SA token access |
| T1003 | OS Credential Dumping | /etc/shadow, memory scraping |
| T1555 | Credentials from Password Stores | Secret managers, keyrings |

## Discovery (TA0007)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1083 | File and Directory Discovery | Filesystem enumeration |
| T1046 | Network Service Discovery | Port scanning, service probing |
| T1613 | Container and Resource Discovery | kubectl get, API enumeration |

## Lateral Movement (TA0008)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1021 | Remote Services | SSH, WinRM, kubectl |
| T1550 | Use Alternate Auth Material | Token reuse, cert theft |

## Impact (TA0040)

| ID | Technique | Indicators |
|----|-----------|------------|
| T1485 | Data Destruction | rm -rf, etcd data deletion |
| T1486 | Data Encrypted for Impact | Ransomware patterns |
| T1489 | Service Stop | systemctl stop, kill processes |
| T1529 | System Shutdown/Reboot | STONITH abuse, power off |

## TNF-Specific Techniques

| ID | Technique | TNF Context | DFD Elements |
|----|-----------|-------------|--------------|
| T1552 | Unsecured Credentials | BMC credentials in install-config, secrets, CIB | DS1, DS2, DS3, DF1-DF9 |
| T1529 | System Shutdown | Malicious fencing, STONITH abuse | P6, P8, EE2 |
| T1489 | Service Stop | etcd/pacemaker service disruption | P7, DS5 |
| T1557 | Adversary-in-the-Middle | BMC MITM when cert disabled, Corosync interception | P8, DF10, EE2, EE3 |
| T1078 | Valid Accounts | BMC account compromise, predictable PCSD token | P3, P8, DS4, EE2 |
| T1059 | Command Interpreter | Shell injection via credentials, OCF agent scripts | P5, P7, DF9 |
| T1611 | Escape to Host | Privileged TNF setup/fencing containers with nsenter | P3, P4, P5 |
| T1562 | Impair Defenses | CIB manipulation to disable STONITH | DS3, P4 |

## TNA-Specific Techniques

| ID | Technique | TNA Context | DFD Elements |
|----|-----------|-------------|--------------|
| T1078 | Valid Accounts | Admin credential theft (kubeconfig) | TNA-EE1 |
| T1552 | Unsecured Credentials | Worker ignition token leak | TNA-DS6 |
| T1611 | Escape to Host | Container escape from pod to node root | TNA-P5 |
| T1562 | Impair Defenses | Arbiter taint removal disabling scheduling protection | TNA-P3 |
| T1489 | Service Stop | etcd quorum disruption (arbiter + 1 master) | TNA-DS5 |
| T1021 | Remote Services | Lateral movement from worker to control plane via pod network | TNA-P5, TNA-DS5 |

## SNO-Specific Techniques

| ID | Technique | SNO Context | DFD Elements |
|----|-----------|-------------|--------------|
| T1552 | Unsecured Credentials | Pull secret, offline token, kubeadmin-password on admin workstation | SNO-DS1, SNO-DS4 |
| T1611 | Escape to Host | Bootstrap-in-place agent runs privileged on bare metal | SNO-P5 |
| T1610 | Deploy Container | Workloads scheduled on master (no worker isolation) | SNO-P6 |
| T1562 | Impair Defenses | UnsafeScalingStrategy bypasses quorum safety checks | SNO-P4 |
| T1485 | Data Destruction | Single etcd member — node failure = total data loss | SNO-DS3 |
| T1195 | Supply Chain Compromise | Discovery ISO tampering before boot | SNO-DS2 |
| T1078 | Valid Accounts | Admin credential theft (kubeconfig) | SNO-EE1 |

## LVMS-Specific Techniques

> **Not yet defined.** This section will be populated once the LVMS DFD model is created.

## TNF DFD Element to ATT&CK Mapping

| DFD Element | Primary ATT&CK Techniques | Per-Element STRIDE IDs |
|-------------|--------------------------|----------------------|
| P1 (Installer) | T1552 | PE-P1-I-1, PE-P1-T-1 |
| P3 (Auth Job) | T1078, T1611 | PE-P3-S-1, PE-P3-E-1 |
| P4 (Setup Job) | T1611, T1562 | PE-P4-E-1, PE-P4-T-1 |
| P5 (Fencing Job) | T1059, T1552, T1611 | PE-P5-I-1, PE-P5-T-1, PE-P5-E-1 |
| P6 (fenced) | T1529 | PE-P6-S-1, PE-P6-D-1 |
| P7 (podman-etcd) | T1489, T1059 | PE-P7-T-1, PE-P7-D-1 |
| P8 (fence_redfish) | T1557, T1529, T1552 | PE-P8-S-1, PE-P8-I-1 |
| DS1 (install-config) | T1552 | PE-DS1-I-1 |
| DS2 (K8s Secrets) | T1552 | PE-DS2-I-1, PE-DS2-T-1 |
| DS3 (CIB) | T1552, T1562 | PE-DS3-I-1, PE-DS3-T-1 |
| DS4 (PCSD Token) | T1078 | PE-DS4-I-1 |
| DF9 (creds as CLI args) | T1552, T1059 | PE-DF9-I-1 |
| DF10 (Redfish HTTPS) | T1557 | PE-DF10-T-1, PE-DF10-I-1 |
| EE2 (BMC) | T1529, T1190 | PE-EE2-S-1, PE-EE2-S-2 |

## TNA DFD Element to ATT&CK Mapping

| DFD Element | Primary ATT&CK Techniques | Per-Element STRIDE IDs |
|-------------|--------------------------|----------------------|
| TNA-P1 (Installer) | T1552 | PE-TNA-P1-T-1, PE-TNA-P1-D-1 |
| TNA-P3 (MCO) | T1562 | PE-TNA-P3-T-1, PE-TNA-P3-D-1 |
| TNA-P4 (CEO) | T1489 | PE-TNA-P4-T-1, PE-TNA-P4-D-1 |
| TNA-P5 (Worker Kubelet) | T1021, T1611 | PE-TNA-P5-S-1, PE-TNA-P5-E-1 |
| TNA-DS5 (etcd Data) | T1552, T1489 | PE-TNA-DS5-T-1, PE-TNA-DS5-I-1, PE-TNA-DS5-D-1 |
| TNA-DS6 (Worker Ignition) | T1552 | PE-TNA-DS6-T-1, PE-TNA-DS6-I-1 |
| TNA-EE1 (Admin) | T1078 | PE-TNA-EE1-S-1, PE-TNA-EE1-R-1 |

## SNO DFD Element to ATT&CK Mapping

| DFD Element | Primary ATT&CK Techniques | Per-Element STRIDE IDs |
|-------------|--------------------------|----------------------|
| SNO-P1 (Installer) | T1552 | PE-SNO-P1-T-1, PE-SNO-P1-I-1 |
| SNO-P2 (Assisted Service) | T1078, T1552 | PE-SNO-P2-S-1, PE-SNO-P2-T-1 |
| SNO-P3 (MCO) | T1611 | PE-SNO-P3-T-1, PE-SNO-P3-E-1 |
| SNO-P4 (CEO) | T1562 | PE-SNO-P4-T-1, PE-SNO-P4-D-1 |
| SNO-P5 (Bootstrap Agent) | T1611, T1552 | PE-SNO-P5-E-1, PE-SNO-P5-I-1 |
| SNO-P6 (Kubelet) | T1610 | PE-SNO-P6-E-1, PE-SNO-P6-D-1 |
| SNO-DS1 (install-config) | T1552 | PE-SNO-DS1-I-1 |
| SNO-DS2 (Discovery ISO) | T1195 | PE-SNO-DS2-T-1, PE-SNO-DS2-I-1 |
| SNO-DS3 (etcd Data) | T1485, T1552 | PE-SNO-DS3-T-1, PE-SNO-DS3-I-1, PE-SNO-DS3-D-1 |
| SNO-DS4 (Credentials) | T1552 | PE-SNO-DS4-I-1 |
| SNO-EE1 (Admin) | T1078 | PE-SNO-EE1-S-1, PE-SNO-EE1-R-1 |
| SNO-EE2 (Assisted Service Cloud) | T1195 | PE-SNO-EE2-S-1 |

## References

- MITRE ATT&CK Enterprise: <https://attack.mitre.org/matrices/enterprise/>
- MITRE ATT&CK Containers: <https://attack.mitre.org/matrices/enterprise/containers/>
- MITRE ATT&CK Mitigations: <https://attack.mitre.org/mitigations/enterprise/>
