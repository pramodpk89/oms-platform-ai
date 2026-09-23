# Order Hub knowledge retrieval

The skill uses a small local graph and a deduplicated IBM topic index. No vector database, embedding service, API key, Python, or Node runtime is required. Existing PowerShell 5.1/7 is sufficient. These helpers retrieve documentation; live business data still comes from the configured Order Hub browser or an explicitly requested REST/DB2 skill.

## Use

```powershell
./scripts/find-orderhub.ps1 -Query 'show inventory for SKU at a node'
./scripts/find-orderhub.ps1 -Query 'purchase order receipts' -Branch legacy
./scripts/find-orderhub.ps1 -Entity exception
./scripts/get-orderhub-topic.ps1 -TopicId orders-searching-outbound -Contains 'Shipping node'
```

`find-orderhub` is offline and deterministic. It matches normalized business phrases against 14 curated entities, returns one workflow plus at most two alternative entity IDs, and ranks titles/source links for up to three distinct pages (maximum five). Singular/plural normalization and exact phrase weighting aid retrieval; this is not semantic reasoning. The agent should use intent to select among alternatives, especially direction and multi-entity requests. Unknown queries can return no workflow/topics without inventing an answer. The query is never used to populate live UI fields.

The graph connects entities to screens, filters, requested output fields, caveats, related entities and source topics. It contains navigation knowledge, not customer records or executable API contracts. `-Entity` retrieves a related entity without loading the entire graph. Other documented workflows remain searchable through topic titles.

`topics.json` contains unique IBM source paths with route aliases, branch, parent topic IDs and breadcrumbs. It covers **Using Order Hub** and **Using next-generation Order Hub**, including nested pages. It does not claim to cover separate customization, installation or other IBM product branches. Container-only headings have no article and are omitted. Shared content is deduplicated by source path; `?pos=` is a navigation alias. Branch selection filters routes, not capabilities of the deployed OMS version. With `any`, returned route labels show which branch was selected; legacy-only and next-generation-only topics can both appear.

`get-orderhub-topic` fetches only a known indexed IBM page, caches its text in ignored `.local/orderhub-docs`, and emits up to 3,500 article characters by default. Aliases share a cache entry. `-Contains` selects a literal matching passage, `-Offset` pages through it, and `-Refresh` explicitly refreshes the cache. A miss returns `containsMatched: false`; it does not assert the feature is unsupported. Follow `nextOffset` without `-Contains`. Output contains source URL, retrieval time and truncation indicators. Plain text loses table layout and is not suitable for reconstructing contracts; open the source page for complex tables/code.

## Context budget

Only the short skill is loaded initially. Routine familiar searches bypass the helpers. For unfamiliar tasks, load one graph slice and a few titles, then at most the needed passage. The complete index and cached articles stay on disk. Bounded outputs and avoiding repeated navigation reduce context use; no model-specific token savings percentage is claimed. Live results should likewise contain requested fields and identifiers, not full UI dumps.

## Maintenance

```powershell
./scripts/update-orderhub-index.ps1
# Or from a previously downloaded full IBM TOC JSON:
./scripts/update-orderhub-index.ps1 -TocFile path/to/order-management-toc.json
./tests/orderhub.ps1
```

The updater uses IBM's public documentation delivery endpoint and records the source/time. Review generated changes before committing. This endpoint is used by IBM Docs but is not a promised public API; if it changes, use the source browser URLs and update the helper. Never change existing index data after a failed refresh. Review `graph.json` and `search-semantics.md` against the referenced IBM topics after a documentation update; they are deliberately curated, not generated from titles. The graph was reviewed on 2026-09-23. The built-in graph uses next-generation topic IDs; shared pages resolve to legacy aliases when that branch is selected.

Tests cover ranking, graph/source integrity, deduplication, branch isolation, misses and bounded/cache retrieval using local fixtures. They do not authenticate to OMS. Complete live acceptance with the examples in the skill against your deployed version; current SaaS documentation does not certify local OMS 10 compatibility.
