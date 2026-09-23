# ERD knowledge

The complete API-docs ZIP ships as [tracked archive parts](../documentation/README.md). Setup reconstructs the ZIP and imports the ERD automatically with Windows PowerShell 5.1 or PowerShell 7. First lookup also works without running setup. No Python, browser, database, Git LFS, or extra download is needed.

The commands below are for maintainers importing a different fix pack; ordinary users only need lookup:

```powershell
./scripts/update-erd.ps1 -ZipPath 'C:\Downloads\xapidocs.zip' -FixPack 'your-fix-pack'
./scripts/find-erd.ps1 -Query 'inventory'
./scripts/find-erd.ps1 -Table YFS_ORDER_HEADER -FixPack 'your-fix-pack'
```

Use the actual fix-pack identifier supplied with the ZIP. The importer records your label; it does not infer a release from file timestamps. If the release is unknown, use a clearly provisional label such as `supplied-2025-12-11` and do not map it to a deployed environment until verified.

## Storage and refresh

Generated knowledge lives in Git-ignored `.local/erd/`; the reconstructed original archive is `.local/docs/xapidocs.zip`. The source archive parts are committed in `documentation/bundle/`. `-KnowledgeRoot <directory>` on the import/lookup commands supports an alternative local store; custom stores require explicit import.

Each immutable `versions/<fix-pack>/` snapshot contains:

- `manifest.json`: supplied version, ZIP SHA-256, importer version, time, and entity/column counts.
- `index.json`: compact table purposes and column names for discovery.
- `tables/<TABLE>.json`: descriptions, source data types, documented keys, logical targets, and source ZIP entry.
- `changes.html`, `changes.json`, and `changes.md`: browser report and comparison with the previously current snapshot, including added/removed tables and columns, changed metadata, and before/after values for changed columns.

The importer reads ZIP entries without extracting executable content. It validates entity titles, column structure, names, duplicates, and documented index columns. Known history-table pages are supported. Unrecognized entity formats fail the import rather than being silently omitted. Validation proves supported pages parsed consistently; it cannot prove IBM's ZIP contains every table in a deployment.

After validation, the importer saves a new snapshot and atomically switches `current.json`. Previous versions remain available. Invalid or empty input leaves current knowledge unchanged. Concurrent updates to a store are rejected. Reimporting the same label and ZIP is a no-op; reusing a label for different contents or a new importer is rejected. Use a new label for corrected/reprocessed packages. Reimporting an older existing version does not change the current pointer.

Review removed tables/columns and other changes before adapting business skills. For rollback in a workflow, select the retained version with `-FixPack`, or restore that version's label in the environment mapping. No snapshot deletion is required.

## Environment versions and extensions

Add `"erdFixPack": "your-fix-pack"` to the relevant environment object in `.local/environments.json`, then use:

```powershell
./scripts/find-erd.ps1 -Environment local -Table YFS_ORDER_HEADER
```

An unmapped environment, unavailable version, or conflicting explicit version fails rather than silently using different documentation. Without an environment or version argument, lookup uses the latest successfully imported snapshot. Mapping is optional and does not affect existing platform helpers.

Keep custom table/column references in `.local/erd/custom/`, separate from generated snapshots. The importer never writes there. Link the relevant custom reference from a business skill; custom definitions are not automatically merged into IBM metadata or searched by `find-erd.ps1`.

## Metadata boundaries

The supported source is the HTML entity-definition export under any `ERD/HTML/` prefix, including Sterling history pages. This is a parser for that known export format, not arbitrary HTML. Changed vendor formats require an importer update and regression fixture.

Descriptions are retained as source text. Index sections provide primary/unique keys; a description mentioning another table's primary key does not make the current column a primary key. Explicit logical-FK lists and general references are separate. No target column or cardinality is invented. Preserve source types such as `Varchar2` and verify the deployed database catalog before generating SQL. Missing metadata is not evidence of no constraint.

Run `./tests/erd.ps1` for isolated synthetic import/refresh/lookup tests, or `./tests/run.ps1` for the complete suite. Real ZIPs stay outside test fixtures.
