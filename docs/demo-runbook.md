# Demo Runbook — Branching, Promotion & PR Review

Step-by-step guide for the live demo session.

---

## Pre-Flight Checklist

- [ ] Repo is accessible: https://github.com/samueltauil/promotion-code-review
- [ ] All 4 PRs are open and visible (#1–#4)
- [ ] Branch protections are active on `dev` and `prod`
- [ ] Labels exist: `feature`, `hotfix`, `breaking-change`, `dataform`
- [ ] GitHub Actions workflows are visible (sql-checks, promotion-gate)
- [ ] Copilot code review is enabled on the repo
- [ ] Screen sharing is ready (browser with GitHub open)

---

## Demo Flow (30 minutes)

### Part 1 — Set the Stage (2 min)

Show the repo README and explain the folder structure:
- `definitions/sources/` → raw data declarations
- `definitions/staging/` → cleaning and joins
- `definitions/marts/` → business aggregations
- Two protected branches: `dev` (integration) and `prod` (production)

**Key message:** "This mirrors your project structure. Let's see how changes flow through it safely."

---

### Part 2 — Scenario A: Parallel Feature Work (10 min)

**Goal:** Show that two developers can work simultaneously without accidentally promoting each other's work.

1. Open **PR #1** (readmission metric) — show the well-filled PR template
2. Open **PR #2** (encounter logic update) — show it's a **Draft PR** with an incomplete template
3. Point out: both modify `mart_daily_encounters.sqlx` — a merge conflict exists
4. Show the **Checks** tab: SQL lint and compile checks running
5. Show that PR #2 is Draft → cannot be merged even if checks pass
6. Walk through resolving the conflict in the GitHub UI (or discuss the workflow)

**Key messages:**
- Draft PRs give visibility without risk of accidental merge
- Required checks catch issues before review
- Conflicts are surfaced early, not at deployment time
- The PR template ensures "ready for review" means something specific

---

### Part 3 — Scenario B: Hotfix Path (10 min)

**Goal:** Show how a production bug fix flows through without dragging unfinished dev work.

1. Open **PR #3** (hotfix → dev) — explain this is for integration testing
2. Open **PR #4** (hotfix → prod) — explain this is the production fix
3. Show the hotfix branch was created from `prod`, not from `dev`
4. Show the **Promotion Policy Check** on PR #4 — it requires a `hotfix` label ✅
5. Show CODEOWNERS requirement on `prod` — code owner must approve
6. Explain the flow: hotfix → test in dev → promote to prod → dev gets the fix too

**Key messages:**
- Hotfixes don't pull unfinished feature work into production
- The promotion gate (label policy) enforces categorization
- CODEOWNERS ensures the right people approve production changes
- Both `dev` and `prod` get the fix (no divergence)

---

### Part 4 — Scenario C: PR-Based Review (5 min)

**Goal:** Show how PR templates + branch protections replace manual/paper-based review.

1. Compare PR #1 (good template) vs PR #2 (bad template) side by side
2. Show branch protection settings: required reviews, required checks, conversation resolution
3. Show the review comment on PR #1 — demonstrates async review conversation
4. Explain: every PR is an auditable record (who approved, when, what checks passed)

**Key messages:**
- The PR template standardizes what "ready" means
- Branch protections enforce the rules automatically
- Review conversations are preserved (not lost in email/paper)
- You can search and audit the full history

---

### Part 5 — Copilot Add-On (3 min)

**Goal:** Show how Copilot accelerates the review workflow (not replaces it).

1. Show Copilot review comments on a PR (if auto-review is active)
2. Demo one prompt from the playbook (e.g., "Review this SQL for anti-patterns")
3. Show how Copilot can generate a PR description from the diff
4. Reference the playbook (`docs/copilot-playbook.md`) for repeatable prompts

**Key message:** "Copilot helps reviewers focus on business logic by handling the mechanical parts of review."

---

## Decision Workshop Prompts (use after demo)

Use these questions to drive decisions:

1. **Branch model:** "Is `dev` + `prod` sufficient, or do you need a `staging`/`UAT` branch?"
2. **Promotion rule:** "What evidence should be required before merging to prod? (tests, peer review, manager approval?)"
3. **Hotfix flow:** "Who should approve hotfixes? Same team or a designated on-call?"
4. **Conflict handling:** "How often should feature branches rebase from dev? Daily? Before PR?"
5. **Code review:** "Are you ready to move review into PRs now, or do you want a parallel period?"
6. **Copilot:** "Is Copilot PR review something you want to enable now or evaluate later?"

---

## Fallback Plan

| If this breaks... | Do this instead... |
|---|---|
| GitHub Actions not running | Show the workflow YAML files and explain what they do |
| Copilot review not showing | Use the playbook prompts manually in Copilot Chat |
| Merge conflict demo doesn't work | Show the diff side-by-side and explain how GitHub surfaces it |
| Branch protections not visible | Show the API response / Settings UI screenshot |

---

## Post-Demo Deliverables

- [ ] Share repo link with attendees
- [ ] Capture decisions from the workshop
- [ ] Draft the 1-page branching + promotion design document
- [ ] Set up follow-up cadence
