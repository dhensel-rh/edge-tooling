# MicroShift Release Activities

Automate MicroShift Release Testing Activities — from pre-release evaluation through build validation, CI verification, advisory promotion, and post-release checks.

## Outgoing Build-Request Notifications

`scripts/request_art_builds.sh` reads the entire incoming-webhook URL from
`SLACK_WEBHOOK_URL`. Inject it at runtime through a protected CI secret or your
shell's secure secret-injection mechanism. Never hardcode it, commit it in a
`.env` file, put it in query parameters or request text, or print it in logs.
The URL must use HTTPS without userinfo, query parameters, or fragments.

The script disables shell tracing and keeps the webhook out of curl arguments.
Do not enable tracing around secret injection: the script cannot undo anything
the calling shell logged before launch. `--dry-run` and `--skip-slack` do not
require the webhook; `--resend-slack` explicitly notifies for a reused ticket.
`--skip-slack` prints a manual message, so keep its reason text free of secrets.
If a webhook is exposed, rotate it through Slack and update the injected secret.
The script neither provisions nor rotates webhooks.

## Installation

```text
/plugin marketplace add openshift-eng/edge-tooling
/plugin install microshift-release
```

## Skills

| Skill | Phase | When | Description |
|---|---|---|---|
| `/microshift-release:pre-check` | Pre-Check (Phase 0) | Every Friday before end of the day | Evaluate whether MicroShift should participate in an OCP release (z-stream, nightly, EC/RC) |
| `/microshift-release:release-versions` | Info (Phase 0) | Anytime after ART has created RPMs and bootc images | Report details about all artifacts: RPMs, bootc images, and Brew builds |
| `/microshift-release:validate-artifacts` | Build Validation (Phase 1) | As soon as ART has created RPMs and bootc images | Validate MicroShift built artifacts (RPMs and bootc images) produced by ART |
| `/microshift-release:automated-testing` | Automated Testing (Phase 2) | As soon as Phase 1 is done | Run the full Prow CI release testing workflow — create PR, trigger jobs, check status, download and upload artifacts |
| Not Applicable | Manual Testing (Phase 2) | Manual testing must be performed on new features only for non-z-stream versions (X.Y.0 or RHEA), in case they cannot be automated or haven't been automated yet. As soon as Phase 1 is done | Run some manual tests  |
| `/microshift-release:advisory-promotion` | Advisory Promotion (Phase 3) | Start in parallel with Phase 1, but wait for Phase 2 to finish before signing off Errata and Shipment | Validate Konflux bootc advisory promotion for QE sign-off — verify advisory YAML, catalog presence, shipment MR, and commit provenance |
| `/microshift-release:post-release` | Post-Release (Phase 4) | After sign-off in Errata Tool (REL_PREP) and Shipment (approved) | Verify all artifacts and docs are publicly available after shipping — bootc images, RPMs, errata, documentation, and lifecycle page |

## How To

### Request ART to create a new Z-Stream

For every Z-Stream marked as `ASK ART` in Pre-Check (Phase 0) output.

This is automated by `scripts/request_art_builds.sh`, which creates (or reuses
a matching existing) ART and USHIFT ticket, links them, and posts the Slack
request for you:

```shell
scripts/request_art_builds.sh <X.Y.Z> <ART_DUE_DATE> <RELEASE_DATE> --reason "<TEXT>"
```

Use the ART and USHIFT ticket keys printed by the run — don't clone the
templates below on top of them. See
[Outgoing Build-Request Notifications](#outgoing-build-request-notifications)
for required secrets, and run with `--dry-run` first to preview the result
without writing to Jira or Slack. Use `--help` for the full flag list.

To do this manually instead:

 1. Clone this [template ART Jira ticket](https://redhat.atlassian.net/browse/ART-11857) and replace the target version in the title
 1. Share it in Slack [#forum-ocp-art](https://redhat.enterprise.slack.com/archives/CB95J6R4N) channel, template message example:

```text
Hello, @release-artists I've opened ${ID_TO_ART_TICKET_CREATED} requesting MicroShift X.Y.Z builds (due date DDth MM). Please help create RPMs and bootc images, thanks!
cc @Pablo Acevedo @Rama kasturi @AlejandroGullon @Tami Love
```

### Track Release Testing Activities

For every Z-Stream release requested to ART:

 1. Open the USHIFT ticket created by `request_art_builds.sh` (or clone the
    [template USHIFT Jira ticket](https://redhat.atlassian.net/browse/USHIFT-6945)
    and replace the target version and date in the title if tracking manually)
 1. Go through the steps described in the template ticket, log results, and mark each completed step.

## Requirements

- VPN connection (for Brew RPM checks, advisory reports)
- Kerberos login: `kinit`
- GitLab API token: `GITLAB_API_TOKEN`
- Jira API token: `JIRA_API_TOKEN` and `JIRA_USERNAME`
- `gh` CLI (for PR operations in automated testing)
- `aws` CLI (for S3 build cache and artifact upload)
- `gsutil` CLI (for GCS artifact download)
