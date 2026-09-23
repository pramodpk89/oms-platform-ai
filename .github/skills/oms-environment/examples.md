# Environment example prompts

Run from a checkout of this repository. Use the environment names configured by your team.

> Show the configured URLs and DB2 host, database, and schema for local. Do not show credentials.

Expected: resolve local and return selected settings, without reading passwords into the response.

> Check whether local has Java, the DB2 driver, and the helper installed. Also check DB2 TCP reachability.

Expected: run the setup checks. A reachable port is not proof of successful authentication or SELECT permissions.

> Help me configure a new environment called training.

Expected: use the existing interactive setup flow; secrets are entered locally and existing values can be preserved.

> Resolve the qa environment. If it is disabled, tell me what needs configuring.

Expected: report the disabled/unconfigured environment. Do not silently use local instead.
