# DB2 example prompts

Requires a configured environment, JDBC driver, and verified SELECT-only account. Replace order numbers with your own test data.

> In local DB2, count orders created today, grouped by document type.

Expected: verify fields, use a read-only aggregate, and state the database date/time interpretation. Do not guess document-type descriptions.

> In local DB2, find order 10001. Return its order number, enterprise, document type, and creation timestamp. Limit the result to 10 rows.

Expected: use parameterized values and selected columns. Report multiple matches rather than assuming order number alone is unique.

> In local DB2, inspect the catalog to confirm whether YFS_ORDER_HEADER has an OPPORTUNITY_KEY column.

Expected: read the deployed catalog. ERD documentation alone is not proof that the deployed column exists.

> Check the local DB2 connection without running application SQL.

Expected: use the helper's connection-only probe and report the connection result.

> Update the status of order 10001 directly in DB2.

Expected: decline the database write because this capability is read-only. Do not bypass the helper or switch to an administrator account.
