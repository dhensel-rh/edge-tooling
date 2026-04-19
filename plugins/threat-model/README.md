# Threat Model Plugin for Claude Code

Security threat analysis for OpenShift PRs across multiple topologies (TNF, TNA, SNO, LVMS).

## What It Does

Analyzes pull requests for security threats against OpenShift clusters:

- Fetches PR diffs from GitHub
- Runs ShellCheck on shell scripts
- Maps changes to Data Flow Diagram (DFD) elements
- Applies per-element STRIDE analysis
- Cross-references against formal threat models
- Maps findings to MITRE ATT&CK techniques and OWASP Top 10:2025
- Generates formal threat analysis reports

## Usage

### TNF (Two-Node Fencing)

```bash
/threat-model:tnf 2136
/threat-model:tnf https://github.com/ClusterLabs/resource-agents/pull/2136
/threat-model:tnf resource-agents 2136
```

### TNA (Two-Node Arbiter)

```bash
/threat-model:tna 1437
/threat-model:tna https://github.com/openshift/cluster-etcd-operator/pull/1437
/threat-model:tna installer 10403
```

### SNO (Single Node OpenShift)

```bash
/threat-model:sno 10498
/threat-model:sno https://github.com/openshift/installer/pull/10498
/threat-model:sno installer 10498
```

### LVMS (LVM Storage)

```bash
/threat-model:lvms 2271
/threat-model:lvms https://github.com/openshift/lvm-operator/pull/2271
/threat-model:lvms lvm-operator 2271
```

> **Note**: The LVMS DFD model is not yet defined. The LVMS skill performs general security analysis, ShellCheck scanning, and MITRE/OWASP mapping. Full DFD/STRIDE analysis will be available once its DFD model is created.

## Workspace Requirements

The skill expects a workspace with a `repos/` directory containing cloned repositories. It auto-discovers the workspace root at runtime.

### Recommended workspace layout

```text
your-workspace/
├── repos/
│   ├── cluster-etcd-operator/
│   ├── installer/
│   ├── machine-config-operator/
│   ├── resource-agents/
│   ├── two-node-toolbox/
│   │   └── docs/
│   │       ├── TNF-THREAT-MODEL.md
│   │       └── TNA-THREAT-MODEL.md
│   └── ...
└── .claude/
    └── skills/
        ├── threat-model/
        ├── mitre-findings-tnf.md  # Created automatically on first use
        ├── mitre-findings-tna.md
        ├── mitre-findings-sno.md
        └── mitre-findings-lvms.md
```

### Optional dependencies

- **ShellCheck** (`dnf install ShellCheck`) - for automated shell script analysis
- **gh** CLI - for fetching PR details from GitHub
- **Formal threat model files** - for DFD/STRIDE cross-referencing

## What's Included

| File | Purpose |
|------|---------|
| `skills/tnf-threat-model/SKILL.md` | TNF threat analysis skill |
| `skills/tnf-threat-model/dfd-elements-tnf.md` | TNF DFD element catalog |
| `skills/tna-threat-model/SKILL.md` | TNA threat analysis skill |
| `skills/tna-threat-model/dfd-elements-tna.md` | TNA DFD element catalog |
| `skills/sno-threat-model/SKILL.md` | SNO threat analysis skill |
| `skills/sno-threat-model/dfd-elements-sno.md` | SNO DFD element catalog (SNO-P1–P6, SNO-DS1–DS6, SNO-DF1–DF10, SNO-TB1–TB3) |
| `skills/lvms-threat-model/SKILL.md` | LVMS threat analysis skill |
| `skills/lvms-threat-model/dfd-elements-lvms.md` | LVMS DFD element catalog (placeholder) |
| `references/mitre-reference.md` | MITRE ATT&CK quick reference |
| `references/owasp-reference.md` | OWASP Top 10:2025 reference |
| `references/mitre-findings-template.md` | Cumulative findings tracker template |

## License

Apache-2.0
