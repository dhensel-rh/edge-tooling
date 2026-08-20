# Maintaining This Documentation

## Automatic Submodule Update Detection

A Claude Code hook checks whether git submodules (e.g., `two-node-toolbox/`) are behind their remote tracking branch at session start. If a submodule is stale, Claude will report how many commits it is behind and offer to update it.

**Hook location:** `.claude/hooks/update-submodules.sh`

**Behavior:**

1. Silently initializes any uninitialized submodules
2. Fetches from each submodule's remote and compares the pinned commit to the remote branch tip
3. If any submodules are behind, Claude reports the details and asks if you'd like to update
4. If you accept, Claude runs `git submodule update --remote <path>`, stages the change, and commits

The hook resolves each submodule's tracking branch in order: `.gitmodules` branch config, `origin/HEAD`, `main`, `master`. It exits silently if offline or if no `.gitmodules` file exists.

## Automatic New Tool Detection

This repository includes a Claude Code hook that automatically detects new tool directories at session start. When a new tool directory is added (a directory with a Makefile or README.md), Claude will:

1. Detect the undocumented tool
2. Notify the user
3. Offer to update the AGENTS.md file

**Hook location:** `.claude/hooks/detect-new-tools.sh`

**When adding a new tool**, update the `DOCUMENTED_TOOLS` array in the hook script:

```bash
DOCUMENTED_TOOLS=(
    "two-node-toolbox"
    "ec2-deploy"
    "sno-deploy"
    "payload-monitor"
    "ci-tooling"
    "ci-tooling/readiness-report"
    "environments/lvm-operator"
    "plugins"
    "your-new-tool"  # Add new tools here
)
```

The hook scans top-level directories and nested collections under `environments/` and `ci-tooling/`. When adding a helper under `ci-tooling/`, add both the parent (`ci-tooling`) if it is new and the nested path (`ci-tooling/<name>`).
