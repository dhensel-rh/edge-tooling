# Evaluation Configs

Automated quality scoring for two-node plugin skills using the
[agent-eval-harness](https://github.com/opendatahub-io/agent-eval-harness)
Claude Code plugin.

Evals measure skill quality on a spectrum (judges score 1-5, not
pass/fail) — they catch regressions and drift, not exact-match
correctness.

## Available Evals

| Config | Skill | Modes Tested | Cases |
|--------|-------|--------------|-------|
| `cluster-diagnostic.yaml` | `two-node:cluster-diagnostic` | validate, recovery-guide, game | 6 |
| `threat-model-tnf.yaml` | `threat-model:tnf` | PR analysis | 5 |

## Running Locally

```bash
# Install the eval harness plugin
/plugin marketplace add opendatahub-skills/agent-eval-harness

# Run an existing eval
/eval-run --model claude-opus-4-6 --config evals/cluster-diagnostic.yaml
```

To create a new eval, see [Adding a New Eval](#adding-a-new-eval) below.

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
            ├── input.yaml      # Scenario input
            └── annotations.yaml # Expected outcomes
```

## Adding a New Eval

1. **Analyze the skill** — reads SKILL.md, designs judges, writes the eval config
   ```
   /eval-analyze --skill <name> --config evals/<name>.yaml
   ```

2. **Generate scenarios** — creates `input.yaml` + `annotations.yaml` per case
   ```
   /eval-dataset --config evals/<name>.yaml
   ```

3. **Run the eval** — executes the skill against each case, scores with judges, generates HTML report
   ```
   /eval-run --model claude-opus-4-6 --config evals/<name>.yaml
   ```

4. **Review results** — walk through cases, collect human feedback
   ```
   /eval-review --run-id <run-id> --config evals/<name>.yaml
   ```

5. **(Optional) Optimize** — auto-fix SKILL.md based on judge failures, re-run to verify
   ```
   /eval-optimize --config evals/<name>.yaml
   ```

6. **Commit and CI**
   - Commit `evals/<name>.yaml`, `evals/<name>.md`, and `evals/<name>/cases/` to this repo
   - Add a CI entry in [openshift/release](https://github.com/openshift/release)
     pointing `EVAL_CONFIG` to the yaml path
   - PR reviewers can then trigger the eval with `/test eval-<name>`
