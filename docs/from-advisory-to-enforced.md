# From Advisory Review to Fail-Closed Control

This note explains the `data-standards-gate` workflow and the idea behind it: how
a repository moves from *distributing* a standard to *enforcing* it, and why that
distinction is the load-bearing one once an automated agent is the author of a
change.

## The gap this closes

The repository already demonstrates strong governance:

- **`CODEOWNERS`** requires a named human to approve changes to sensitive paths.
- **`promotion-gate.yml`** checks PR metadata (labels, description sections).
- **`sql-checks.yml`** lints SQL style and validates the Dataform config.
- **`docs/copilot-playbook.md`** gives reviewers excellent prompts for catching
  SQL anti-patterns, PII exposure, and missing tests.

Every one of those, on its own, is either a *human-in-the-loop* control
(CODEOWNERS, review) or an *advisory* one (a playbook prompt a reviewer chooses to
run; a lint step that reports). None of them mechanically *refuses* a change that
violates a mandated data standard.

That is fine when a careful human writes and reviews every change. It stops being
fine the moment the author is an agent operating at machine speed, because:

> An instruction the agent ignores produces no signal.
> A required status check refuses the merge every time.

A `copilot-instructions.md`, or a review prompt in a playbook, is a **suggestion**
the model may follow. It is a speed-limit sign. A required status check wired to
branch protection is a **speed bump** -- it does not ask, it stops. Distributing
the sign to every repository in an organization scales the *suggestion*; it does
not scale the *control*.

## What the gate does

`scripts/check_data_standards.py` promotes three of the playbook's advisory
heuristics into deterministic, fail-closed checks over `definitions/**`:

| Rule | Standard enforced | Scope |
|------|-------------------|-------|
| R1 | No `SELECT *` (schema drift is reviewed, not silent) | marts, staging |
| R2 | Dated transformations must bound the scan with a date filter | marts, staging |
| R3 | Marts must not surface raw PII columns | marts |
| R4 | Every model must declare a `schema` in its config block | all models |

The rule set is intentionally narrow and mechanical. It does **not** judge
business logic or correctness -- that is exactly where an agent reviewer and a
human reviewer still add value. It enforces only the non-negotiable standards that
must never regress, even on an unattended merge. The PII column list and the
directory scopes at the top of the script are meant to be edited to match the
organization's actual mandated standards.

Exit `0` = standards satisfied. Exit `1` = at least one violation.

## The step that makes it a gate

Adding the workflow file is not enough. A workflow that reports but cannot block is
still advisory. It becomes control only when it is a **required status check**:

1. Settings -> Branches -> branch protection rule for `prod` (and `dev`).
2. Enable **Require status checks to pass before merging**.
3. Select **Data Standards Gate**.

After that, a violating change cannot merge to `prod` regardless of who -- or what
-- opened the PR.

## Where this fits a fully-automated pipeline

The gate is one deterministic layer. A pipeline that removes the human from routine
review without removing oversight composes three layers, in order of trust:

1. **Deterministic gate (this workflow).** The non-negotiables -- PII, SELECT *,
   unbounded scans, naming. Fails closed. Cheap, exact, no model variance.
2. **Agent review in CI.** An agent reviews the diff for the fuzzy, judgment-heavy
   issues the playbook describes, and its verdict is wired to a required check so a
   rejection blocks the merge rather than merely commenting.
3. **CODEOWNERS as the escalation path.** The named human is no longer the default
   reviewer of every PR; they are pulled in only when a gate fails or an exception
   is requested.

The result for a change authored by an agent:

```
agent opens PR
      -> deterministic standards gate (this workflow)   [fail-closed]
      -> agent reviews the diff in CI                    [verdict = required check]
      -> pass on a low-risk model  -> auto-merge
      -> fail / high-risk / exception -> escalate to CODEOWNERS
```

`CODEOWNERS` proves the *governed* half of that picture; this gate begins to
supply the *enforced* half. The two together are what let a team relax the
default human review on low-risk paths **without** relaxing the standard -- which
is the actual bar for an autonomous data pipeline that must never ship an
unreviewed violation.

The point is not that the human disappears. It is that oversight moves from a
person watching every change to a system that fails closed, with the person as the
exception path. That is the same move a "lights-out" factory makes: the line runs
unattended not because oversight was removed, but because it was encoded into a
control system that halts on a fault.
