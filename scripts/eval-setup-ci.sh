#!/usr/bin/env bash
#
# CI setup script for the openshift-claude-agent-eval step.
#
# Called via EVAL_SETUP_SCRIPT before /eval-run. Discovers the changed
# skill in the PR, generates judges and fresh cases, and outputs the
# eval config path on stdout for the ref to use as EVAL_CONFIG.
#
# Expects:
#   PULL_BASE_SHA    — set by Prow
#   EVAL_HARNESS_DIR — set by the ref after cloning the eval harness

set -euo pipefail

log() { echo "$*" >&2; }

if [[ -z "${PULL_BASE_SHA:-}" ]]; then
    log "PULL_BASE_SHA not set, cannot detect changed skills."
    exit 1
fi

# Find changed SKILL.md files
SKILL_FILE=$(
    git diff --name-only "${PULL_BASE_SHA}...HEAD" 2>/dev/null \
    | grep '/skills/.*SKILL\.md$' \
    | head -1 \
    || true
)

if [[ -z "${SKILL_FILE}" ]]; then
    log "No skill files changed, nothing to evaluate."
    exit 0
fi

# Extract plugin and skill name from path
# e.g. plugins/two-node/skills/cluster-diagnostic/SKILL.md
PLUGIN=$(echo "${SKILL_FILE}" | cut -d'/' -f2)
SKILL_DIR=$(echo "${SKILL_FILE}" | rev | cut -d'/' -f2 | rev)
SKILL_NAME="${PLUGIN}:${SKILL_DIR}"

log "=== Evaluating: ${SKILL_NAME} ==="
log "  Skill file: ${SKILL_FILE}"

PLUGIN_DIR="${EVAL_HARNESS_DIR:-/tmp/agent-eval-harness}"
EVAL_CONFIG="/tmp/eval-${PLUGIN}-${SKILL_DIR}.yaml"

# Generate judges
log ""
log "[1/2] Analyzing skill (generating judges)..."
claude \
    --plugin-dir "${PLUGIN_DIR}" \
    -p "/eval-analyze --skill ${SKILL_NAME} --config ${EVAL_CONFIG}" \
    2>&1 >&2

if [[ ! -f "${EVAL_CONFIG}" ]]; then
    log "ERROR: /eval-analyze did not produce ${EVAL_CONFIG}"
    exit 1
fi

# Generate fresh cases
log ""
log "[2/2] Generating fresh test cases..."
claude \
    --plugin-dir "${PLUGIN_DIR}" \
    -p "/eval-dataset --config ${EVAL_CONFIG}" \
    2>&1 >&2

log ""
log "Setup complete. Config: ${EVAL_CONFIG}"

# Output config path — ref picks this up as EVAL_CONFIG
echo "${EVAL_CONFIG}"
