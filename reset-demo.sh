#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Demo Reset Script — Restores the promotion-code-review repo to demo-ready state
# =============================================================================
# Run this after a demo to reset all PRs, branches, and protections.
# Usage: ./reset-demo.sh
# =============================================================================

REPO="samueltauil/promotion-code-review"
export GH_PAGER=""

# Commit SHAs (pinned at demo setup time)
SHA_BASE="9a59e3dee9198bad5ea3b9601f3d3861dbeb216d"       # Initial commit (dev/prod base)
SHA_MAIN="de64597d6a604a941eb9711d3abb0c2a34cb5b0b"       # main tip (includes docs + reset script)
SHA_FEATURE_A="97a789a3298b293f2014abf7df8a0c7445bd2f7b"  # feature/add-readmission-metric
SHA_FEATURE_B="e2746a88cb5502511b70d7533199fce6dd43f403"  # feature/update-encounter-logic
SHA_HOTFIX="776061b281d9826cf8a48eb153505cd776a110d5"      # hotfix/fix-encounter-date-filter

echo "================================================"
echo "  Resetting demo repo: $REPO"
echo "================================================"
echo ""

# ---- Step 1: Close all open PRs ----
echo "Step 1/6: Closing all open PRs..."
OPEN_PRS=$(gh pr list --repo "$REPO" --state open --json number --jq '.[].number' 2>/dev/null || true)
if [ -n "$OPEN_PRS" ]; then
  for pr in $OPEN_PRS; do
    echo "  Closing PR #$pr..."
    gh pr close "$pr" --repo "$REPO" --delete-branch=false 2>/dev/null || true
  done
else
  echo "  No open PRs to close."
fi
echo ""

# ---- Step 2: Remove branch protections (so we can force-push) ----
echo "Step 2/6: Temporarily removing branch protections..."
gh api "repos/$REPO/branches/dev/protection" -X DELETE --silent 2>/dev/null || true
gh api "repos/$REPO/branches/prod/protection" -X DELETE --silent 2>/dev/null || true
echo "  Protections removed."
echo ""

# ---- Step 3: Reset all branches to their original commits ----
echo "Step 3/6: Resetting branches to original state..."

git fetch origin --prune

# Reset main
git checkout main
git reset --hard "$SHA_MAIN"
git push origin main --force

# Reset dev
git checkout dev 2>/dev/null || git checkout -b dev "$SHA_BASE"
git reset --hard "$SHA_BASE"
git push origin dev --force

# Reset prod
git checkout prod 2>/dev/null || git checkout -b prod "$SHA_BASE"
git reset --hard "$SHA_BASE"
git push origin prod --force

# Reset feature/add-readmission-metric
git checkout feature/add-readmission-metric 2>/dev/null || git checkout -b feature/add-readmission-metric "$SHA_FEATURE_A"
git reset --hard "$SHA_FEATURE_A"
git push origin feature/add-readmission-metric --force

# Reset feature/update-encounter-logic
git checkout feature/update-encounter-logic 2>/dev/null || git checkout -b feature/update-encounter-logic "$SHA_FEATURE_B"
git reset --hard "$SHA_FEATURE_B"
git push origin feature/update-encounter-logic --force

# Reset hotfix/fix-encounter-date-filter
git checkout hotfix/fix-encounter-date-filter 2>/dev/null || git checkout -b hotfix/fix-encounter-date-filter "$SHA_HOTFIX"
git reset --hard "$SHA_HOTFIX"
git push origin hotfix/fix-encounter-date-filter --force

git checkout main
echo "  All branches reset."
echo ""

# ---- Step 4: Re-apply branch protections ----
echo "Step 4/6: Re-applying branch protections..."

gh api "repos/$REPO/branches/dev/protection" -X PUT --silent --input - <<'DEVPROT'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["SQL Lint (sqlfluff)", "Dataform Compile Check"]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "enforce_admins": false,
  "restrictions": null,
  "required_conversation_resolution": true
}
DEVPROT
echo "  dev protection set."

gh api "repos/$REPO/branches/prod/protection" -X PUT --silent --input - <<'PRODPROT'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["SQL Lint (sqlfluff)", "Dataform Compile Check", "Promotion Policy Check"]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "enforce_admins": false,
  "restrictions": null,
  "required_conversation_resolution": true
}
PRODPROT
echo "  prod protection set."
echo ""

# ---- Step 5: Recreate PRs ----
echo "Step 5/6: Recreating pull requests..."

# PR: feature/add-readmission-metric → dev (good template example)
git checkout feature/add-readmission-metric
PR1_URL=$(gh pr create --repo "$REPO" --base dev \
  --title "feat: Add 30-day readmission rate metric" \
  --label "feature" --label "dataform" \
  --body '## Summary

Adds a 30-day readmission rate calculation to the daily encounters mart using a LAG window function. This identifies patients who return within 30 days of a previous encounter, enabling readmission tracking on operational dashboards.

## Change Type

- [x] New feature / data model
- [ ] Bug fix / hotfix
- [ ] Refactor (no behavior change)
- [ ] Configuration change
- [ ] Documentation update

## Testing Evidence

- [x] SQL compiles successfully (`dataform compile`)
- [x] Tested against development dataset
- [x] Verified row counts / output shape
- [ ] N/A (documentation or config only)

Tested with a sample of 10,000 encounters. Readmission rate across all facilities is approximately 8.3%, consistent with industry benchmarks.

## Risk Assessment

- **Impact**: Medium — adds new columns to an existing mart
- **Affected tables/views**: `mart_daily_encounters` (downstream dashboards may need updating)
- **Breaking change?**: No — additive columns only

## Rollback Plan

Revert this PR to remove the readmission columns. No schema migration required since columns are additive.

## Validation Steps for Reviewer

1. Check the LAG window function partitions correctly by `patient_id`
2. Verify the 30-day threshold is appropriate (vs. 7-day or 90-day)
3. Confirm `SAFE_DIVIDE` handles zero-encounter edge cases

## Labels

Feature change — adds new metric columns.')
echo "  PR created: $PR1_URL"

# Extract PR number for adding review comment
PR1_NUM=$(echo "$PR1_URL" | grep -oP '\d+$')

# PR: feature/update-encounter-logic → dev (Draft, bad template)
git checkout feature/update-encounter-logic
PR2_URL=$(gh pr create --repo "$REPO" --base dev \
  --title "feat: Filter scheduled-only encounters, add emergency count" \
  --draft \
  --label "dataform" \
  --body '## Summary

<!-- Developer did not fill this out properly — demonstrates a "bad" PR description -->

Updated the encounter logic.

## Change Type

- [x] New feature / data model

## Testing Evidence

- [ ] SQL compiles successfully (`dataform compile`)
- [ ] Tested against development dataset
- [ ] Verified row counts / output shape
- [ ] N/A (documentation or config only)

## Risk Assessment

- **Impact**: 
- **Affected tables/views**: 
- **Breaking change?**: 

## Rollback Plan

## Validation Steps for Reviewer

1. 
2. 
3. 
')
echo "  PR created (Draft): $PR2_URL"

# PR: hotfix → dev (integration)
git checkout hotfix/fix-encounter-date-filter
PR3_URL=$(gh pr create --repo "$REPO" --base dev \
  --title "fix: Tighten encounter date filter (hotfix → dev integration)" \
  --label "hotfix" \
  --body '## Summary

**HOTFIX** — Fixes a data quality bug in the staging encounter view. Encounters with NULL dates or future-dated entries (from data entry errors) were passing through to downstream marts, causing inflated counts and inaccurate reporting.

### Changes
- Added `NOT NULL` check on `encounter_date`
- Added upper bound filter: `encounter_date <= CURRENT_DATE()`
- Extended status exclusion to include `entered_in_error` alongside `cancelled`

This PR integrates the hotfix into `dev` for testing. A separate PR will promote to `prod` after validation.

## Change Type

- [ ] New feature / data model
- [x] Bug fix / hotfix
- [ ] Refactor (no behavior change)
- [ ] Configuration change
- [ ] Documentation update

## Testing Evidence

- [x] SQL compiles successfully (`dataform compile`)
- [x] Tested against development dataset
- [x] Verified row counts / output shape
- [ ] N/A (documentation or config only)

Before fix: 142,387 encounters in staging (includes 23 NULL-dated, 4 future-dated)
After fix: 142,360 encounters — 27 invalid records correctly excluded.

## Risk Assessment

- **Impact**: Low — tightens an existing filter, removes bad data
- **Affected tables/views**: `stg_patient_encounters` → all downstream marts
- **Breaking change?**: No — only removes invalid records that should not have been included

## Rollback Plan

Revert this PR to restore the original WHERE clause. Invalid records will reappear but no data loss occurs.

## Validation Steps for Reviewer

1. Confirm `encounter_date IS NOT NULL` filter is correct
2. Verify `CURRENT_DATE()` upper bound is appropriate (vs. a fixed date)
3. Check that `entered_in_error` is a valid status in the source system

## Labels

Hotfix — production data quality issue.')
echo "  PR created: $PR3_URL"

# PR: hotfix → prod (production fix)
PR4_URL=$(gh pr create --repo "$REPO" --base prod \
  --title "fix: Tighten encounter date filter (hotfix → prod)" \
  --label "hotfix" \
  --body '## Summary

**HOTFIX → PROD** — Production deployment of the encounter date filter fix. See the companion dev integration PR for full details and testing.

Fixes a data quality bug where NULL and future-dated encounters were included in staging, causing downstream reporting inaccuracies.

## Change Type

- [x] Bug fix / hotfix

## Testing Evidence

- [x] SQL compiles successfully (`dataform compile`)
- [x] Tested against development dataset
- [x] Verified row counts / output shape

Validated in dev integration PR: 27 invalid records correctly excluded with no impact on valid data.

## Risk Assessment

- **Impact**: Low
- **Affected tables/views**: `stg_patient_encounters` → all downstream marts
- **Breaking change?**: No

## Rollback Plan

Revert this commit on `prod`. Original WHERE clause will restore previous behavior.

## Validation Steps for Reviewer

1. Confirm this is identical to the change validated in the dev integration PR
2. Verify no unrelated changes are included
3. Approve as CODEOWNER for production deployment
')
echo "  PR created: $PR4_URL"
echo ""

# ---- Step 6: Add review comment on PR #1 ----
echo "Step 6/6: Adding review comment on PR #$PR1_NUM..."
gh api "repos/$REPO/pulls/$PR1_NUM/reviews" -X POST --silent --input - <<REVIEW
{
  "body": "Overall looks good! A couple of questions:\n\n1. **30-day threshold** — Is 30 days the right window? Some teams use 7-day for acute and 90-day for chronic. Should we make this configurable via \`includes/constants.js\`?\n2. **Performance** — The LAG window function will scan all historical encounters. For large datasets, consider adding a partition by \`facility_code\` or limiting the lookback window.\n3. **SAFE_DIVIDE** — Good use of SAFE_DIVIDE to handle zero-encounter edge cases. 👍\n\nApprove once the threshold question is resolved.",
  "event": "COMMENT"
}
REVIEW
echo "  Review comment added."

git checkout main
echo ""
echo "================================================"
echo "  ✅ Demo reset complete!"
echo "  Repo: https://github.com/$REPO"
echo "================================================"
echo ""
echo "Open PRs:"
gh pr list --repo "$REPO" --state open
