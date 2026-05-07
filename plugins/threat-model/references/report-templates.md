# Report Templates

Shared report naming conventions and output templates used by all threat-model skills.
Each skill substitutes its own topology name (TNA, TNF, SNO, LVMS) where indicated.

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
**Topology**: <topology>
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

This PR affects the following elements in the <topology> Data Flow Diagram
(see <topology>-THREAT-MODEL.md):

### Affected DFD Elements

| Element | Name | Impact | Trust Boundary |
|---------|------|--------|----------------|
| P# | [process name] | [what changed] | TB# |
| DS# | [store name] | [what changed] | TB# |
| DF# | [flow description] | [what changed] | TB#->TB# |

### Trust Boundary Crossings

[Describe any trust boundaries crossed by the changed code]

### Per-Element STRIDE

| Element | S | T | R | I | D | E | Notes |
|---------|---|---|---|---|---|---|-------|
| P# | - | - | - | - | - | - | [Processes: all 6] |
| DS# | N/A | - | N/A | - | - | N/A | [Data Stores: T, I, D] |
| DF# | N/A | - | N/A | - | - | N/A | [Data Flows: T, I, D] |
| EE# | - | N/A | - | N/A | N/A | N/A | [External Entities: S, R] |

**Legend**: **X** = new threat found, **~** = existing threat modified, **-** = no impact, N/A = not applicable

### Threat Model Cross-Reference

| PR Finding | Existing PE-* ID | Status |
|------------|-----------------|--------|
| [finding] | PE-XX-X-X | Matches existing / New gap / Mitigated |

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

[Detailed description of the vulnerability]

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

#### Before Merge

1. [Code fix or change required in this PR]

#### After Merge

1. [Follow-up code improvement, test addition, or refactor]

### For Customers (Deployment & Operations)

#### Configuration Hardening

1. [Cluster configuration or hardening recommendation]

#### Operational Practices

1. [Monitoring, incident response, or day-2 operational guidance]

---

## References

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [MITRE ATT&CK](https://attack.mitre.org/)
- [Relevant CVEs, CWEs, documentation]
```

## Report Format: Individual Vulnerability (for Critical/High findings)

```markdown
# Security Ticket: [Vulnerability Title]

**Ticket ID**: VULN-PR<number>-<seq>
**Severity**: CRITICAL/HIGH
**Component**: <repo>
**Status**: Open
**Created**: YYYY-MM-DD
**PR**: #<number>

## Summary

[One paragraph summary]

## Affected Code

**File**: `path/to/file.go:lines`

## Exploitation

### Attack Flow

[ASCII diagram or description of attack flow]

### Exploit Examples

[Code examples showing exploitation]

## Impact

[Detailed impact analysis]

## Recommended Fix

### For Developers

[Code showing the fix with explanation]

### For Customers

[Deployment hardening, configuration changes, or monitoring guidance]

## References

- [CWE, OWASP, other references]
```
