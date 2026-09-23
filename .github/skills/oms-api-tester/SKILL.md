---
name: oms-api-tester
description: Invoke Sterling OMS APIs or configured services through the browser API Tester using input XML and optional output templates. Supports read and write operations, not just order cancellation.
---

Resolve [environment](../oms-environment/SKILL.md); open its `apiTesterUrl`. Reuse the authenticated session or follow the environment login procedure.

For sample prompts and expected results, see [examples](examples.md) when requested.

The [bundled API documentation](../../../documentation/README.md) is available in `.local/docs/xapidocs.zip` after setup (or `scripts/prepare-docs.ps1 -ArchiveOnly`). Consult relevant API contracts there, checking deployment version/customizations before use.

1. Determine the API or service, input, and expected effect from the user's request and the installed API documentation or an approved example. If unknown, inspect the available choices/docs or ask for the contract. Do not invent an API name, XML attribute, cancellation mechanism, or service behavior.
2. Inspect the current tester UI. Select the correct API/service mode and name. Fill the input XML; set a narrow output template when supported. Clear stale inputs and templates that belong to a previous invocation. Keep authentication and request fields distinct.
3. Validate XML and required identifiers. A “get” name alone is not proof that a custom service is read-only. For changes, confirm the environment, operation, target, and relevant payload once, immediately before invoking.
4. Invoke once. Read both the HTTP/page outcome and OMS errors. A successful HTTP status or a nonempty response does not establish business success. Verify the affected entity after a write when the response does not establish its final state.
5. Return a compact result and relevant error code/message. Do not paste entire XML responses or credentials. A timeout has unknown outcome; check before retrying.

The first cancellation example must be derived from the installed contract and a specific test order. Do not ship a guessed `cancelOrder` contract. Use the [acceptance scenarios](../../../docs/acceptance.md) for broader tests.
