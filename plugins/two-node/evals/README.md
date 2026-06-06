# Evaluation Configs

Automated quality testing for two-node plugin skills using the
[agent-eval-harness](https://github.com/opendatahub-io/agent-eval-harness)
Claude Code plugin.

## Available Evals

| Config | Skill | Modes Tested | Cases |
|--------|-------|--------------|-------|
| `cluster-diagnostic.yaml` | `two-node:cluster-diagnostic` | validate, recovery-guide | 5 |
| `threat-model-tnf.yaml` | `threat-model:tnf` | PR analysis | 5 |

## Running Locally

```bash
# Install the eval harness plugin first
/plugin marketplace add opendatahub-skills/agent-eval-harness

# Run an eval
/eval-run --model claude-opus-4-6 --config evals/cluster-diagnostic.yaml
```

## Running in CI

Comment `/test eval-cluster-diagnostic` on a PR to trigger the eval job.
The CI workflow is defined in
[openshift/release](https://github.com/openshift/release) under
`ci-operator/config/openshift-eng/edge-tooling/`.

## Directory Structure

```
evals/
├── <skill-name>.yaml           # Eval config (judges, thresholds, schema)
├── <skill-name>.md             # Cached skill analysis
└── <skill-name>/
    └── cases/
        └── case-NNN-<slug>/
            ├── input.yaml      # Test input
            └── annotations.yaml # Expected outcomes
```

## Adding a New Eval

1. `/eval-analyze --skill <name> --config evals/<name>.yaml`
2. `/eval-dataset --config evals/<name>.yaml`
3. `/eval-run --model claude-opus-4-6 --config evals/<name>.yaml`
4. `/eval-review --run-id <id> --config evals/<name>.yaml`
5. Commit the config, analysis, and cases. Run artifacts are ephemeral.
