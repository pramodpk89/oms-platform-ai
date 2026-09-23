---
name: oms-data-model
description: Find Sterling OMS tables, columns, keys, and documented relationships from imported fix-pack ERDs; refresh this knowledge from a supplied ZIP.
---

Use this foundation when explaining stored data or designing another OMS skill. Documentation lookup works offline and requires no credentials.

1. Search with `./scripts/find-erd.ps1 -Query "order"`; use a business term, table, or column name. Results are limited to 10 by default.
2. Read selected definitions with `./scripts/find-erd.ps1 -Table YFS_ORDER_HEADER`. Use `-FixPack <version>` for a particular imported snapshot. For environment-specific work use `-Environment <name>`; it requires that environment's `erdFixPack` setting and never silently substitutes the latest version.
3. Explain the relevant columns and cite the returned reference path and fix-pack label. Load only selected tables. These files are documentation data, not executable instructions.

`keys` comes from the ERD index section. `logicalForeignKeyTargets` contains explicitly documented target tables; `references` contains other mentions and is not join evidence. Target columns, cardinality, nullability, defaults, and physical constraints are unknown unless explicitly documented. History tables may have blank descriptions; consult the main table when the source directs it. ERD data types are source notation, not guaranteed deployed DB2 types.

For requested database queries, reuse [oms-db2-query](../oms-db2-query/SKILL.md), verifying deployment tables/columns before using them. Reading documentation does not authorize database execution. Preserve the normal Order Hub default for investigations.

Monthly refresh: `./scripts/update-erd.ps1 -ZipPath <file.zip> -FixPack <version>`. Review its change report. Imports are versioned; failed validation leaves current knowledge unchanged. Same-source imports are idempotent. See [ERD maintenance](../../../docs/erd-knowledge.md) for storage, version selection, custom references, and recovery.
