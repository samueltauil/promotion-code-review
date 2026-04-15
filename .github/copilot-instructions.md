This repository contains BigQuery SQL and Dataform (.sqlx) files for a data pipeline.

When reviewing pull requests, focus on:

1. **Data quality risks**: Missing NULL checks, unbounded date ranges, implicit type conversions
2. **BigQuery anti-patterns**: SELECT *, missing partition filters, cross-joins on large tables
3. **Window function correctness**: Verify PARTITION BY and ORDER BY clauses match the intended logic
4. **Breaking changes**: Schema changes that could affect downstream views or dashboards
5. **Dataform config**: Ensure `config {}` blocks have correct type, schema, and assertions
6. **Date filter consistency**: All queries should use consistent date boundaries (check `includes/constants.js`)
