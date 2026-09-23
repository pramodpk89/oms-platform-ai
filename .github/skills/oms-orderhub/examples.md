# Order Hub example prompts

Copy a prompt into agent chat and replace the sample environment, enterprise, IDs and dates with your own. Live lookups require a configured Order Hub URL, a browser tool and an authenticated session. Documentation questions and offline knowledge searches do not require an OMS connection.

For compact answers, specify the fields and maximum results you want. The agent should reuse the current session and search context, retrieve only relevant guidance, and report applied filters and any result limits. These are expected behaviors, not results from a live test.

## Orders, lines and releases

> In local Order Hub, find order 10001 and summarize its header and line statuses.

Expected: search through the browser, identify the correct order, and report displayed statuses. Disambiguate matching orders when necessary.

> In local Order Hub, find sales orders created today for enterprise ENT-1. Show at most 10 order numbers, statuses and creation dates.

Expected: select outbound sales orders and the requested enterprise, use the creation-date field if available, and establish the applicable timezone/date range. Return at most 10 rows and state whether more matches exist; do not substitute order date for creation date.

> In local Order Hub, show line statuses and line shipping nodes for order 10001 in enterprise ENT-1.

Expected: inspect line-level fields using the order's existing details or an Order line search. Keep header status separate and do not substitute release-level shipping nodes.

> In local Order Hub, show releases for order 10001. Return release number, release status and assigned ship node only.

Expected: follow the order's Releases tab or use Order release search. Fetch only requested fields and identify any partial result set.

> In local Order Hub, find purchase order receipts for PO-100 in enterprise ENT-1.

Expected: use Orders > Inbound with Purchase order and the receipt scope, or follow the identified purchase order's Receipts tab. Treat PO-100 as the requested purchase order identifier, not a sales order's customer PO reference.

> In local Order Hub, find return RMA-100 and show its status and displayed payment information.

Expected: use Orders > Returns and open only the matching return and requested tab. Return status alone does not establish that a refund was paid.

> In local Order Hub, find work order WO-100 and show its status and service details.

Expected: use Orders > Work orders, verify the identifier and enterprise, and report displayed work-order fields.

## Related details and shipments

> In local Order Hub, show the shipment information displayed for order 10001. Return shipment number, status, carrier and tracking number where available.

Expected: reuse the matching order's Shipments tab and open shipment/container details only as needed. Report unavailable tracking explicitly; do not infer it from order status or silently substitute DB2/REST.

> In local Order Hub, find inbound shipment SHIP-IN-100 and show its status and receipt information if available.

Expected: select inbound shipment search, verify the matching shipment, and inspect relevant details. Do not use the outbound shipment workflow.

> For order 10001 in local Order Hub, show payment status and any active holds. Do not change anything.

Expected: identify the order once, then inspect its payment and hold tabs. Keep payment state, holds and fulfillment status distinct; do not remove holds or edit payments.

## Inventory and nodes

> Find inventory for SKU ABC-123 at node STORE-1 in local Order Hub. Show availability and UOM.

Expected: use the inventory graph slice, select the enterprise and item/node scope, then return only displayed availability/UOM with identifiers. Do not confuse supply with availability or treat a dash as zero.

> In local Order Hub, show supply audit history for SKU ABC-123 at STORE-1 from September 1 through September 7, 2026. Return at most 10 records.

Expected: use Inventory > Audit with supply audit, item/node scope and the stated date range. Establish timezone and inclusive date boundaries, preserve relevant UOM/product-class/segment scope, and report pagination limits. Do not substitute current inventory availability.

> In local Order Hub, show ship capacity and pickup capacity for node STORE-1, including the capacity unit of measure.

Expected: find the node and inspect its capacity/metrics. Preserve units versus releases; report a dash or unavailable capacity as displayed, not as zero. Do not change capacity.

## Alerts and exceptions

> In local Order Hub, show alerts assigned to me in my subscribed queues. Return at most 10 alert IDs, statuses, priorities and related order numbers.

Expected: use the supported queue/user alert filters and current authenticated identity. If queue subscription or access prevents the search, report that limitation. Do not assign or close alerts.

> Find the latest integration exceptions for service TEST_SERVICE from yesterday.

Expected: use Exceptions, service and an explicit Exception date range. Sorting only the loaded records does not establish the latest records globally. Do not reprocess anything.

## Documentation and compact knowledge retrieval

> How does Order Hub search by shipping node?

Expected: retrieve a focused documentation excerpt and explain order/line/release search-level semantics with its IBM source. No OMS login is needed for this documentation question.

> Find the IBM legacy Order Hub guidance for inventory availability. Give me the best topic link and relevant filters.

Expected: search the local index with the legacy branch, return a focused workflow/topic, and fetch one excerpt only if needed. The branch identifies documentation, not proof that every feature exists in the deployed version.

> What is the difference between supply, demand and availability for an inventory search? Cite the relevant IBM guidance and keep it brief.

Expected: retrieve only the relevant topic or passage, preserve inventory-provider differences, and cite the source. Do not retrieve live inventory or load the full documentation collection.

For direct helper use, run from the repository root in PowerShell:

```powershell
# Offline routing: one workflow and up to three topics.
./scripts/find-orderhub.ps1 -Query 'inventory for SKU at a node'

# Exact entity and branch; one topic.
./scripts/find-orderhub.ps1 -Entity inventory -Branch legacy -Limit 1

# One cached/fetched IBM excerpt, capped at 1,200 article characters.
./scripts/get-orderhub-topic.ps1 -TopicId orders-searching-outbound -Contains 'Shipping node' -MaxChars 1200
```

Expected: the first two commands return documentation guidance, not customer records. The last returns a source URL, retrieval timestamp, excerpt and truncation indicators. If `containsMatched` is false, do not claim the passage was found. To continue, pass the returned `nextOffset` as `-Offset` without `-Contains`; use `-Refresh` when fresh documentation is required.

## Empty results, ambiguity and actions

> Find order ORDER-DOES-NOT-EXIST in local Order Hub.

Expected: report no match and the exact filters used; do not invent a status or silently broaden the search.

> Find transfer order TRANSFER-100 in local Order Hub.

Expected: resolve inbound versus outbound direction from the request or existing context. If unresolved, ask for direction; disambiguate enterprise/document type before reporting a result.

> In local Order Hub, check whether order 10001 can be cancelled. Do not submit a cancellation.

Expected: inspect available actions and explain what the UI permits without changing the order. A hidden action does not establish its underlying cause.

> Cancel test order 10001 in local Order Hub.

Expected: identify the target, explain environment and action, obtain one confirmation, then submit and verify. Use disposable test data. A timeout requires checking the outcome before any retry.
