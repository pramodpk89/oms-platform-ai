# Order Hub example prompts

Requires a configured Order Hub URL, a browser tool, and an authenticated session. Replace sample order numbers with your test data.

> In local Order Hub, find order 10001 and summarize its header and line statuses.

Expected: search through the browser, identify the correct order, and report displayed statuses. Disambiguate matching orders when necessary.

> In local Order Hub, show the shipment information displayed for order 10001.

Expected: use the available UI and report what is visible. Do not silently substitute DB2 or REST.

> In local Order Hub, check whether order 10001 can be cancelled. Do not submit a cancellation.

Expected: inspect available actions and explain what the UI permits without changing the order.

> Cancel test order 10001 in local Order Hub.

Expected: identify the target, explain the action, obtain one confirmation, then submit and verify. Use only disposable test data for this example.

> Find order ORDER-DOES-NOT-EXIST in local Order Hub.

Expected: report no match after a focused search; do not invent a status.

> Find inventory for SKU ABC-123 at node STORE-1 in local Order Hub. Show availability and UOM.

Expected: use the inventory graph slice, select the enterprise and item/node scope, then return only displayed availability/UOM with identifiers. Do not confuse supply with availability or treat a dash as zero.

> Find purchase order receipts for PO-100 in local Order Hub.

Expected: use Orders > Inbound with the appropriate document type and receipt scope. Do not use the outbound sales-order search.

> Show line statuses and assigned nodes for order 10001.

Expected: distinguish line-level nodes/statuses from release-level assignments. Use the existing order details and relevant line/release view; report both explicitly if needed.

> Find the latest integration exceptions for service TEST_SERVICE from yesterday.

Expected: use Exceptions, service and an explicit Exception date range. Sorting only the loaded records does not establish the latest records globally. Do not reprocess anything.

> How does Order Hub search by shipping node?

Expected: retrieve a focused documentation excerpt and explain order/line/release search-level semantics with its IBM source. No OMS login is needed for this documentation question.
