---
name: oms-rest
description: Call configured Sterling OMS REST endpoints with documented methods, parameters, headers, and XML or JSON payloads, and interpret responses. Use for direct HTTP requests rather than browser API Tester workflows.
---

Resolve [environment](../oms-environment/SKILL.md). Obtain the endpoint and authentication convention from this deployment's documentation or user input; do not derive them from Order Hub's port or URL.

1. Create a request descriptor in `.local/request.json` using [request format](references/request-format.md). Paths are relative to the configured REST base. Store payloads beside the descriptor. Keep credentials in the environment's credential entry, not the descriptor or shell arguments.
2. Declare `effect` from the operation's semantics. POST may be a read API; a custom service may write regardless of its name. If the effect is unknown, resolve it before sending.
3. For a write, show the environment, operation, target, and relevant changes; obtain one confirmation. Run `./scripts/invoke-rest.ps1 -Environment <name> -RequestFile .local/request.json`, adding `-ConfirmedWrite` only after that confirmation.
4. Interpret HTTP status and application errors separately. Redirects are returned rather than followed with credentials. Authentication or certificate failures need configuration fixes, not repeated requests. Never automatically retry a write after timeout.
5. Return the requested fields or concise result. Default response budget is 4000 characters. If omitted as too large, narrow the API's output template/filter first. Read helper code only to debug it.
