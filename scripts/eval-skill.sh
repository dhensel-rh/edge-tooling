#!/usr/bin/bash
set -euo pipefail

EVAL_MODEL="${EVAL_MODEL:-claude-sonnet-4-6}"
BASE_BRANCH="${BASE_BRANCH:-origin/main}"
EVAL_WORKDIR=$(mktemp -d -t skill-eval-XXXXXX)
EVAL_RUNS_DIR="${AGENT_EVAL_RUNS_DIR:-eval/runs}"

trap 'rm -rf "${EVAL_WORKDIR}"' EXIT

# ── Commit status helper ───────────────────────────────────
# Posts GitHub commit status when EVAL_SHA and EVAL_REPO are
# set (by the pre-push hook). No-op on manual invocation.
post_status() {
    local state="$1"
    local description="$2"

    [[ -z "${EVAL_SHA:-}" || -z "${EVAL_REPO:-}" ]] && return 0
    command -v gh >/dev/null 2>&1 || return 0

    gh api "repos/${EVAL_REPO}/statuses/${EVAL_SHA}" \
        -f state="${state}" \
        -f context="skill-eval" \
        -f description="${description}" \
        2>/dev/null || true
}

# ── PR comment helper ──────────────────────────────────────
# Posts eval report as a PR comment on the current branch's PR.
post_pr_comment() {
    local report_file="$1"

    [[ -z "${EVAL_SHA:-}" || -z "${EVAL_REPO:-}" ]] && return 0
    [[ ! -f "${report_file}" ]] && return 0
    command -v gh >/dev/null 2>&1 || return 0

    local body
    body="## Skill Eval Report

$(cat "${report_file}")"

    gh pr comment --edit-last --body "${body}" 2>/dev/null \
        || gh pr comment --body "${body}" 2>/dev/null || true
}

echo "╔══════════════════════════════════════════════╗"
echo "║  Skill Eval — scanning for changed skills    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Step 1: find changed SKILL.md files ─────────────────────
# Scope to the current user's commits only — other people's merged
# work on the branch should not trigger eval.
GIT_USER="$(git config user.name)"
mapfile -t CHANGED_SKILLS < <(
    git log --author="${GIT_USER}" --format="%H" "${BASE_BRANCH}"..HEAD 2>/dev/null \
    | xargs -rI{} git diff-tree --no-commit-id -r --name-only {} \
    | grep '/skills/.*SKILL\.md$' \
    | sort -u \
    || true)

if [[ ${#CHANGED_SKILLS[@]} -eq 0 ]]; then
    echo "No skill files changed, nothing to evaluate."
    exit 0
fi

echo "Changed skills:"
printf '  • %s\n' "${CHANGED_SKILLS[@]}"
echo ""

post_status "pending" "Evaluating ${#CHANGED_SKILLS[@]} skill(s)..."

EVAL_STATUS_POSTED=0
trap 'if [[ "${EVAL_STATUS_POSTED}" -eq 0 ]]; then post_status "error" "Eval crashed unexpectedly"; fi; rm -rf "${EVAL_WORKDIR}"' EXIT

# ── Step 2: for each changed skill, analyze → generate → run ─
TOTAL=0
PASSED=0
FAILED=0
REPORT_FILE="${EVAL_WORKDIR}/summary.txt"
LAST_ANALYSIS=""

for skill_file in "${CHANGED_SKILLS[@]}"; do
    TOTAL=$((TOTAL + 1))

    # Extract plugin and skill name from path
    # e.g. plugins/two-node/skills/cluster-diagnostic/SKILL.md
    plugin=$(echo "${skill_file}" | cut -d'/' -f2)
    skill_dir=$(echo "${skill_file}" | rev | cut -d'/' -f2 | rev)
    skill_name="${plugin}:${skill_dir}"

    config="${EVAL_WORKDIR}/${plugin}-${skill_dir}.yaml"
    cases_dir="${EVAL_WORKDIR}/${plugin}-${skill_dir}/cases"
    mkdir -p "${cases_dir}"

    echo "════════════════════════════════════════════"
    echo "Evaluating: ${skill_name}"
    echo "  Skill file: ${skill_file}"
    echo "  Temp config: ${config}"
    echo "════════════════════════════════════════════"

    # Step 2a: Analyze — generate eval config with judges
    echo "[1/3] Analyzing skill..."
    if ! claude -p "/eval-analyze --skill ${skill_name} --config ${config}" 2>&1; then
        echo "  ⚠ eval-analyze failed for ${skill_name}, skipping."
        FAILED=$((FAILED + 1))
        echo "SKIP  ${skill_name}  (eval-analyze failed)" >> "${REPORT_FILE}"
        continue
    fi

    # Step 2b: Generate — create test scenarios
    echo "[2/3] Generating test scenarios..."
    if ! claude -p "/eval-dataset --config ${config}" 2>&1; then
        echo "  ⚠ eval-dataset failed for ${skill_name}, skipping."
        FAILED=$((FAILED + 1))
        echo "SKIP  ${skill_name}  (eval-dataset failed)" >> "${REPORT_FILE}"
        continue
    fi

    # Step 2c: Run — execute eval and score
    echo "[3/3] Running evaluation..."
    if claude -p "/eval-run --model ${EVAL_MODEL} --config ${config}" 2>&1; then
        PASSED=$((PASSED + 1))
        echo "PASS  ${skill_name}" >> "${REPORT_FILE}"
    else
        FAILED=$((FAILED + 1))
        echo "FAIL  ${skill_name}" >> "${REPORT_FILE}"
    fi

    # Find the most recent analysis.md for this run
    latest_run=$(find "${EVAL_RUNS_DIR}" -name "analysis.md" -newer "${config}" 2>/dev/null \
        | sort | tail -1)
    if [[ -n "${latest_run}" ]]; then
        LAST_ANALYSIS="${latest_run}"
    fi

    echo ""
done

# ── Step 3: print summary report ────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Skill Eval Report                           ║"
echo "╠══════════════════════════════════════════════╣"
printf "║  Skills evaluated: %-24s ║\n" "${TOTAL}"
printf "║  Passed:           %-24s ║\n" "${PASSED}"
printf "║  Failed/Skipped:   %-24s ║\n" "${FAILED}"
echo "╠══════════════════════════════════════════════╣"

if [[ -f "${REPORT_FILE}" ]]; then
    while IFS= read -r line; do
        printf "║  %-43s ║\n" "${line}"
    done < "${REPORT_FILE}"
fi
echo "╚══════════════════════════════════════════════╝"

# ── Step 4: post results to GitHub ──────────────────────────
if [[ "${FAILED}" -gt 0 ]]; then
    post_status "failure" "${PASSED}/${TOTAL} skills passed, ${FAILED} failed"
else
    post_status "success" "${PASSED}/${TOTAL} skills passed"
fi

if [[ -n "${LAST_ANALYSIS}" ]]; then
    post_pr_comment "${LAST_ANALYSIS}"
fi

EVAL_STATUS_POSTED=1

# Always exit 0 — non-blocking
exit 0
