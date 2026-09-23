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
