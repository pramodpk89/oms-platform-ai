# Start here — project handoff

Updated 2026-09-23. Read this file first; inspect other files only as needed for the next request. Do not rebuild, retest, or redesign completed work without a relevant change or failure.

## ERD refresh addition

Monthly fix-pack ERD import is implemented in `scripts/update-erd.ps1`; lookup is `scripts/find-erd.ps1`. Both agents use the new `oms-data-model` foundation. See `docs/erd-knowledge.md`. Generated vendor metadata stays in Git-ignored `.local/erd/`, with immutable versions, a current pointer, and HTML/JSON change reports. Import your authorized ZIP in each checkout; source metadata is not bundled in the public repo.

The supplied ZIP imported 904 tables and 16,861 columns. Its exact fix-pack ID is unknown; local labels beginning `supplied-2025-12-11` are provisional. An environment's optional `erdFixPack` setting selects matching documentation. No live DB connection is needed for lookup.

Added 37 synthetic ERD regression checks; the full local suite passed (37 ERD, 31 Java, 81 PowerShell). The historical initial-build notes below remain background; inspect current PR/CI status for this addition.

## User's objective and working preferences

Build one reusable repository of IBM Sterling OMS platform skills and agents for teammates and other agents to use and extend. Target GitHub Copilot **agent mode in VS Code**, with user-selected OpenAI or Claude models. Develop on Mac; users run Windows. Sterling OMS version 10; fix pack unknown.

Token efficiency is a major requirement. The user reported this initial session consumed **9% of their weekly quota** and is moving to a lower model. This is user-reported account quota, not a measured task token count. Use compact tool output, focused reads, existing helpers, and short responses. No unnecessary agents, repeated tests, speculative frameworks, or generic prose. Listen before assuming scope. Ask only questions that materially affect the next action.

The user's examples—order status, today's order count, and cancellation—are examples, **not capability limits**. API Tester, Order Hub, and REST skills must remain general-purpose foundations.

## Repository and current state

- Remote: https://github.com/pramodpk89/oms-platform-ai.git
- Branch: main. User authorized pushing this project to that repository.
- Working copy: `/Users/pramodp/Documents/Codex/2026-09-23/hel/outputs/sterling-oms-toolkit`
- Portable archive: sibling `sterling-oms-toolkit.zip` (a snapshot; GitHub is authoritative).
- Last implementation commit before this handoff: `ba03687`; test documentation commit: `839f020`.
- Initial build is complete and pushed. No feature request beyond saving context is currently outstanding. Continue from the user's next request.

## Implemented design

Five foundations in `.github/skills/`: `oms-environment`, `oms-db2-query`, `oms-orderhub`, `oms-api-tester`, `oms-rest`. A sixth skill, `sample-orders-today`, demonstrates composing a business workflow from foundations.

Two thin, model-independent custom agents in `.github/agents/`: **OMS Operator**, **OMS Skill Builder**. No model is pinned; no provider-specific browser tool IDs are hardcoded. Copilot uses the team's existing browser tool. Skills load detail on demand; agents do not preload all skills or routinely delegate.

PowerShell scripts handle setup, configuration, DB2 invocation, and REST. A small Java 8-compatible JDBC helper is included as source and `tools/db2-client/oms-db2.jar`. Runtime users need Java for DB2, but no Python, Node.js, Maven, or compiler. Maintainers need JDK 9+ to rebuild. Windows PowerShell 5.1 and PowerShell 7 are tested.

Credentials are intentionally simple plaintext JSON, split by environment and service in Git-ignored `.local/credentials.json`. Settings are separate in `.local/environments.json`. Blank templates are committed. Local is initially enabled; dev and QA are disabled placeholders; init supports additional named environments and preserves existing values on Enter. Never print/commit credential files or move actual passwords into this handoff.

IBM's JDBC driver is NOT committed or distributed in the archive. Users provide their approved driver from DBeaver/IBM or configure its existing path. Java itself is not bundled. The local test copy of the IBM driver and credentials are available only in this working copy's ignored directories.

## Operational rules and decisions

- **Only DB2 is strictly read-only.** It requires a verified SELECT-only account. `readOnlyAccountVerified` is an administrative attestation, not a permission grant. Do not turn it on for an administrator to bypass the requirement.
- JDBC has a conservative SQL guard, prepared parameters, query/row/output limits, read-only mode, and rollback. Database grants remain the actual protection against writes/side-effecting routines.
- Default order investigations to Order Hub. Other requested workflows are supported by observing the current UI; do not guess selectors or status descriptions.
- API Tester and REST can change data in lower environments. Ask once for confirmation of the concrete environment, action, target, and meaningful payload before a write. Do not repeatedly request approval or retry an uncertain write blindly.
- API/service names, XML contracts, REST routes/auth conventions, and UI details must come from the installed deployment or user. Do not invent a `cancelOrder` API contract. Cancellation has not been implemented as a hardcoded business skill.
- REST supports Basic, bearer, custom auth headers, or none; relative paths stay within the configured base; redirects are not followed; no automatic retries or certificate bypass. HTTP success alone is not business success.
- Browser credentials may appear in tool history. Prefer an existing session, supported secret binding, or user sign-in; do not claim plaintext is invisible to the model.
- Today's count uses `{{schema}}.YFS_ORDER_HEADER`, `CREATETS >= TIMESTAMP(CURRENT DATE)` and `< TIMESTAMP(CURRENT DATE + 1 DAY)`. It counts all document types and uses DB2's calendar. Storage timezone is not confirmed; do not assert India time.
- Reports, if requested, should be normal HTML/PDF with direct links, not Canvas, per the user's delivery preference.

## Local environment facts observed

- Order Hub: https://localhost:7443/order-management/
- API Tester: https://localhost:9443/smcfs/yfshttpapi/ibmapitester.jsp
- DB2: localhost:50000 / database OMDB / schema OMDB; local Docker publishes the port.
- DB2 username originally supplied is the instance administrator; its password is in ignored local config, not this document. Browser credentials were not provided.
- Docker containers observed: `om-orderhub-base`, `om-appserver`, `om-runtime`, `om-db2server`.
- Driver copied locally from `om-db2server:/opt/ibm/db2/V11.5/java/db2jcc4.jar`.
- Live helper connection probe succeeded: DB2/LINUXX8664, version SQL110580 (11.5.8). It executed no application SQL.
- Both supplied HTTPS endpoints responded to connectivity checks. Browser automation was blocked by ERR_CERT_AUTHORITY_INVALID. No certificate trust settings were changed.
- REST base URL and authentication convention are still unknown. Browser username/password login does not establish HTTP Basic for REST.

## Verification already completed — do not repeat without reason

**102 checks:** 31 Java assertions and 71 PowerShell checks. Passed locally on Mac/PowerShell 7/Java 21; Java helper assertions also passed on Java 8. Hosted CI passed Windows PowerShell 5.1, Windows PowerShell 7, and macOS PowerShell 7 with Java 17:
https://github.com/pramodpk89/oms-platform-ai/actions/runs/35826684457

The suite checks query rejection, parameter binding, rollback, bounded output, setup preservation, environment selection/isolation, REST authentication/redaction, write confirmation gating, redirects/errors/timeouts, path handling, and skill names/links/size budgets. Fixtures use a fake JDBC driver and loopback HTTP server; no OMS writes.

Windows 5.1 uncovered a UTF-8 BOM emitted when the Java input pipe is initialized. Fixed using explicit UTF-8 bytes plus BOM handling in `OmsDb2.readInput`; regression tests cover input with and without BOM. Do not revert this compatibility fix.

A browser smoke test of a **mock** API Tester passed selecting an operation, filling XML, invoking a read, and simulated cancellation. This was not live Sterling UI validation or proof of Copilot's conversational confirmation behavior. No real order was changed.

Always-loaded instruction file: 167 words. Individual skill bodies including metadata: 135–264 words at initial verification. These are size measurements, not exact model token counts.

## Remaining integration checks

1. Windows VS Code Copilot discovery/routing/browser integration with one available OpenAI model and one Claude model.
2. Live Order Hub and API Tester after trusted certificate access and authentication are available.
3. Live sample SQL count with a verified read-only account; compare against DBeaver if needed.
4. Live REST after the user supplies the deployment base URL and auth convention.
5. Live cancellation only with a documented contract, a specific disposable order, and confirmation. Do not cancel anything merely to finish testing.

These limitations are documented; do not describe the repo as fully live-OMS validated. See `docs/acceptance.md` only when undertaking those checks.

## Useful commands and locations

For teammates: `./scripts/init.ps1`, then `./scripts/check-setup.ps1 -Connect`. Use normal Copilot agent mode or OMS Operator. `docs/building-a-skill.md` teaches extension through the working sample.

Maintainer tests: `./tests/run.ps1`. Build: `./scripts/build-db2.ps1`. Rebuild the checked-in helper JAR whenever its Java source changes. CI is `.github/workflows/test.yml`.

This Mac did not have PowerShell on PATH. A portable test runtime was downloaded from Microsoft's official PowerShell release into `/Users/pramodp/Documents/Codex/2026-09-23/hel/work/pwsh/pwsh` (7.4.13). It is outside the shared repo. GitHub CLI `gh` is installed; if log retrieval hits a cache permission error, set `XDG_CACHE_HOME=/Users/pramodp/Documents/Codex/2026-09-23/hel/work/gh-cache` for that command, not HOME.

Local credentials/driver/work artifacts must stay excluded. Use `git archive` for portable distribution. No PR was created; this was an initially empty repository, pushed directly to main as requested.
