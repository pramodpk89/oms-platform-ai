# ERD example prompts

Paste these into Copilot with this repository open. No database connection is needed. First use prepares the bundled ERD automatically; later queries use the local index and table files.

## Find tables

> Which tables store order headers and order lines? Explain the documented relationship.

> Find tables related to inventory reservations and summarize what each stores.

> Which tables contain ORDER_HEADER_KEY? Show at most 10 matches.

Expected: search the index, read relevant definitions, and cite the documentation version and source. Do not infer join columns or cardinality from names alone.

## Explain fields and keys

> Explain ORDER_NO, DOCUMENT_TYPE, and ENTERPRISE_KEY in YFS_ORDER_HEADER. Keep the answer short.

> What are the documented primary and unique keys of YFS_ORDER_HEADER?

> Is OPPORTUNITY_KEY a primary key of YFS_ORDER_HEADER? Check the ERD.

Expected for the bundled documentation: ORDER_HEADER_KEY is the primary key; ENTERPRISE_KEY, ORDER_NO, and DOCUMENT_TYPE form a documented unique key. OPPORTUNITY_KEY is a logical reference to YFS_OPPORTUNITY, not the order header's primary key.

## History and version checks

> Which table archives records purged from YFS_ORDER_HEADER?

Expected: YFS_ORDER_HEADER_H. A reference to an archive table does not guarantee that its own definition is present in this ZIP.

> Which ERD version are you using? Is its exact IBM fix-pack identifier known?

Expected: report the active import label. The bundled label is provisional; do not present its date as a verified fix-pack number.

> Use local's configured ERD version to explain YFS_ORDER_LINE.

Expected: use the environment's erdFixPack mapping. If missing, identify the missing setting instead of silently using another version.

## Failure case

> Explain YFS_NOT_A_REAL_TABLE from the ERD.

Expected: report that the table is not documented in the selected version. Do not invent columns or query a database to answer a documentation-only request.
