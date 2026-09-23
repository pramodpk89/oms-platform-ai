# REST example prompts

Requires a configured REST base URL and authentication. Supply an actual deployment-documented endpoint or request descriptor; the repository does not assume a universal Sterling REST route.

> Review the REST request descriptor I attach. Check its method, relative path, payload, and read/write effect. Do not execute it.

Expected: inspect the contract and descriptor without sending a request. See [descriptor format](references/request-format.md).

> Send the attached documented read-only REST request to local. Return selected result fields and any application error.

Expected: use the configured environment and existing REST helper; bound the output and distinguish HTTP success from business success.

> Prepare a REST request for the documented operation I provide, using test order 10001. Do not send it yet.

Expected: prepare the descriptor and payload from the supplied contract. Do not guess the route or authentication convention.

> Execute the attached write request against local after showing me its target and changes for confirmation.

Expected: one confirmation tied to the concrete operation, then execution and outcome verification.

> The request returned HTTP 400. Explain the returned error without retrying.

Expected: report HTTP and application errors; do not automatically retry or expose credentials.
