---
name: oms-orderhub
description: Use the Sterling Order Hub browser interface for requested searches, inspections, and supported business actions. Default surface for order investigations unless another surface is requested.
---

Resolve [environment](../oms-environment/SKILL.md); open its `orderHubUrl` using the available browser tool. Reuse the matching tab and authenticated session. Use the environment skill's login procedure if needed.

For sample prompts and expected results, see [examples](examples.md) when requested.

For direct order lookups, use the shortest path:

1. Open the local Order Hub login page and authenticate with the selected environment credentials. If the local deployment uses a self-signed certificate, accept the browser exception or use the project’s insecure browser workflow rather than guessing at credentials.
2. Go straight to the order search page when available, such as `https://localhost:7443/order-management/order-search/order/search` or the equivalent Orders -> Search workflow. Do not wander through generic home pages if the search screen is already exposed.
3. Enter the exact order number in the Order Number or equivalent field, then run the search. Do not type partial values, fuzzy text, or alternate IDs unless the UI requires them.
4. If multiple orders match, distinguish the target using the displayed order number, shipment, organization, or document type before opening it. If the search returns nothing, report the exact empty result instead of inventing a status.
5. Open the matching result and read the order header and summary details. Confirm status, order date, and other visible summary values directly from the page.
6. For a write, show the environment, selected entity, operation, and meaningful changes, then obtain one confirmation before submitting. Confirmation expires if that scope changes.
7. Verify the result using the page’s response or a focused refresh. Distinguish header/line status when shown; do not translate an unknown status code by guessing. For partial failures, state what succeeded and what remains uncertain.

Capture only enough page state to choose the next action. Re-inspect after navigation or stale locators; do not repeat blind clicks. Do not retry a timed-out write until its outcome is checked. An unavailable action or authorization error is a result to report, not a reason to switch to DB2 writes.

Order-status lookup is one example; this skill also supports other Order Hub workflows exposed by the deployment. For a quick manual acceptance check, see [test scenarios](../../../docs/acceptance.md).
