# Testing

Run `./tests/run.ps1` with a maintainer JDK 9+ and PowerShell. The suite uses temporary local fixtures, a fake JDBC driver, and a loopback HTTP server. It does not need OMS, IBM binaries, credentials, Copilot, Python, or Node.js.

Coverage includes SQL guardrails, JDBC parameter binding and rollback, bounded results, environment isolation, setup idempotency, REST authentication/redaction, confirmation gating, redirect handling, error statuses, and skill names/links/size budgets. The GitHub workflow targets macOS PowerShell 7 plus Windows PowerShell 7 and 5.1; a configured workflow is not evidence it has run.

Build with `./scripts/build-db2.ps1`. Runtime helper JAR is included. Changes to Java source must rebuild that JAR and rerun tests before sharing.

For live checks see [acceptance](acceptance.md). API names, schemas and UI controls are installation-specific and must be observed or supplied. Keep raw responses and actual credentials in `.local/`, not fixtures.

## Local verification — 2026-09-23

- Mac, PowerShell 7.4.13, Java 21: 29 Java assertions and 71 PowerShell checks passed (100 total).
- Java helper checks also passed under the locally installed Java 8 runtime.
- Live DB2 connection probe passed: DB2 11.5.8 (`SQL110580`); no application SQL executed.
- Both supplied OMS HTTPS endpoints responded to a connectivity check. The browser rejected their untrusted certificate; authenticated Order Hub and API Tester workflows remain untested.
- A loopback mock API Tester passed browser selection, XML entry, invocation, result reading, and simulated cancellation. This does not validate Sterling UI controls, XML contracts, or Copilot confirmation behavior.
- No live order was changed. Live SQL counts require a verified read-only account; REST needs a deployment endpoint/auth configuration.
- Windows and VS Code Copilot/OpenAI/Claude acceptance runs remain pending. The CI workflow is provided but has not been run on a hosted runner.

Context budget: the shared Copilot instruction file is 167 words; individual skills are 135–264 words. Runtime output is bounded. These are measured size limits, not an exact token-usage guarantee.
