#!/usr/bin/bash

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${TEST_DIR}/../request_art_builds.sh"
FIXTURES="${TEST_DIR}/fixtures"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/request_art_builds_test.XXXXXX")"
trap 'rm -rf "${TEST_ROOT}"' EXIT

PASS=0
FAIL=0
CASE_NUMBER=0
LAST_CASE=""

# Record a passing assertion.
pass() {
  PASS=$((PASS + 1))
  printf 'PASS: %s\n' "$1"
}

# Record a failed assertion without aborting the suite.
fail() {
  FAIL=$((FAIL + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

# Run an assertion command and record its status.
assert_true() {
  local name="$1"
  shift
  if "$@" >/dev/null; then pass "${name}"; else fail "${name}"; fi
}

# Require a literal value in a captured output file.
assert_file_contains() {
  local name="$1" file="$2" pattern="$3"
  if grep -F -- "${pattern}" "${file}" >/dev/null; then pass "${name}"; else fail "${name}"; fi
}

# Require a literal value to be absent from captured output.
assert_file_excludes() {
  local name="$1" file="$2" pattern="$3"
  if grep -F -- "${pattern}" "${file}" >/dev/null; then fail "${name}"; else pass "${name}"; fi
}

# Run one isolated scenario with curl replaced by the local fixture.
run_case() {
  local scenario="$1"
  shift
  CASE_NUMBER=$((CASE_NUMBER + 1))
  LAST_CASE="${TEST_ROOT}/case-${CASE_NUMBER}"
  mkdir -p "${LAST_CASE}/tmp" "${LAST_CASE}/state"
  : > "${LAST_CASE}/requests.jsonl"
  : > "${LAST_CASE}/slack.jsonl"
  : > "${LAST_CASE}/U-WILDX"

  (
    cd "${LAST_CASE}"
    env \
      PATH="${FIXTURES}:${PATH}" \
      TMPDIR="${LAST_CASE}/tmp" \
      JIRA_BASE_URL="${CASE_JIRA_BASE_URL:-https://jira.example.test}" \
      JIRA_USER_EMAIL="operator@example.test" \
      JIRA_API_TOKEN="not-a-real-token" \
      SLACK_WEBHOOK_URL="https://hooks.example.test/mock" \
      SLACK_CC_USER_IDS="${CASE_CC_USERS:-}" \
      MOCK_SCENARIO="${scenario}" \
      MOCK_ART_KEY="ART-55" \
      MOCK_QE_KEY="USHIFT-66" \
      MOCK_REQUEST_LOG="${LAST_CASE}/requests.jsonl" \
      MOCK_SLACK_LOG="${LAST_CASE}/slack.jsonl" \
      MOCK_SLACK_URL="https://hooks.example.test/mock" \
      MOCK_STATE_DIR="${LAST_CASE}/state" \
      "${SCRIPT}" "$@" > "${LAST_CASE}/stdout" 2> "${LAST_CASE}/stderr"
  )
}

# Require an invalid invocation to fail with a specific safe message.
expect_invalid() {
  local name="$1" expected="$2"
  shift 2
  if run_case validation "$@"; then
    fail "${name}"
  else
    assert_file_contains "${name}" "${LAST_CASE}/stderr" "${expected}"
  fi
}

# Input validation: positive execution and representative negative near-misses.
if run_case new_success 4.20.7 2026-11-18 2026-11-20 --reason SENSITIVE-REASON-SENTINEL; then
  pass "valid version and dates complete with offline mocks"
else
  fail "valid version and dates complete with offline mocks"
fi
NEW_CASE="${LAST_CASE}"

expect_invalid "version rejects missing patch" "Version must be X.Y.Z" \
  4.20 2026-11-18 2026-11-20 --reason test
expect_invalid "version rejects suffix" "Version must be X.Y.Z" \
  4.20.7-rc.1 2026-11-18 2026-11-20 --reason test
expect_invalid "date rejects non-padded month" "ART_DUE must be YYYY-MM-DD" \
  4.20.7 2026-1-18 2026-11-20 --reason test
expect_invalid "date rejects invalid calendar day" "ART_DUE is not a valid calendar date" \
  4.20.7 2026-02-30 2026-11-20 --reason test
expect_invalid "date rejects reversed chronology" "cannot be after RELEASE_DATE" \
  4.20.7 2026-11-21 2026-11-20 --reason test

# The new-ticket flow preserves private input in outbound payloads without logging it.
assert_true "ART payload substitutes the real version" jq -e -s '
  any(.[];
    .method == "POST"
    and (.url | endswith("/rest/api/3/issue"))
    and ((.data | fromjson | .. | strings) == "Build 4.20.7 TEMPLATE-DESCRIPTION-SENTINEL")
  )
' "${NEW_CASE}/requests.jsonl"
assert_true "outgoing Jira payload preserves the supplied reason" jq -e -s '
  any(.[];
    .method == "POST"
    and (.url | endswith("/rest/api/3/issue"))
    and any((.data | fromjson | .. | strings); . == "Reason: SENSITIVE-REASON-SENTINEL")
  )
' "${NEW_CASE}/requests.jsonl"
assert_true "ART blocks QE in the captured POST payload" jq -e -s '
  any(.[];
    .method == "POST"
    and (.url | endswith("/rest/api/3/issueLink"))
    and (.data | fromjson | .inwardIssue.key == "ART-101")
    and (.data | fromjson | .outwardIssue.key == "USHIFT-202")
  )
' "${NEW_CASE}/requests.jsonl"
assert_true "multi-page search follows nextPageToken" jq -e -s '
  any(.[]; .method == "GET" and (.url | contains("nextPageToken")))
' "${NEW_CASE}/requests.jsonl"
assert_file_contains "new notification uses the real ART key" "${NEW_CASE}/slack.jsonl" "ART-101"
assert_file_contains "new flow prints both real issue keys" "${NEW_CASE}/stdout" "ART-101 USHIFT-202"

# A desired existing link is inward from ART when reading the QE issue.
if run_case reuse_desired 4.20.7 2026-11-18 2026-11-20 --reason reuse; then
  pass "duplicate labels reuse matching issues and desired link"
else
  fail "duplicate labels reuse matching issues and desired link"
fi
REUSE_CASE="${LAST_CASE}"
assert_true "reuse performs no issue creation" jq -e -s '
  all(.[]; .method != "POST" or ((.url | endswith("/issue")) | not))
' "${REUSE_CASE}/requests.jsonl"
assert_true "ordinary rerun skips notification" test ! -s "${REUSE_CASE}/slack.jsonl"
assert_file_contains "reuse returns existing issue keys" "${REUSE_CASE}/stdout" "ART-55 USHIFT-66"

# A reverse outward link on QE is rejected before any mutation.
if run_case reverse_link 4.20.7 2026-11-18 2026-11-20 --reason reverse; then
  fail "reverse link is rejected"
else
  assert_file_contains "reverse link is rejected" "${LAST_CASE}/stderr" "Conflicting reverse link detected"
fi
REVERSE_CASE="${LAST_CASE}"
assert_true "reverse-link preflight performs no POST" jq -e -s 'all(.[]; .method != "POST")' \
  "${REVERSE_CASE}/requests.jsonl"

# A partial rerun remains manual: --resend-slack explicitly requests recovery.
CASE_CC_USERS='U-WILD* U-EXTRA'
if run_case partial 4.20.7 2026-11-18 2026-11-20 --reason recovery --resend-slack; then
  pass "explicit resend recovers a partial run"
else
  fail "explicit resend recovers a partial run"
fi
PARTIAL_CASE="${LAST_CASE}"
unset CASE_CC_USERS
assert_file_contains "explicit resend posts notification" "${PARTIAL_CASE}/slack.jsonl" "ART-55"
assert_file_contains "wildcard recipient remains literal" "${PARTIAL_CASE}/slack.jsonl" '<@U-WILD*>'
assert_file_excludes "wildcard recipient does not expand a filename" "${PARTIAL_CASE}/slack.jsonl" '<@U-WILDX>'

# Dry-run previews and Jira failures must not expose descriptions, reasons, bodies, or base URLs.
if run_case dry_run 4.20.7 2026-11-18 2026-11-20 --reason SENSITIVE-REASON-SENTINEL --dry-run; then
  pass "dry-run completes with redacted previews"
else
  fail "dry-run completes with redacted previews"
fi
DRY_CASE="${LAST_CASE}"
assert_file_excludes "dry-run hides the reason" "${DRY_CASE}/stderr" "SENSITIVE-REASON-SENTINEL"
assert_file_excludes "dry-run hides copied descriptions" "${DRY_CASE}/stderr" "TEMPLATE-DESCRIPTION-SENTINEL"
assert_file_excludes "dry-run hides the Jira base URL" "${DRY_CASE}/stderr" "jira.example.test"
assert_file_contains "dry-run documents preview redaction" "${DRY_CASE}/stderr" "reason redacted"

if run_case search_failure 4.20.7 2026-11-18 2026-11-20 --reason SENSITIVE-REASON-SENTINEL; then
  fail "failing search aborts"
else
  pass "failing search aborts"
fi
FAIL_CASE="${LAST_CASE}"
assert_file_contains "HTTP failure logs only status and safe endpoint" "${FAIL_CASE}/stderr" \
  "Jira API request failed (HTTP 500): GET /rest/api/3/search/jql"
assert_file_excludes "HTTP failure hides raw response body" "${FAIL_CASE}/stderr" "RAW-ERROR-BODY-SENTINEL"
assert_file_excludes "HTTP failure hides the reason" "${FAIL_CASE}/stderr" "SENSITIVE-REASON-SENTINEL"
assert_file_excludes "HTTP failure hides the Jira base URL" "${FAIL_CASE}/stderr" "jira.example.test"
assert_true "failing search performs no POST" jq -e -s 'all(.[]; .method != "POST")' \
  "${FAIL_CASE}/requests.jsonl"

CASE_JIRA_BASE_URL='https://sample-user:sample-pass@jira.example.test'
if run_case validation 4.20.7 2026-11-18 2026-11-20 --reason test; then
  fail "credential-bearing Jira URL is rejected"
else
  assert_file_contains "credential-bearing Jira URL is rejected" "${LAST_CASE}/stderr" \
    "JIRA_BASE_URL must be an HTTPS URL without embedded credentials"
fi
assert_file_excludes "credential-bearing Jira URL is not echoed" "${LAST_CASE}/stderr" \
  "sample-user:sample-pass@jira.example.test"
unset CASE_JIRA_BASE_URL

printf '\nResults: %d passed, %d failed\n' "${PASS}" "${FAIL}"
[[ ${FAIL} -eq 0 ]]
