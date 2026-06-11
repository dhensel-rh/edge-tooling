---
name: threat-model:tnf
description: Analyze a PR for TNF (Two-Node Fencing) security threats with STRIDE/DFD analysis, MITRE ATT&CK and OWASP mapping
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, WebFetch
argument-hint: "<PR-number | GitHub-URL | repo PR-number>"
---

# TNF PR Threat Analysis

Analyze a pull request for security threats against the **TNF (Two-Node Fencing)** topology, map to MITRE ATT&CK, and generate a formal report.

This skill focuses on TNF-specific DFD elements, trust boundaries, and code paths. For TNA analysis, use `/threat-model:tna`.

## Reference Files

Bundled with this skill:

- `dfd-elements-tnf.md` — TNF DFD element catalog (P1-P8, DS1-DS5, DF1-DF12, TB1-TB6)

Shared references (in `$PLUGIN_DIR/references/`):

- `mitre-reference.md` — MITRE ATT&CK lookup with DFD element mappings
- `owasp-reference.md` — OWASP Top 10:2025 mapping with DFD element cross-references
- `mitre-findings-template.md` — Template for cumulative findings tracker

Discovered at runtime from the workspace:

- `$THREAT_MODEL_DIR/TNF-THREAT-MODEL.md` — TNF formal threat model with DFD and per-element STRIDE analysis
- `$FINDINGS_FILE` — TNF findings tracker (created from template on first use)

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
   - **Threat model**: Look for `TNF-THREAT-MODEL.md` in:
     - `$WORKSPACE/repos/two-node-toolbox/docs/`
     - `$WORKSPACE/docs/`
     - The current directory
   - **Report output**: If `$REPORT_DIR` is already set in the environment, use it directly. Otherwise, write reports to the same directory where the threat model is found. If not found, write to `$WORKSPACE/reports/` (create if needed).
   - **Findings tracker**: `$WORKSPACE/.claude/skills/threat-model/mitre-findings-tnf.md` — initialized from `$PLUGIN_DIR/references/mitre-findings-template.md` on first use.

3. **Validate workspace**: Warn the user if:
   - No `repos/` directory is found
   - Required repos for the target PR are not cloned locally
   - Threat model reference file is not found (analysis can still proceed, but DFD cross-referencing will be skipped)

### Path Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `$WORKSPACE` | Root directory containing `repos/` | `/home/user/Projects/tnf-dev-env` |
| `$REPOS` | Repos directory | `$WORKSPACE/repos` |
| `$THREAT_MODEL_DIR` | Directory containing formal threat model | `$REPOS/two-node-toolbox/docs` |
| `$REPORT_DIR` | Directory for generated reports | Same as `$THREAT_MODEL_DIR` or `$WORKSPACE/reports` |
| `$FINDINGS_FILE` | TNF findings tracker | `$WORKSPACE/.claude/skills/threat-model/mitre-findings-tnf.md` |

### Findings File

Each threat-model skill writes to its own findings file (`mitre-findings-tnf.md`, `mitre-findings-tna.md`, `mitre-findings-sno.md`, `mitre-findings-lvms.md`), so no file locking is required during concurrent execution.

**Append protocol** (use in step 12):

```bash
FINDINGS_FILE="$WORKSPACE/.claude/skills/threat-model/mitre-findings-tnf.md"

mkdir -p "$(dirname "$FINDINGS_FILE")"
cp -n "RESOLVED_TEMPLATE_PATH" "$FINDINGS_FILE"

cat >> "$FINDINGS_FILE" <<'FINDINGS_BLOCK'

## TNF — REPO PR #NUMBER (YYYY-MM-DD)

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
/threat-model:tnf 2136
```

Detects the repository from the current working directory. Must be inside a repo under `$REPOS/<repo>/`.

### Option 2: GitHub PR URL

```text
/threat-model:tnf https://github.com/ClusterLabs/resource-agents/pull/2136
```

Extracts org, repo, and PR number from the URL automatically.

### Option 3: Explicit repo and PR

```text
/threat-model:tnf resource-agents 2136
```

Specify repo name and PR number explicitly.

## Parsing Logic

1. **If input is a URL** (contains `github.com`):
   - Extract org/repo/PR from: `https://github.com/<org>/<repo>/pull/<PR>`

2. **If input is a single number**:
   - Detect repo from current directory path
   - Look for pattern `repos/<repo-name>/` in the working directory
   - Use the repo's configured remote to determine the org

3. **If input is `<repo> <number>`**:
   - Use provided repo name
   - Look up org from the repository mapping table

## Repository Mapping

| Repo | GitHub Org |
|------|------------|
| assisted-service | openshift |
| cluster-etcd-operator | openshift |
| machine-config-operator | openshift |
| installer | openshift |
| cluster-baremetal-operator | openshift |
| resource-agents | ClusterLabs |
| origin | openshift |
| dev-scripts | openshift-metal3 |
| release | openshift |
| enhancements | openshift |
| openshift-docs | openshift |
| pacemaker | ClusterLabs |

## Instructions

1. **Discover workspace** using the Workspace Discovery steps above
2. **Parse input** to determine org, repo, and PR number
3. **Fetch PR details** using `gh pr view <PR> --repo <org>/<repo>` or WebFetch
4. **Get changed files** with `gh pr diff <PR> --repo <org>/<repo>` or WebFetch
5. **Run ShellCheck** on any shell scripts in the changed files (see Automated Scanner section)
6. **Analyze all changes** for security-relevant patterns (see Security Patterns)
7. **Map to DFD elements** — identify which DFD elements are affected using the TNF mapping table below and `dfd-elements-tnf.md`
8. **Apply per-element STRIDE** to affected elements and cross-reference against `$THREAT_MODEL_DIR/TNF-THREAT-MODEL.md` (if found)
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

### Include in Report

Add ShellCheck results under Automated Scanner Results:

```markdown
## Automated Scanner Results

### ShellCheck

**Tool**: ShellCheck (from RHEL repos)
**Version**: X.X.X

| Code | Severity | File | Line | Message |
|------|----------|------|------|---------|
| SC2086 | warning | podman-etcd | 42 | Double quote to prevent globbing and word splitting |
```

If ShellCheck is not installed, note: *Not installed. Install with: `dnf install ShellCheck`*
If no shell scripts in PR, note: *No shell scripts in this PR - skipped.*

---

## Optional External Scanners

The following scanners provide additional coverage but require **external downloads**. Use at your own discretion.

| Tool | Source | Risks | Mitigations |
|------|--------|-------|-------------|
| **Semgrep** | pip/GitHub | Fetches rules from semgrep.dev; may send telemetry | Use `--offline` mode with local rules |
| **Gitleaks** | GitHub releases | Binary from external source | Verify checksums; use container image |
| **gosec** | GitHub/go install | Binary from external source | Verify checksums; audit source |

```bash
command -v semgrep >/dev/null && echo "semgrep: installed" || echo "semgrep: not installed (external)"
command -v gitleaks >/dev/null && echo "gitleaks: installed" || echo "gitleaks: not installed (external)"
command -v gosec >/dev/null && echo "gosec: installed" || echo "gosec: not installed (external)"
```

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

## TNF DFD Element Mapping

See `dfd-elements-tnf.md` for the full element catalog.

### Code Path to DFD Element

| Code Path Pattern | DFD Element | STRIDE Focus |
|-------------------|-------------|--------------|
| `assisted-service/internal/installcfg/` | P1 (Installer) | I, T, R |
| `assisted-service/internal/bminventory/` | P1 (Installer) | I, S, T |
| `assisted-service/models/fencing*` | P1 (Installer), DF1 | I, T |
| `cluster-etcd-operator/pkg/tnf/operator/` | P2 (CEO Controller) | S, D, E |
| `cluster-etcd-operator/pkg/tnf/auth/` | P3 (Auth Job) | S, E |
| `cluster-etcd-operator/pkg/tnf/setup/` | P4 (Setup Job) | T, I, E, D |
| `cluster-etcd-operator/pkg/tnf/fencing/` | P5 (Fencing Job) | I, T, R, E |
| `cluster-etcd-operator/pkg/tnf/pkg/pcs/fencing*` | P5, DF7, DF9 | I, T |
| `cluster-etcd-operator/pkg/tnf/pkg/pcs/cluster*` | P4, DS3 | T, D |
| `cluster-etcd-operator/pkg/tnf/pkg/tools/secrets*` | DS2, DF4 | I, T |
| `cluster-etcd-operator/pkg/tnf/pkg/tools/redact*` | P5, DF9 | I, R |
| `cluster-etcd-operator/pkg/tnf/pkg/exec/` | P3-P5 (nsenter) | E |
| `cluster-etcd-operator/bindata/tnfdeployment/job*` | P3-P5 (container spec) | E |
| `pacemaker/daemons/fenced/` | P6 (fenced) | S, I, D |
| `resource-agents/heartbeat/podman-etcd` | P7 (OCF Agent) | T, D, I |
| `resource-agents/heartbeat/podman` | P7 (OCF Agent) | T, D |
| `machine-config-operator/templates/*two-node*` | DS4 (PCSD setup) | T, E |
| `installer/pkg/asset/agent/manifests/fencing*` | P1, DS1, DF1, DF2 | I, T |

### Trust Boundary Crossings

When a PR modifies code that crosses a trust boundary, apply additional scrutiny:

| Boundary Crossing | Code Indicators | Key Threats |
|-------------------|-----------------|-------------|
| TB2->TB3 (K8s -> Privileged Container) | Job specs, SA tokens, secret reads | E (escape), I (secret leak) |
| TB3->TB4 (Container -> Host) | nsenter calls, hostPID, privileged | E (host access), T (CIB tamper) |
| TB4->TB5 (Host -> BMC) | fence_redfish calls, Redfish URLs | S (MITM), I (credential exposure) |
| TB2->TB4 (Secrets -> CIB) | Secret->pcs command pipeline | I (plaintext creds in XML) |
| TB6 (Inter-Node) | Corosync config, PCSD auth | S (spoofing), D (quorum loss) |

### Per-Element STRIDE for PR Analysis

For each affected DFD element, ask these questions:

**Processes (all 6 STRIDE categories)**:

- **S**: Can the process be impersonated? Are auth checks adequate?
- **T**: Can inputs/outputs be modified? Is data validated?
- **R**: Are actions auditable? Are logs adequate and redacted?
- **I**: Does it handle secrets? Are they protected in transit/at rest?
- **D**: Can it be crashed or blocked? What happens on failure?
- **E**: Does it run with minimal privilege? Can it be abused for escalation?

**Data Stores (T, I, D)**:

- **T**: Can stored data be modified by unauthorized parties?
- **I**: Is sensitive data encrypted? Who can read it?
- **D**: Can the store be corrupted or deleted?

**Data Flows (T, I, D)**:

- **T**: Can data in transit be modified? Is integrity verified?
- **I**: Is the channel encrypted? Are credentials visible?
- **D**: Can the flow be interrupted or flooded?

**External Entities (S, R)**:

- **S**: Can the entity be impersonated? Is authentication enforced?
- **R**: Can the entity deny having performed an action? Are interactions logged?

### Cross-Referencing the Threat Model

After identifying per-element threats, check against `$THREAT_MODEL_DIR/TNF-THREAT-MODEL.md`:

1. Search for relevant `PE-<element>-*` IDs in the Per-Element STRIDE Analysis section
2. If a PR introduces a **new** threat not covered by existing PE-* entries, flag it as a gap
3. If a PR **mitigates** an existing PE-* threat, note it as a positive finding
4. If a PR **worsens** an existing PE-* threat, flag with elevated severity

If the formal threat model file is not found, skip cross-referencing and note this in the report.

---

## Report Output

Use report templates from `$PLUGIN_DIR/references/report-templates.md`. Set `<topology>` to **TNF** when filling in the templates.
