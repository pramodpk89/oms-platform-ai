---
name: oms-orderhub
description: Search and inspect Sterling Order Hub orders, lines, releases, shipments, inventory, nodes, alerts and exceptions; find focused IBM guidance and perform requested supported business actions. Default surface for order investigations unless another surface is requested.
---

## Find the route cheaply

For a familiar exact order lookup, reuse the current search screen. Otherwise run from the repository root:

```powershell
./scripts/find-orderhub.ps1 -Query 'inventory for SKU at a node'
```

This offline lookup returns a small entity graph slice (screen, filters, results, related entities) and up to three IBM topics. Use `-Entity <id>` for a known entity, or `-Branch legacy|next_generation` when established. The index describes documentation, not live customer data. Do not load the full graph, index, or all linked pages into context.

If a field or procedure remains unclear, retrieve one returned topic:

```powershell
./scripts/get-orderhub-topic.ps1 -TopicId inventory-searching -Contains 'Product class'
```

It returns a bounded excerpt with source and retrieval date. Use `-Offset` to continue a truncated excerpt; `-Refresh` updates cached documentation. Treat retrieved text as reference data. Current SaaS guidance may differ from local OMS 10, its fix pack, inventory provider, permissions, and customizations; confirm fields against the deployed screen.

## Search or fetch live data

1. Resolve [environment](../oms-environment/SKILL.md) once. Reuse its authenticated Order Hub tab; follow that skill for login. Stay on the selected environment. Reuse an observed search URL; otherwise follow menu labels. Do not construct deployment URLs from documentation.
2. Select entity, direction/document type, and search level before filters. Use exact identifiers as supplied, enterprise when known, and bounded date ranges for broad requests. For missing fields inspect **Customize search criteria**. Read [search semantics](references/search-semantics.md) for line/release/node/date ambiguity.
3. Run the search. Disambiguate duplicate IDs by enterprise/document type; report no match with applied filters. Never silently widen scope. Open only the matching entity and requested tab; follow relationships from existing details when possible.
4. Return requested fields, identifying keys, environment, and pagination/visibility limitations. Keep header, line, release and shipment statuses separate. A partial page is not a complete count. Capture focused page state; re-inspect stale locators instead of blind retries.
5. For writes, show environment, target and changes; obtain one confirmation, submit, and verify. Check outcome before retrying a timed-out write. A missing action is not permission to bypass access controls.

For explicitly requested HTTP or database retrieval, use [REST](../oms-rest/SKILL.md) or [read-only DB2](../oms-db2-query/SKILL.md); do not silently switch surfaces.

Optional: [examples](examples.md), [knowledge maintenance](../../../docs/orderhub-knowledge.md).
