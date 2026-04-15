# Promotion Code Review Demo

A demonstration repository showcasing GitHub branching, promotion workflows, and PR-based code review for data pipeline teams using Dataform and BigQuery.

## Repository Structure

```
definitions/
  sources/       — Source declarations (raw data references)
  staging/       — Staging transformations (cleaning, normalization)
  marts/         — Business-level aggregations and data marts
includes/        — Shared constants, macros, and helper functions
docs/            — Documentation, runbooks, and playbooks
dataform.json    — Dataform project configuration
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

## Code Review

All changes require pull request review. See the [PR template](.github/pull_request_template.md) for required fields.
