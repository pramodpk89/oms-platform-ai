---
name: oms-environment
description: Configure or select an OMS environment and resolve service URLs and credential locations. Use before OMS browser, REST, or DB2 work, or when changing environment settings.
---

Run from the repository root. On Windows, use the VS Code PowerShell terminal; on Mac use `pwsh`.

For sample prompts and expected results, see [examples](examples.md) when requested.

1. Run `./scripts/get-environment.ps1 -Environment <name>`. Omit the name only to resolve the configured default, then retain the returned name for all steps.
2. If unconfigured, have the user run `./scripts/init.ps1 -Environment <name>` interactively. For initial templates only use `-NonInteractive`. Setup supports additional environment names; dev and QA start disabled.
3. Runtime settings and credentials live in `.local/`; examples in `config/` contain no secrets. Endpoint changes go in `environments.json`; secrets are under `<environment>.<service>` in `credentials.json` (`db2`, `orderhub`, `apiTester`, `rest`). Do not dump credential files into chat. REST and DB2 helpers read only the selected service internally.
4. Reuse existing browser login. If login is required, use the browser tool's supported secret-file binding when available; otherwise ask the user to sign in. Do not claim tool calls hide plaintext passwords.

Check setup with `./scripts/check-setup.ps1 -Environment <name> -Connect`. This checks dependencies and DB2 TCP reachability, not query permissions or browser login. For configuration details only, read [setup](../../../docs/setup.md).
