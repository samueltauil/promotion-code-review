# Copilot for PR Review — Playbook

How to use GitHub Copilot to improve code review quality, consistency, and speed in data pipeline workflows.

---

## 1. Auto-Generate PR Descriptions from Diffs

**When to use:** After completing a feature or fix, before requesting review.

**Prompt (in Copilot Chat):**
```
Summarize the changes in this PR for a reviewer. Include: what changed, why, 
what downstream tables are affected, and any risks.
```

**Why it helps:** Ensures every PR has a complete, consistent description — even when developers forget to fill out the template.

---

## 2. Review SQL for Anti-Patterns

**When to use:** During code review of any `.sqlx` file change.

**Prompt:**
```
Review this SQL for BigQuery anti-patterns, performance issues, and data quality 
risks. Flag any SELECT * usage, missing partition filters, unbounded date ranges, 
or implicit type conversions.
```

**Why it helps:** Catches common SQL issues that manual reviewers might miss, especially in complex window functions or joins.

---

## 3. Generate a Change Impact Summary

**When to use:** For PRs that modify staging or mart tables with downstream dependencies.

**Prompt:**
```
List all tables and views that depend on the files changed in this PR. 
Describe the potential impact of these changes on downstream consumers.
```

**Why it helps:** Makes it easy for approvers to understand blast radius without tracing dependencies manually.

---

## 4. Draft Validation Queries

**When to use:** When a PR modifies data transformations and needs testing evidence.

**Prompt:**
```
Generate 3 validation queries I can run against the development dataset to verify 
this change is correct. Include row count checks, null checks, and a sample 
comparison between before and after.
```

**Why it helps:** Provides ready-to-run test queries that reviewers can use to verify correctness, replacing ad-hoc manual testing.

---

## 5. Identify Missing Test Coverage

**When to use:** During review of any data model change.

**Prompt:**
```
What assertions or tests are missing for this data model? Consider null checks, 
uniqueness constraints, referential integrity, and value range validations.
```

**Why it helps:** Ensures that Dataform assertions cover edge cases that could cause silent data quality issues in production.

---

## Talking Points for the Demo

| Topic | Key Message |
|-------|------------|
| **Review quality** | Copilot catches SQL anti-patterns and missing tests that humans often overlook during time-pressured reviews. |
| **Consistency** | Auto-generated PR descriptions ensure every change is documented the same way, making audits and rollbacks easier. |
| **Speed** | Reviewers spend less time understanding "what changed" and more time on "is this correct?" |
| **Safer promotion** | Impact summaries and validation queries reduce the risk of promoting breaking changes to production. |
| **Not replacing humans** | Copilot assists reviewers — it doesn't replace the approval workflow. Human judgment + CODEOWNERS still gate production. |

---

## Configuration

Copilot code review can be enabled at the repository level:
1. Go to **Settings → Copilot → Code review**
2. Enable **Copilot code review**
3. Optionally add custom review instructions in a `.github/copilot-code-review-instructions.md` file

For this demo repo, Copilot is configured to review all PRs automatically.
