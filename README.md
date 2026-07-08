# Promotion Code Review Demo

A demonstration repository showcasing GitHub branching, promotion workflows, and PR-based code review for data pipeline teams using Dataform and BigQuery.

## Repository Structure

```
definitions/
  sources/       — Source declarations (raw data references)
  staging/       — Staging transformations (cleaning, normalization)
  marts/         — Business-level aggregations and data marts
includes/
  constants.js   — Shared constants (active statuses, date boundaries, facilities)
scripts/
  check_data_standards.py — Deterministic data-pipeline standards gate
docs/
  copilot-playbook.md       — Copilot prompts for PR review workflows
  demo-runbook.md           — Step-by-step live demo guide
  from-advisory-to-enforced.md — Design note: advisory vs fail-closed controls
.github/
  workflows/
    sql-checks.yml          — SQL linting (sqlfluff) and Dataform compile check
    promotion-gate.yml      — Label and description policy for prod PRs
    data-standards-gate.yml — Fail-closed enforcement of mandated data standards
  CODEOWNERS                — Required reviewers for sensitive paths
  copilot-instructions.md   — Custom review instructions for Copilot
  pull_request_template.md  — Standardized PR template with required sections
dataform.json               — Dataform project configuration
reset-demo.sh               — Script to restore repo to demo-ready state
```

## Branching Model

| Branch | Purpose | Protection |
|--------|---------|------------|
| `prod` | Production-ready code | Required reviews, CODEOWNERS approval, status checks |
| `dev`  | Integration branch for feature work | Required reviews, status checks |
| `feature/*` | Individual feature branches (from `dev`) | None |
| `hotfix/*` | Emergency fixes (from `prod`) | None |

## Workflow

1. **Feature work** → branch from `dev` → PR to `dev` → merge after review + checks
2. **Promotion** → PR from `dev` to `prod` → CODEOWNERS approval + all checks pass
3. **Hotfixes** → branch from `prod` → PR to `dev` (integration) → PR to `prod` (deploy)

## CI/CD Checks

Three GitHub Actions workflows enforce quality and governance:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **SQL Checks** | PRs to `dev`/`prod` touching `definitions/` | Lints SQL with sqlfluff and validates `dataform.json` structure |
| **Promotion Gate** | PRs to `prod` | Requires categorization label (`hotfix`, `feature`, or `breaking-change`) and complete PR description |
| **Data Standards Gate** | PRs to `dev`/`prod` touching `definitions/` | Fail-closed enforcement of mandated standards (no `SELECT *`, bounded date ranges, no PII in marts, schema declarations) |

The Data Standards Gate (`scripts/check_data_standards.py`) promotes advisory review heuristics into deterministic checks. When configured as a **required status check** under branch protection, violations block the merge automatically — see [`docs/from-advisory-to-enforced.md`](docs/from-advisory-to-enforced.md) for the design rationale.

## Data Standards Enforced

| Rule | Standard | Scope |
|------|----------|-------|
| R1 | No `SELECT *` (schema drift must be reviewed) | marts, staging |
| R2 | Dated transformations must have a date filter in WHERE | marts, staging |
| R3 | Marts must not surface raw PII columns | marts |
| R4 | Every model must declare a `schema` in its config block | all models |

## Code Review

All changes require pull request review. The [PR template](.github/pull_request_template.md) enforces a consistent structure with required sections:

- **Summary** — what changed and why
- **Testing Evidence** — how the change was validated
- **Risk Assessment** — impact, affected tables, breaking change status
- **Rollback Plan** — how to revert if needed

### Copilot-Assisted Review

GitHub Copilot is configured for automated PR review using custom instructions in [`.github/copilot-instructions.md`](.github/copilot-instructions.md). The [Copilot playbook](docs/copilot-playbook.md) provides repeatable prompts for:

- Auto-generating PR descriptions from diffs
- Reviewing SQL for BigQuery anti-patterns
- Generating change impact summaries
- Drafting validation queries
- Identifying missing test coverage

## CODEOWNERS

Production-critical paths require approval from designated owners:

- `definitions/marts/` — senior review required
- `dataform.json` — config changes reviewed
- `.github/workflows/` — CI/CD changes reviewed

## Getting Started

1. Clone the repository
2. Review the [demo runbook](docs/demo-runbook.md) for the full walkthrough
3. Branch from `dev` for feature work, from `prod` for hotfixes
4. Open a PR using the template and ensure all checks pass before requesting review

## Resetting the Demo

Run `./reset-demo.sh` to restore all branches, PRs, and branch protections to their demo-ready state. Requires the `gh` CLI with repo admin permissions.
