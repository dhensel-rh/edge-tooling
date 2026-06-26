#!/usr/bin/bash
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

if ! command -v claude &>/dev/null; then
    log "ERROR: claude CLI not found on PATH."
    exit 1
fi

# Find changed SKILL.md files
DIFF_OUTPUT=$(git diff --name-only "${PULL_BASE_SHA}...HEAD") || {
    log "ERROR: git diff failed (PULL_BASE_SHA=${PULL_BASE_SHA}). Is the base SHA valid?"
    exit 1
}

SKILL_FILE=$(echo "${DIFF_OUTPUT}" | grep '^plugins/[^/]*/skills/[^/]*/SKILL\.md$' | head -1 || true)

if [[ -z "${SKILL_FILE}" ]]; then
    log "No skill files changed, nothing to evaluate."
    exit 0
fi

# Verify the skill file exists on disk (not a deletion)
if [[ ! -f "${SKILL_FILE}" ]]; then
    log "Skill file ${SKILL_FILE} was deleted in this PR, nothing to evaluate."
    exit 0
fi

# Extract plugin and skill name from path
# Expected: plugins/<plugin>/skills/<skill>/SKILL.md
if [[ ! "${SKILL_FILE}" =~ ^plugins/[^/]+/skills/[^/]+/SKILL\.md$ ]]; then
    log "ERROR: Unexpected SKILL.md path structure: ${SKILL_FILE}"
    log "Expected: plugins/<plugin>/skills/<skill>/SKILL.md"
    exit 1
fi
PLUGIN=$(echo "${SKILL_FILE}" | cut -d'/' -f2)
SKILL_DIR=$(echo "${SKILL_FILE}" | cut -d'/' -f4)
SKILL_NAME="${PLUGIN}:${SKILL_DIR}"

log "=== Evaluating: ${SKILL_NAME} ==="
log "  Skill file: ${SKILL_FILE}"

PLUGIN_DIR="${EVAL_HARNESS_DIR:-/tmp/agent-eval-harness}"
if [[ ! -d "${PLUGIN_DIR}" ]]; then
    log "ERROR: Plugin directory not found: ${PLUGIN_DIR}"
    log "The ref should clone agent-eval-harness before calling this script."
    exit 1
fi
EVAL_CONFIG="/tmp/eval-${PLUGIN}-${SKILL_DIR}.yaml"

# Generate judges
log ""
log "[1/2] Analyzing skill (generating judges)..."
claude \
    --plugin-dir "${PLUGIN_DIR}" \
    -p "/eval-analyze --skill ${SKILL_NAME} --config ${EVAL_CONFIG}" \
    >&2

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
    >&2

# Verify config still exists and is non-trivial after dataset generation
if [[ ! -s "${EVAL_CONFIG}" ]]; then
    log "ERROR: ${EVAL_CONFIG} is empty after /eval-dataset."
    exit 1
fi

log ""
log "Setup complete. Config: ${EVAL_CONFIG}"

# Output config path — ref picks this up as EVAL_CONFIG
echo "${EVAL_CONFIG}"
