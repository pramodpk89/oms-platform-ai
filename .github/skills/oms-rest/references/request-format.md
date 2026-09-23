# REST request format

Example shape only; replace the endpoint with one verified for your installation:

```json
{
  "method": "POST",
  "path": "verified-relative-endpoint",
  "effect": "read",
  "headers": { "Accept": "application/xml" },
  "contentType": "application/xml",
  "bodyFile": "input.xml"
}
```

Omit bodyFile/contentType for a bodyless request. Path may include URL-encoded query parameters; never place credentials in it. Payload paths resolve relative to the descriptor. Valid methods: GET, HEAD, OPTIONS, POST, PUT, PATCH, DELETE. PUT/PATCH/DELETE require write effect. POST classification requires the actual API contract. `-ConfirmedWrite` records the agent's prior user confirmation; it cannot verify a conversation by itself.

Settings: `rest.baseUrl`, `rest.auth` (`basic`, `bearer`, `headers`, `none`). Credentials: username/password, token, or a headers object for deployment-specific authentication. Never guess Sterling auth header names. Custom authentication requires deployment documentation; the helper does not implement SSO/token refresh.

Request headers allowed: Accept, If-Match, If-None-Match, Idempotency-Key, X-Correlation-ID. Authentication headers live in the credential file. Do not invent an idempotency key strategy when the API does not support one.

TLS uses the machine trust configuration. Redirects are not followed. There is no automatic retry or TLS verification bypass. Response body previews may include business data; select only what is needed. Common secret values are redacted, but this is not a general PII scrubber.
