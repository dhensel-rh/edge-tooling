---
name: threat-model:sno
description: Analyze a PR for SNO (Single Node OpenShift) security threats with STRIDE/DFD analysis, MITRE ATT&CK and OWASP mapping
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, WebFetch
argument-hint: "<PR-number | GitHub-URL | repo PR-number>"
---

# SNO PR Threat Analysis

Analyze a pull request for security threats against the **SNO (Single Node OpenShift)** topology, map to MITRE ATT&CK, and generate a formal report.

This skill focuses on SNO-specific DFD elements, trust boundaries, and code paths. For TNF analysis, use `/threat-model:tnf`. For TNA, use `/threat-model:tna`.

## Reference Files

Bundled with this skill:

- `dfd-elements-sno.md` — SNO DFD element catalog (SNO-P1–P6, SNO-DS1–DS6, SNO-DF1–DF10, SNO-TB1–TB3)

Shared references (in `$PLUGIN_DIR/references/`):

- `mitre-reference.md` — MITRE ATT&CK lookup with DFD element mappings
- `owasp-reference.md` — OWASP Top 10:2025 mapping with DFD element cross-references
- `mitre-findings-template.md` — Template for cumulative findings tracker

Discovered at runtime from the workspace:

- `$THREAT_MODEL_DIR/SNO-THREAT-MODEL.md` — SNO formal threat model (when available)
- `$FINDINGS_FILE` — SNO findings tracker (created from template on first use)

## Workspace Discovery

Before starting analysis, discover the workspace layout.

### Discovery Steps

1. **Find workspace root**: Walk upward from `$PWD` until a directory containing `repos/` is found. If no parent qualifies, fall back to checking whether the current git repo sits inside a `repos/` directory:

   ```bash
   d="$PWD"
   while [ "$d" != "/" ]; do
     if [ -d "$d/repos" ]; then
       echo "$d"
       break
     fi
     d="$(dirname "$d")"
   done
   if [ "$d" = "/" ]; then
     repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
     if [ -n "$repo_root" ] && [ "$(basename "$(dirname "$repo_root")")" = "repos" ]; then
       echo "$(dirname "$(dirname "$repo_root")")"
     fi
   fi
   ```

2. **Set workspace paths**: Once the workspace root (`WORKSPACE`) is found:
   - **Repos directory**: `$WORKSPACE/repos/`
   - **Threat model**: Look for `SNO-THREAT-MODEL.md` in:
     - `$WORKSPACE/repos/sno-deploy/docs/`
     - `$WORKSPACE/docs/`
     - The current directory
   - **Report output**: If `$REPORT_DIR` is already set in the environment, use it directly. Otherwise, write reports to the same directory where the threat model is found. If not found, write to `$WORKSPACE/reports/` (create if needed).
   - **Findings tracker**: `$WORKSPACE/.claude/skills/threat-model/mitre-findings-sno.md` — initialized from `$PLUGIN_DIR/references/mitre-findings-template.md` on first use.

3. **Validate workspace**: Warn the user if:
   - No `repos/` directory is found
   - Required repos for the target PR are not cloned locally
   - Formal threat model file (`SNO-THREAT-MODEL.md`) is not found (analysis can still proceed, but cross-referencing will be skipped)

### Path Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `$WORKSPACE` | Root directory containing `repos/` | `/home/user/Projects/sno-dev-env` |
| `$REPOS` | Repos directory | `$WORKSPACE/repos` |
| `$THREAT_MODEL_DIR` | Directory containing formal threat model | `$REPOS/sno-deploy/docs` |
| `$REPORT_DIR` | Directory for generated reports | Same as `$THREAT_MODEL_DIR` or `$WORKSPACE/reports` |
| `$FINDINGS_FILE` | SNO findings tracker | `$WORKSPACE/.claude/skills/threat-model/mitre-findings-sno.md` |

### Findings File

Each threat-model skill writes to its own findings file (`mitre-findings-tnf.md`, `mitre-findings-tna.md`, `mitre-findings-sno.md`, `mitre-findings-lvms.md`), so no file locking is required during concurrent execution.

**Append protocol** (use in step 12):

```bash
FINDINGS_FILE="$WORKSPACE/.claude/skills/threat-model/mitre-findings-sno.md"

mkdir -p "$(dirname "$FINDINGS_FILE")"
cp -n "RESOLVED_TEMPLATE_PATH" "$FINDINGS_FILE"

cat >> "$FINDINGS_FILE" <<'FINDINGS_BLOCK'

## SNO — REPO PR #NUMBER (YYYY-MM-DD)

| Technique ID | Technique Name | Finding | Severity | Status | Notes |
|--------------|----------------|---------|----------|--------|-------|
| T#### | Name | VULN-# | Severity | Open | Description |

---
FINDINGS_BLOCK
```

Substitute `RESOLVED_TEMPLATE_PATH` with the absolute path to `$PLUGIN_DIR/references/mitre-findings-template.md` (resolved from this skill's directory). Fill in `REPO`, `NUMBER`, `YYYY-MM-DD`, and the table rows from the current analysis.

## Input Formats

### Option 1: PR Number Only

```text
/threat-model:sno 10498
```

Detects the repository from the current working directory.

### Option 2: GitHub PR URL

```text
/threat-model:sno https://github.com/openshift/installer/pull/10498
```

### Option 3: Explicit repo and PR

```text
/threat-model:sno installer 10498
```

## Parsing Logic

1. **If input is a URL** (contains `github.com`):
   - Extract org/repo/PR from: `https://github.com/<org>/<repo>/pull/<PR>`

2. **If input is a single number**:
   - Detect repo from current directory path
   - Look for pattern `repos/<repo-name>/` in the working directory

3. **If input is `<repo> <number>`**:
   - Use provided repo name
   - Look up org from the repository mapping table

## Repository Mapping

| Repo | GitHub Org |
|------|------------|
| installer | openshift |
| machine-config-operator | openshift |
| cluster-etcd-operator | openshift |
| assisted-service | openshift |
| origin | openshift |
| dev-scripts | openshift-metal3 |
| release | openshift |

## Instructions

1. **Discover workspace** using the Workspace Discovery steps above
2. **Parse input** to determine org, repo, and PR number
3. **Fetch PR details** using `gh pr view <PR> --repo <org>/<repo>` or WebFetch
4. **Get changed files** with `gh pr diff <PR> --repo <org>/<repo>` or WebFetch
5. **Run ShellCheck** on any shell scripts in the changed files (see Automated Scanner section)
6. **Analyze all changes** for security-relevant patterns (see Security Patterns)
7. **Map to DFD elements** — identify which DFD elements are affected using the SNO mapping table below and `dfd-elements-sno.md`
8. **Apply per-element STRIDE** to affected elements and cross-reference against `$THREAT_MODEL_DIR/SNO-THREAT-MODEL.md` (if found)
9. **Combine findings** from ShellCheck + AI analysis + DFD/STRIDE analysis
10. **Map findings to MITRE ATT&CK** techniques (see `$PLUGIN_DIR/references/mitre-reference.md`)
11. **Generate report** at `$REPORT_DIR/`
12. **Append findings to tracker** — follow the Append Protocol to write a findings block to `$FINDINGS_FILE`

---

## Automated Scanner: ShellCheck

ShellCheck is available in RHEL/Fedora repos (`dnf install ShellCheck`) - no external downloads required.

### Installation Check

```bash
command -v shellcheck >/dev/null && echo "shellcheck: installed" || echo "shellcheck: NOT installed (run: dnf install ShellCheck)"
```

### Running ShellCheck

```bash
shellcheck -f json <script-file>
shellcheck -S warning <script-file>
shellcheck -s bash <script-file>
```

### Security-Relevant ShellCheck Codes

| Code | Severity | Security Relevance | MITRE |
|------|----------|-------------------|-------|
| SC2086 | Warning | Unquoted variable - command injection risk | T1059 |
| SC2091 | Warning | Command in $() used as condition - injection | T1059 |
| SC2046 | Warning | Unquoted command substitution | T1059 |
| SC2012 | Info | Parsing ls output - can be exploited | T1059 |
| SC2029 | Warning | ssh command with unescaped variables | T1059 |
| SC2087 | Warning | Unquoted heredoc - variable expansion | T1059 |
| SC2155 | Warning | Declare/assign separately to avoid masking errors | - |
| SC2164 | Warning | cd without error-exit guard - path traversal risk | T1083 |

---

## Optional External Scanners

| Tool | Source | Risks | Mitigations |
|------|--------|-------|-------------|
| **Semgrep** | pip/GitHub | Fetches rules from semgrep.dev; may send telemetry | Use `--offline` mode with local rules |
| **Gitleaks** | GitHub releases | Binary from external source | Verify checksums; use container image |
| **gosec** | GitHub/go install | Binary from external source | Verify checksums; audit source |

---

## Security Patterns to Detect

| Category | Patterns | MITRE | Severity |
|----------|----------|-------|----------|
| Command Injection | shell exec, os.system, subprocess, fmt.Sprintf with shell | T1059 | Critical |
| Credentials | hardcoded secrets, API keys, tokens, passwords in code | T1552 | Critical |
| Privilege Escalation | setuid, capabilities, privileged containers, sudo, nsenter | T1548 | High |
| Authentication | auth bypass, weak validation, token handling flaws | T1078 | High |
| Crypto Weakness | weak algorithms, hardcoded keys, disabled TLS verify | T1573 | High |
| Path Traversal | unsanitized file paths, symlink attacks | T1083 | Medium |
| Container Escape | host mounts, hostPID, hostNetwork, privileged mode | T1611 | Critical |
| Logging Exposure | sensitive data in logs, credential printing | T1005 | Medium |
| SSRF/Network | unvalidated URLs, exposed internal endpoints | T1046 | Medium |
| Deserialization | unsafe unmarshal, pickle, yaml.load | T1059 | High |

## SNO DFD Element Mapping

See `dfd-elements-sno.md` for the full element catalog.

### Code Path to DFD Element

| Code Path Pattern | DFD Element | STRIDE Focus |
|-------------------|-------------|--------------|
| `installer/pkg/types/installconfig.go` (IsSingleNodeOpenShift, BootstrapInPlace) | SNO-P1 (Installer) | T, D |
| `installer/pkg/asset/machines/master.go` (SingleReplicaTopologyMode) | SNO-P1 | T, D |
| `installer/pkg/types/validation/installconfig.go` (BootstrapInPlace) | SNO-P1 | T |
| `installer/data/data/bootstrap/bootstrap-in-place/` | SNO-P5 (Bootstrap Agent) | T, I, E |
| `assisted-service/internal/common/common.go` (IsSingleNodeCluster) | SNO-P2 (Assisted Service) | T |
| `assisted-service/internal/cluster/validator.go` (SNO validations) | SNO-P2 | S, T |
| `assisted-service/internal/host/validator.go` (SNO host checks) | SNO-P2 | T |
| `cluster-etcd-operator/pkg/operator/ceohelpers/bootstrap.go` (UnsafeScalingStrategy) | SNO-P4 (CEO) | T, D |
| `cluster-etcd-operator/pkg/operator/ceohelpers/control_plane_topology.go` | SNO-P4 | T, D |
| `machine-config-operator/` (MachineConfig, kubelet config) | SNO-P3 (MCO) | T, E |
| `sno-deploy/day_two/templates/` (DU policy generation, workload partitioning) | SNO-P3 (MCO), SNO-DS6 | T |
| `origin/test/extended/` (SNO test code) | Test | - |

### Trust Boundary Crossings

When a PR modifies code that crosses a trust boundary, apply additional scrutiny:

| Boundary Crossing | Code Indicators | Key Threats |
|-------------------|-----------------|-------------|
| SNO-TB1->SNO-TB2 (Admin -> Assisted Service) | install-config, offline-token, pull-secret, API calls to console.redhat.com | I (credential exposure), T (config tampering) |
| SNO-TB2->SNO-TB3 (Assisted Service -> SNO Node) | Discovery ISO generation, ignition delivery, host inventory | T (ISO tampering), I (ignition secrets), E (privileged bootstrap) |
| SNO-TB1->SNO-TB3 (Admin -> SNO Node) | oc/kubectl, kubeconfig, kubeadmin-password | S (admin impersonation), I (credential theft) |

### Per-Element STRIDE for PR Analysis

For each affected DFD element, ask these questions:

**Processes (all 6 STRIDE categories)**:

- **S**: Can the process be impersonated? Are auth checks adequate?
- **T**: Can inputs/outputs be modified? Is data validated?
- **R**: Are actions auditable? Are logs adequate and redacted?
- **I**: Does it handle secrets? Are they protected in transit/at rest?
- **D**: Can it be crashed or blocked? What happens on failure? (Critical for SNO — no failover)
- **E**: Does it run with minimal privilege? Can it be abused for escalation?

**Data Stores (T, I, D)**:

- **T**: Can stored data be modified by unauthorized parties?
- **I**: Is sensitive data encrypted? Who can read it?
- **D**: Can the store be corrupted or deleted? (Single etcd member — total loss)

**Data Flows (T, I, D)**:

- **T**: Can data in transit be modified? Is integrity verified?
- **I**: Is the channel encrypted? Are credentials visible?
- **D**: Can the flow be interrupted or flooded?

**External Entities (S, R)**:

- **S**: Can the entity be impersonated? Is authentication enforced?
- **R**: Can the entity deny having performed an action? Are interactions logged?

### Cross-Referencing the Threat Model

After identifying per-element threats, check against `$THREAT_MODEL_DIR/SNO-THREAT-MODEL.md`:

1. Search for relevant `PE-SNO-<element>-*` IDs in the Per-Element STRIDE Analysis section
2. If a PR introduces a **new** threat not covered by existing PE-* entries, flag it as a gap
3. If a PR **mitigates** an existing PE-* threat, note it as a positive finding
4. If a PR **worsens** an existing PE-* threat, flag with elevated severity

If the formal threat model file is not found, skip cross-referencing and note this in the report.

---

## Report Output

Use report templates from `$PLUGIN_DIR/references/report-templates.md`. Set `<topology>` to **SNO** when filling in the templates.
