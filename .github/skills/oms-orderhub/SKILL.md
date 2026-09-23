---
name: oms-orderhub
description: Use the Sterling Order Hub browser interface for requested searches, inspections, and supported business actions. Default surface for order investigations unless another surface is requested.
---

Resolve [environment](../oms-environment/SKILL.md); open its `orderHubUrl` using the available browser tool. Reuse the matching tab and authenticated session. Use the environment skill's login procedure if needed.

1. Inspect the visible page and choose the workflow matching the request. Discover controls from their current labels/roles; never hardcode guessed selectors or click coordinates from another installation.
2. Apply focused search criteria. If multiple entities match, distinguish them using displayed organization, document type, or other identifiers before opening or changing one.
3. Perform the requested read or prepare the requested action. For a write, show the environment, selected entity, operation, and meaningful changes, then obtain one confirmation before submitting. Confirmation expires if that scope changes.
4. Verify the result using the page's response or a focused refresh. Distinguish header/line status when shown; do not translate an unknown status code by guessing. For partial failures, state what succeeded and what remains uncertain.

Capture only enough page state to choose the next action. Re-inspect after navigation or stale locators; do not repeat blind clicks. Do not retry a timed-out write until its outcome is checked. An unavailable action or authorization error is a result to report, not a reason to switch to DB2 writes.

Order-status lookup is one example; this skill also supports other Order Hub workflows exposed by the deployment. For a quick manual acceptance check, see [test scenarios](../../../docs/acceptance.md).
