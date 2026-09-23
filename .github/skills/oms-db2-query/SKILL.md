---
name: oms-db2-query
description: Run read-only SELECT queries against an OMS DB2 schema, including counts, joins, and investigations. Use when database access is explicitly requested; never for database updates.
---

Resolve [environment](../oms-environment/SKILL.md). Use a verified SELECT-only database account; `readOnlyAccountVerified` is an administrator's attestation, not a permission grant. SQL checks and JDBC read-only mode are additional safeguards, not a security boundary.

1. Identify the requested tables and fields from known schema or read-only catalog queries. Do not assume a table or status mapping exists.
2. Write a single SELECT or SELECT CTE to `.local/query.sql`, without a trailing semicolon. Use `{{schema}}` for the configured schema and `?` for values. Store parameters as `[ { "type": "string", "value": "10001" } ]` in `.local/params.json`. Types: string, int, long, decimal, date, timestamp, boolean, null (use `"value": null`).
3. Run `./scripts/invoke-db2.ps1 -Environment <name> -SqlFile .local/query.sql -ParametersFile .local/params.json`. Omit ParametersFile if there are no placeholders. Defaults: 50 rows, 30 seconds; maximum 1000 rows. Do not read the helper source for routine execution.
4. Return the requested result, environment, and whether it was truncated. Prefer aggregation or selected columns. Output values are strings or null; columns and rows are separate arrays.

Never use CALL, writes, sequence advancement, data-changing CTEs, or side-effecting functions. If the conservative query guard rejects valid SQL, simplify the SELECT; do not bypass it. A connection-only diagnostic is `./scripts/invoke-db2.ps1 -Environment <name> -Probe` and executes no application SQL.

For today's order count use the [working sample](../sample-orders-today/SKILL.md). For date semantics, verify how the deployment stores timestamps before interpreting “today” in a different timezone.
