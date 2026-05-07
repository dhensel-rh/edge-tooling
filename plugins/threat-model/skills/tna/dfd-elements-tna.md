# TNA DFD Element Reference

> **Topology**: TNA (Two-Node with Arbiter) only. For TNF elements, see dfd-elements-tnf.md.

Quick reference for mapping PR changes to Data Flow Diagram elements defined in
the TNA formal threat model (see `TNA-THREAT-MODEL.md` in the two-node-toolbox docs directory).

> **ID Namespace**: TNA elements use `TNA-` prefixed IDs (TNA-P1, TNA-DS5, etc.) to avoid ambiguity with TNF element IDs (e.g., TNF P3 = Auth Job vs TNA-P3 = MCO).

## Processes

| ID | Name | Code Reference | STRIDE |
|----|------|---------------|--------|
| TNA-P1 | Installer (arbiter topology) | `installer/pkg/asset/machines/arbiter.go`, `installer/pkg/types/installconfig.go` | S, T, R, I, D, E |
| TNA-P3 | MCO (arbiter config) | `machine-config-operator/manifests/arbiter.machineconfigpool.yaml` | S, T, R, I, D, E |
| TNA-P4 | CEO (standard etcd) | `cluster-etcd-operator/pkg/operator/ceohelpers/control_plane_topology.go` | S, T, R, I, D, E |
| TNA-P5 | Worker Kubelet (optional, OCP 4.22+) | Worker node kubelet | S, T, R, I, D, E |

## Data Stores

| ID | Name | Location | STRIDE |
|----|------|----------|--------|
| TNA-DS5 | etcd Data | etcd pods on 2 masters + arbiter | T, I, D |
| TNA-DS6 | Worker Ignition / Credentials | Worker ignition endpoint | T, I, D |

## External Entities

| ID | Name | Protocol | STRIDE |
|----|------|----------|--------|
| TNA-EE1 | User / Cluster Admin | oc/kubectl | S, R |

## Trust Boundaries

| ID | Boundary | Elements Inside |
|----|----------|----------------|
| TNA-TB1 | Admin Network | TNA-EE1 |
| TNA-TB2 | Kubernetes API | TNA-P1, TNA-P3, TNA-P4, TNA-DS5 |
| TNA-TB3 | Worker Compute (optional) | TNA-P5, TNA-DS6 |

---

## High-Risk Elements

Elements with the most significant threats (from TNA-THREAT-MODEL.md):

| Element | Key Risks | Related Threats |
|---------|-----------|-----------------|
| TNA-P3 (MCO) | Arbiter taint removal -> workload scheduling -> quorum loss | T-2, D-1 |
| TNA-DS5 (etcd Data) | Node compromise exposes all K8s secrets | I-1, T-1 |
| TNA-P5 (Worker Kubelet) | Lateral movement from worker to control plane | E-2 |

---

## TNA Does NOT Have

TNA uses standard Kubernetes etcd (3-member quorum via arbiter) and does **not** include any RHEL-HA / Pacemaker components. The following TNF elements have **no equivalent** in TNA:

- No Pacemaker / Corosync / STONITH / fencing
- No BMC credentials or fencing-credentials secrets
- No podman-etcd OCF agent
- No PCSD authentication
- No privileged TNF setup jobs (TNF processes P2: CEO Controller, P3: Auth Job, P4: Setup Job, P5: Fencing Job handle Pacemaker setup and fencing and do not exist in TNA). Note: TNA reuses IDs P3–P5 for different components (TNA-P3: MCO, TNA-P4: CEO, TNA-P5: Worker Kubelet)
- No CIB (Cluster Information Base)
- No fence_redfish
- No Corosync network (UDP 5404-5406)
- No BMC network trust boundary

Any PR analysis mentioning these components is **not applicable** to TNA topology.
