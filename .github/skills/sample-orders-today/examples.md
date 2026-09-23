# Today's order count example prompts

Requires the DB2 foundation and a verified SELECT-only account. This sample uses the existing [query](queries/orders-today.sql).

> How many orders were created today in local DB2?

Expected: return ORDER_COUNT, DB_DATE, and the environment. The sample includes all document types and uses DB2's current date.

> Count today's orders in dev DB2, and explain what “today” means in that result.

Expected: resolve dev explicitly. Explain the database calendar and the assumption about CREATETS; do not silently use local if dev is disabled.

> Count today's sales orders in local DB2 only. Verify the document-type value before adding the filter.

Expected: adapt the read-only query using a supported document-type mapping; do not present the unfiltered sample as sales orders only.

> Count orders created today in India time, using local DB2.

Expected: establish how the deployment stores timestamps before defining explicit date boundaries. Do not assume DB2 CURRENT DATE represents India time.
