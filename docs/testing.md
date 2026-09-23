# Testing

Run `./tests/run.ps1` with a maintainer JDK 9+ and PowerShell. The suite uses temporary local fixtures, a fake JDBC driver, and a loopback HTTP server. It does not need OMS, IBM binaries, credentials, Copilot, Python, or Node.js.

Coverage includes SQL guardrails, JDBC parameter binding and rollback, bounded results, environment isolation, setup idempotency, REST authentication/redaction, confirmation gating, redirect handling, error statuses, and skill names/links/size budgets. The GitHub workflow targets macOS PowerShell 7 plus Windows PowerShell 7 and 5.1; a configured workflow is not evidence it has run.

ERD regression tests (`./tests/erd.ps1`, also included in the full suite) generate synthetic ZIPs. They cover extraction, primary/unique keys, logical relationships versus mentions, monthly deltas, idempotency, immutable snapshots, failed-import preservation, bounded lookup, environment version selection, and preservation of custom references.

Build with `./scripts/build-db2.ps1`. Runtime helper JAR is included. Changes to Java source must rebuild that JAR and rerun tests before sharing.

For live checks see [acceptance](acceptance.md). API names, schemas and UI controls are installation-specific and must be observed or supplied. Keep raw responses and actual credentials in `.local/`, not fixtures.

## Local verification — 2026-09-23

Bundled-documentation addition: built the Java helper and passed 43 ERD/bundle checks, 31 Java assertions, and 87 PowerShell checks before committing. The full suite now runs normal setup against the tracked real archive parts in a fresh temporary configuration directory. A separate fresh copy (excluding `.git` and `.local`) successfully ran `find-erd.ps1 -Table YFS_ORDER_HEADER` without setup, reconstructed the checksum-verified API ZIP, and imported 904 tables/16,861 columns. No network, existing knowledge cache, or external ZIP was used by that fresh-copy check.

ERD refresh addition: 37 synthetic ERD checks, 31 Java assertions, and 81 PowerShell checks passed locally. The supplied ZIP imported 904 entity definitions with 16,861 columns; the `YFS_ORDER_HEADER` primary key and `OPPORTUNITY_KEY` logical relationship were checked against the source. The source's exact fix-pack identifier is unknown. Hosted Windows verification for this addition is tracked by its PR checks.

- Mac, PowerShell 7.4.13, Java 21: 31 Java assertions and 71 PowerShell checks passed (102 total).
- Java helper checks also passed under the locally installed Java 8 runtime.
- Live DB2 connection probe passed: DB2 11.5.8 (`SQL110580`); no application SQL executed.
- Both supplied OMS HTTPS endpoints responded to a connectivity check. The browser rejected their untrusted certificate; authenticated Order Hub and API Tester workflows remain untested.
- A loopback mock API Tester passed browser selection, XML entry, invocation, result reading, and simulated cancellation. This does not validate Sterling UI controls, XML contracts, or Copilot confirmation behavior.
- No live order was changed. Live SQL counts require a verified read-only account; REST needs a deployment endpoint/auth configuration.
- Hosted CI passed the suite on Windows PowerShell 5.1, Windows PowerShell 7, and macOS PowerShell 7 with Java 17: [verified run](https://github.com/pramodpk89/oms-platform-ai/actions/runs/35826684457). Windows testing caught a UTF-8 preamble in the Java input stream; the fix has a regression test.
- VS Code Copilot/OpenAI/Claude acceptance runs remain pending; helper execution on Windows is verified, model routing and browser integration are not.

Context budget: the shared Copilot instruction file is 167 words; individual skills are 135–264 words. Runtime output is bounded. These are measured size limits, not an exact token-usage guarantee.
