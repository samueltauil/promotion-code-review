#!/usr/bin/env python3
"""
Deterministic data-pipeline standards gate.

This promotes the review heuristics in docs/copilot-playbook.md (SELECT * usage,
missing date/partition filters, PII exposure) from advisory reviewer prompts into
fail-closed checks. A repository-wide instructions file is a suggestion the model
(or a hurried human) may follow; a required status check is enforced by the system.

The distinction matters when the author of a change is an automated agent: an
instruction the agent ignores produces no signal, but a deterministic gate refuses
the merge every time, with no human attention required.

Exit code 0  -> all standards satisfied.
Exit code 1  -> at least one violation. When this workflow is marked as a required
                status check under branch protection, a non-zero exit blocks the
                merge (fail-closed), and a code owner is the escalation path rather
                than the default reviewer.

Scope is intentionally narrow and deterministic. It does not judge business logic
or correctness -- that is where an agent reviewer and a human still add value. It
enforces only the non-negotiable, mechanically-checkable standards that must never
regress, even on an unattended merge.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Standards configuration (edit here to match the mandated data standards).
# ---------------------------------------------------------------------------

# Business-level marts are consumed by dashboards and downstream teams. They must
# not surface raw identifiers -- personally identifiable information belongs in
# upstream layers with tighter access, not in a broadly-read analytics mart.
PII_COLUMNS = {
    "first_name",
    "last_name",
    "date_of_birth",
    "dob",
    "ssn",
    "mrn",
    "email",
    "phone_number",
    "street_address",
}

# Directories that produce materialized/business output and therefore carry the
# strictest standards.
MART_DIR = "definitions/marts"
STAGING_DIR = "definitions/staging"

# A transformation that reads a dated source must bound the scan. Unbounded date
# ranges are both a cost problem (full-table scans) and a correctness problem.
DATE_FILTER_HINTS = ("encounter_date", "admission_date", "discharge_date", "event_date", "_date")


def read_sql_body(text: str) -> str:
    """Return the SQL portion of a .sqlx file, excluding the leading config block."""
    # Dataform config blocks are `config { ... }` at the top. Strip the first
    # balanced block so column checks do not match words inside the config.
    idx = text.find("config")
    if idx == -1:
        return text
    brace = text.find("{", idx)
    if brace == -1:
        return text
    depth = 0
    for i in range(brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[i + 1 :]
    return text


def declared_type(text: str) -> str:
    m = re.search(r'type\s*:\s*"([a-zA-Z_]+)"', text)
    return m.group(1) if m else ""


def check_file(path: Path, repo_root: Path) -> list[str]:
    rel = path.relative_to(repo_root).as_posix()
    text = path.read_text(encoding="utf-8")
    body = read_sql_body(text)
    body_lower = body.lower()
    violations: list[str] = []

    dtype = declared_type(text)
    is_mart = rel.startswith(MART_DIR)
    is_staging = rel.startswith(STAGING_DIR)

    # Source declarations are pass-through references, not transformations.
    if dtype == "declaration":
        return violations

    # R1 -- No SELECT * in mart or staging models (schema-drift / blast-radius).
    if is_mart or is_staging:
        if re.search(r"select\s+\*", body_lower):
            violations.append(
                f"{rel}: SELECT * is not permitted in mart/staging models. "
                "Enumerate columns explicitly so schema changes are reviewed, not silent."
            )

    # R2 -- Dated transformations must bound the scan with a date filter.
    if (is_mart or is_staging) and dtype in {"table", "view", "incremental"}:
        reads_dated_source = any(h in body_lower for h in DATE_FILTER_HINTS)
        has_date_filter = bool(
            re.search(r"where[\s\S]*?(_date|date_of|admission_date|discharge_date)", body_lower)
        )
        if reads_dated_source and not has_date_filter:
            violations.append(
                f"{rel}: transformation reads a dated source but has no date filter in a WHERE clause. "
                "Unbounded ranges cause full scans and non-deterministic output."
            )

    # R3 -- Marts must not surface raw PII columns.
    if is_mart:
        for col in sorted(PII_COLUMNS):
            # Match the column as a selected identifier, not as a substring.
            if re.search(rf"(^|[\s,\.]){re.escape(col)}(\s|,|$)", body_lower):
                violations.append(
                    f"{rel}: mart surfaces a restricted PII column '{col}'. "
                    "Aggregate or hash identifiers upstream; marts are broadly read."
                )

    # R4 -- Every model must declare a config block with a schema.
    if dtype in {"table", "view", "incremental"}:
        if not re.search(r'schema\s*:\s*"[^"]+"', text):
            violations.append(
                f"{rel}: model is missing a 'schema' in its config block (naming standard)."
            )

    return violations


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    definitions = repo_root / "definitions"
    if not definitions.exists():
        print("No definitions/ directory found; nothing to check.")
        return 0

    files = sorted(definitions.rglob("*.sqlx"))
    all_violations: list[str] = []
    for f in files:
        all_violations.extend(check_file(f, repo_root))

    print(f"Data standards gate: scanned {len(files)} model file(s).")
    if all_violations:
        print("\nFAIL -- mandated data standards violated:\n")
        for v in all_violations:
            print(f"  x {v}")
        print(
            "\nThis gate is fail-closed. When set as a required status check under "
            "branch protection, these violations block the merge with no human "
            "required. Fix the model, or route to a code owner for an exception."
        )
        return 1

    print("PASS -- all mandated data standards satisfied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
