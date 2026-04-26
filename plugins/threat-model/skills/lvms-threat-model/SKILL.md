---
name: threat-model:lvms
description: Analyze a PR for LVMS (LVM Storage) security threats with STRIDE/DFD analysis, MITRE ATT&CK and OWASP mapping
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, WebFetch
argument-hint: "<PR-number | GitHub-URL | repo PR-number>"
---

# LVMS PR Threat Analysis

Analyze a pull request for security threats against the **LVMS (LVM Storage)** operator, map to MITRE ATT&CK, and generate a formal report.

> **Note**: The LVMS DFD model (`dfd-elements-lvms.md`) is not yet defined. This skill will perform general security analysis, ShellCheck scanning, and MITRE/OWASP mapping. DFD element mapping and STRIDE cross-referencing will be available once the DFD model is created.

## Reference Files

Bundled with this skill:

- `dfd-elements-lvms.md` — LVMS DFD element catalog (placeholder — not yet modeled)

Shared references (in `../../references/`):

- `mitre-reference.md` — MITRE ATT&CK lookup with DFD element mappings
- `owasp-reference.md` — OWASP Top 10:2025 mapping with DFD element cross-references
- `mitre-findings-template.md` — Template for cumulative findings tracker

Discovered at runtime from the workspace:

- `$THREAT_MODEL_DIR/LVMS-THREAT-MODEL.md` — LVMS formal threat model (when available)
- `$FINDINGS_FILE` — LVMS findings tracker (created from template on first use)

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
   - **Threat model**: Look for `LVMS-THREAT-MODEL.md` in:
     - `$WORKSPACE/repos/lvm-operator/docs/`
     - `$WORKSPACE/docs/`
     - The current directory
   - **Report output**: Write reports to the same directory where the threat model is found. If not found, write to `$WORKSPACE/reports/` (create if needed).
   - **Findings tracker**: `$WORKSPACE/.claude/skills/threat-model/mitre-findings-lvms.md` — initialized from `../../references/mitre-findings-template.md` on first use.

3. **Validate workspace**: Warn the user if:
   - No `repos/` directory is found
   - Required repos for the target PR are not cloned locally
   - DFD model is not yet defined (analysis proceeds without DFD mapping)

### Path Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `$WORKSPACE` | Root directory containing `repos/` | `/home/user/Projects/lvm-workspace` |
| `$REPOS` | Repos directory | `$WORKSPACE/repos` |
| `$THREAT_MODEL_DIR` | Directory containing formal threat model | `$REPOS/lvm-operator/docs` |
| `$REPORT_DIR` | Directory for generated reports | Same as `$THREAT_MODEL_DIR` or `$WORKSPACE/reports` |
| `$FINDINGS_FILE` | LVMS findings tracker | `$WORKSPACE/.claude/skills/threat-model/mitre-findings-lvms.md` |

### Findings File

Each threat-model skill writes to its own findings file (`mitre-findings-tnf.md`, `mitre-findings-tna.md`, `mitre-findings-sno.md`, `mitre-findings-lvms.md`), so no file locking is required during concurrent execution.

**Append protocol** (use in step 12):

```bash
FINDINGS_FILE="$WORKSPACE/.claude/skills/threat-model/mitre-findings-lvms.md"

mkdir -p "$(dirname "$FINDINGS_FILE")"
cp -n "RESOLVED_TEMPLATE_PATH" "$FINDINGS_FILE"

cat >> "$FINDINGS_FILE" <<'FINDINGS_BLOCK'

## LVMS — REPO PR #NUMBER (YYYY-MM-DD)

| Technique ID | Technique Name | Finding | Severity | Status | Notes |
|--------------|----------------|---------|----------|--------|-------|
| T#### | Name | VULN-# | Severity | Open | Description |

---
FINDINGS_BLOCK
```

Substitute `RESOLVED_TEMPLATE_PATH` with the absolute path to `../../references/mitre-findings-template.md` (resolved from this skill's directory). Fill in `REPO`, `NUMBER`, `YYYY-MM-DD`, and the table rows from the current analysis.

## Input Formats

### Option 1: PR Number Only

```text
/threat-model:lvms 2271
```

Detects the repository from the current working directory.

### Option 2: GitHub PR URL

```text
/threat-model:lvms https://github.com/openshift/lvm-operator/pull/2271
```

### Option 3: Explicit repo and PR

```text
/threat-model:lvms lvm-operator 2271
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
| lvm-operator | openshift |
| origin | openshift |

## Instructions

1. **Discover workspace** using the Workspace Discovery steps above
2. **Parse input** to determine org, repo, and PR number
3. **Fetch PR details** using `gh pr view <PR> --repo <org>/<repo>` or WebFetch
4. **Get changed files** with `gh pr diff <PR> --repo <org>/<repo>` or WebFetch
5. **Run ShellCheck** on any shell scripts in the changed files (see Automated Scanner section)
6. **Analyze all changes** for security-relevant patterns (see Security Patterns)
7. **Map to DFD elements** — if `dfd-elements-lvms.md` has been populated, map changed files to affected DFD elements. If not yet modeled, skip and note in the report.
8. **Apply per-element STRIDE** to affected elements (if DFD is available) and cross-reference against `$THREAT_MODEL_DIR/LVMS-THREAT-MODEL.md` (if found)
9. **Combine findings** from ShellCheck + AI analysis + DFD/STRIDE analysis
10. **Map findings to MITRE ATT&CK** techniques (see `../../references/mitre-reference.md`)
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

## LVMS DFD Element Mapping

> **Not yet modeled.** Once `dfd-elements-lvms.md` is populated with DFD elements, add code path mapping and trust boundary crossing tables here.

When the DFD is available, the analysis should follow the same STRIDE methodology as TNF/TNA:

- Map changed files to affected DFD elements
- Apply per-element STRIDE questions
- Cross-reference against `LVMS-THREAT-MODEL.md`

---

## Report Naming Convention

- **Full threat model**: `PR<number>-THREAT-MODEL-<repo>.md`
- **Individual vuln**: `VULN-PR<number>-<short-desc>.md`

## Report Format: Threat Model

```markdown
# PR #<number> Threat Analysis: <PR Title>

**Document Version**: 1.0
**Date**: YYYY-MM-DD
**Classification**: Internal - Security Sensitive
**Repository**: <repo>
**Topology**: LVMS
**PR Author**: <author>
**PR URL**: <url>

---

## Executive Summary

[Brief overview of the PR and key security findings]

### Findings Summary

| Severity | Count | Summary |
|----------|-------|---------|
| Critical | X | [brief] |
| High | X | [brief] |
| Medium | X | [brief] |
| Low | X | [brief] |

---

## Change Overview

[What this PR does, its purpose, and security-relevant changes]

---

## Affected Files

| File | Changes | Security Relevance |
|------|---------|-------------------|
| path/to/file.go | +X/-Y lines | [relevance] |

---

## DFD Impact Analysis

> DFD model not yet defined for LVMS. This section will be populated once `dfd-elements-lvms.md` is created.

---

## Threat Analysis

### VULN-1: [Vulnerability Title]

**Severity**: Critical/High/Medium/Low
**OWASP**: A##:2025 - Category Name
**MITRE ATT&CK**: T#### - Technique Name
**CWE**: CWE-###

#### Affected Code

**File**: `path/to/file.go:line`

#### Description

[Detailed description]

#### Attack Vector

[How this could be exploited]

#### Impact

- **Confidentiality**: [impact]
- **Integrity**: [impact]
- **Availability**: [impact]

#### Recommended Fix

[Code showing the fix]

---

## OWASP & MITRE ATT&CK Mapping

| Finding | OWASP | MITRE | CWE | Status |
|---------|-------|-------|-----|--------|
| VULN-1 | A05:2025 Injection | T1059 | CWE-78 | Open |

---

## Risk Assessment

| Finding | Likelihood | Impact | Risk |
|---------|------------|--------|------|
| VULN-1 | High | Critical | Critical |

---

## Recommendations

### For Developers (Code Changes)

1. [Recommendations]

### For Customers (Deployment & Operations)

1. [Recommendations]

---

## References

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [MITRE ATT&CK](https://attack.mitre.org/)
```

## Available Repositories

| Repo | Org | Focus Areas |
|------|-----|-------------|
| lvm-operator | openshift | CSI driver, VG management, privilege, LVM commands |
| origin | openshift | Test code security |
