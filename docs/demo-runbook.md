# Demo Runbook — Branching, Promotion & PR Review

Step-by-step guide for the live demo session.

---

## Pre-Flight Checklist

- [ ] Repo is accessible: https://github.com/samueltauil/promotion-code-review
- [ ] All 4 PRs are open and visible (check via Pull Requests tab)
- [ ] Branch protections are active on `dev` and `prod`
- [ ] Labels exist: `feature`, `hotfix`, `breaking-change`, `dataform`
- [ ] GitHub Actions workflows are visible (sql-checks, promotion-gate)
- [ ] Copilot code review is enabled on the repo
- [ ] Screen sharing is ready (browser with GitHub open)

---

## Demo Flow (30 minutes)

### Part 1 — Set the Stage (2 min)

Acknowledge the two agreed priorities from prior conversations:

1. **Primary:** Refine the branch strategy and promotion flow so that only selected, ready changes reach production.
2. **Secondary:** Replace paper-based peer review with automated, PR-based review.

Show the repo README and explain the folder structure:
- `definitions/sources/` → raw data declarations
- `definitions/staging/` → cleaning and joins
- `definitions/marts/` → business aggregations
- Two protected branches: `dev` (integration) and `prod` (production)

**Key message:** "This repo mirrors your Dataform/GCP setup — one repo per subject area, dev and prod branches, code owners gate production. The three scenarios we'll walk through are designed around the specific problems you've described."

---

### Part 2 — Scenario A: Parallel Feature Work (10 min)

> **Pain point addressed:** *Developers start from development, push changes to remote branches, and then struggle to promote only selected changes to production. When multiple developers work in a single repository, promoting selected commits without including unfinished work is extremely difficult.*

**Goal:** Show how feature branches isolate each developer's work so that *only the changes you choose* get promoted — no one else's unfinished work comes along for the ride.

1. Open the **"Add 30-day readmission rate metric"** PR — show the well-filled PR template
2. Open the **"Filter scheduled-only encounters, add emergency count"** PR — show it's a **Draft PR** with an incomplete template
3. Point out: both modify `mart_daily_encounters.sqlx` — a merge conflict exists
4. Show the **Checks** tab: SQL lint and compile checks running
5. Show that the draft PR cannot be merged even if checks pass
6. Walk through resolving the conflict in the GitHub UI (or discuss the workflow)
7. **Key demo moment:** Merge the readmission metric PR into `dev` and show that the other PR's unfinished work is *not* included — only the readmission metric was promoted

**Key messages:**
- Feature branches solve the "selective promotion" problem — each developer's work is isolated until explicitly merged via PR
- Draft PRs give visibility into in-flight work without risk of accidental merge
- Merging one PR does not drag the other's changes along — this is the core difference from working directly on `dev`
- Conflicts are surfaced early in the PR, not discovered during a production deploy

> **Teaching moment — "unexpected merge behavior":** If the team has seen a developer branch absorb all of `dev`'s changes after a merge, explain that this happens when you merge *from* `dev` *into* your branch (to catch up). This is expected Git behavior — not a bug. Feature branches avoid this by staying short-lived and merging *into* `dev` via PR only when ready. Show the PR diff to prove: only the feature's changes are included.

---

### Part 3 — Scenario B: Hotfix Path (10 min)

> **Pain point addressed:** *With only dev and prod branches, there is no clean way to push an emergency fix to production without including unfinished work sitting in dev. The two-environment setup creates a critical bottleneck for hotfixes.*

**Goal:** Show a clean hotfix workflow that starts from `prod` and returns safely to both `dev` and `prod` — proving that you can fix production without touching anything in `dev`.

1. Open the **"Tighten encounter date filter (hotfix → dev integration)"** PR — explain this is for integration testing
2. Open the **"Tighten encounter date filter (hotfix → prod)"** PR — explain this is the production fix
3. **Key demo moment:** Click into the hotfix-to-prod PR's "Files changed" tab and show that *only* the hotfix is in the diff — no feature work, no dev-only changes
4. Show the hotfix branch was created from `prod`, not from `dev` — this is why it doesn't carry unfinished work
5. Show the **Promotion Policy Check** on the hotfix-to-prod PR — it requires a `hotfix` label ✅
6. Show CODEOWNERS requirement on `prod` — code owner must approve
7. Explain the flow: hotfix → PR to prod (deploy) + PR to dev (keep in sync)

**Key messages:**
- Branching from `prod` means the hotfix contains *only* production code + the fix — the bottleneck of "dev has unfinished work" is completely bypassed
- The PR to `dev` ensures the fix is integrated back — no branch divergence, no cherry-pick chaos
- The promotion gate (label policy) forces categorization, so you always know *why* something went to prod
- CODEOWNERS ensures the right people approve — governance is enforced by the system, not by process discipline alone

---

### Part 4 — Scenario C: PR-Based Review (5 min)

> **Pain point addressed:** *The team still relies on paper-based peer review processes and has expressed interest in automating code reviews. Currently only code owners can approve merges into production, but the review process itself is manual.*

**Goal:** Show how PR templates + branch protections turn the existing code-owner approval into a full, auditable review workflow — replacing paper with a digital process that enforces the same rules automatically.

1. Compare the **readmission metric PR** (good template) vs the **encounter logic PR** (bad template) side by side — ask: "Which one would you feel confident promoting to prod?"
2. Show branch protection settings: required reviews, required checks, conversation resolution
3. Show the review comment on the readmission metric PR — demonstrates async review conversation with full context
4. Explain: every PR is a permanent, searchable audit record (who approved, when, what checks passed, what was discussed)
5. Point out: code owners already gate production today — this workflow keeps that model and adds structure around it

**Key messages:**
- The PR template replaces paper checklists — "ready for review" has a consistent, enforceable definition
- The existing code-owner approval model is preserved but now *enforced by GitHub* (not by process discipline)
- Branch protections make the rules automatic — a human can't skip a step, even accidentally
- Review conversations are preserved in the PR (not lost in email threads or paper forms)
- The full history is searchable and auditable — for compliance, onboarding, or post-incident review

---

### Part 5 — Copilot Add-On (3 min)

> **Pain point addressed:** *The team's main challenges are related to lifecycle management rather than code generation. Any Copilot demo should be anchored to lifecycle + review outcomes.*

**Goal:** Show how Copilot directly improves the review and promotion workflow — not code generation, but lifecycle quality.

1. Show Copilot review comments on a PR (if auto-review is active) — point out it flagged a SQL anti-pattern or missing test
2. Demo one prompt from the playbook (e.g., "Review this SQL for anti-patterns") — show it catches things humans miss under time pressure
3. Show how Copilot can generate a PR description from the diff — this directly solves the "bad template" problem from Scenario C
4. Reference the playbook (`docs/copilot-playbook.md`) for repeatable prompts the team can adopt immediately

**Key message:** "Copilot doesn't replace your reviewers or your code owners — it gives them a head start. It catches the mechanical stuff (anti-patterns, missing fields, impact analysis) so your team can focus on business logic and correctness. This is lifecycle support, not code generation."

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
