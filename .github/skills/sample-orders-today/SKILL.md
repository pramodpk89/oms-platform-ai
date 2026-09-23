---
name: sample-orders-today
description: Count orders created today in DB2 using the configured OMS schema. Also serves as the working example for teammates building a business skill from platform foundations.
---

Use [DB2 query](../oms-db2-query/SKILL.md), which resolves the environment and enforces the connection pattern.

For sample prompts and expected results, see [examples](examples.md) when requested.

Run `./scripts/invoke-db2.ps1 -Environment <name> -SqlFile .github/skills/sample-orders-today/queries/orders-today.sql`.

Return `ORDER_COUNT`, `DB_DATE`, and the environment. “Today” here is DB2 CURRENT DATE and assumes CREATETS uses that calendar. If the user requests a different timezone, resolve the timestamp convention and use explicit start/end parameters instead.

This counts all rows in YFS_ORDER_HEADER created today, including all document types. Add a documented document-type filter only when the user asks for sales orders or another specific type. Explain that scope if it matters.

For new skills follow the [authoring guide](../../../docs/building-a-skill.md). Do not copy DB2 connection code into this skill.
