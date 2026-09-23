# Setup

Run `./scripts/init.ps1` in a Windows PowerShell terminal. On Mac, install PowerShell 7 and run `pwsh -File scripts/init.ps1`; Java and JDBC logic are portable. Runtime users do not need a JDK, Python, Node.js, Maven, or a DB2 native client. Maintainers need JDK 9+ to rebuild/test the helper.

Setup prompts do not echo passwords. Files are plaintext and local; protect them using normal workstation access controls. Setup preserves existing values on Enter and creates missing templates without overwriting files. Edit the JSON to deliberately clear a value. Do not attach `.local/` to chat or commit it.

## Environments and services

`environments.json`: defaultEnvironment, javaPath, driverPath, and named environments. Each has enabled, orderHubUrl, apiTesterUrl, rest.baseUrl/auth, and db2.host/port/database/schema/readOnlyAccountVerified. Java and driver paths may be absolute; relative driver paths resolve from the repo. Do not embed credentials in URLs. DB2 hosts currently support DNS/IPv4, not IPv6 literals or extra JDBC URL options.

`credentials.json`: environment → username/password. The same login is used by DB2, Order Hub, API Tester, and REST Basic authentication. REST also supports an environment-level token and custom headers. This keeps local/dev/QA credentials independent. `./scripts/init.ps1 -Environment dev` configures dev; custom names work too. Disabled/missing environments fail without falling back to local. Switch the default in environments.json or always pass `-Environment` explicitly.

Use the actual host/port from DBeaver, including any tunnel it uses. A JAR does not expose a Docker port. In a normal published-port local Docker setup the host is localhost and the port is 50000.

## Java and driver

Use an existing Java runtime and set its executable path if not on PATH. Copy an approved `db2jcc4.jar` from the driver's Files tab in DBeaver, or from your DB2 installation, into `dependencies/`; alternatively point driverPath to its existing path. Verify compatibility with your DB2 server and Java version. Setup does not download arbitrary drivers or bundle a JRE.

The helper has no library dependency except the IBM JDBC driver. The IBM JAR is excluded from Git and distribution until your organization approves redistribution. The helper source and `scripts/build-db2.ps1` are included; that script builds for Java 8 bytecode. See [IBM driver information](https://www.ibm.com/support/pages/db2-jdbc-driver-versions-and-downloads).

## Read-only DB2

Ask the DBA for an account whose effective permissions are limited to required SELECT access. It must not have DBADM/SYSADM, inherited write grants, or execution rights on side-effecting routines. The supplied instance administrator is not an appropriate read-only account. Mark readOnlyAccountVerified true only after those permissions are verified.

The helper rejects writes, multiple statements, common sequence operations and data-changing CTEs; sets JDBC read-only mode; and rolls back its transaction. These are safeguards, not a substitute for database grants. It uses no commit and will not provision accounts or change permissions. `-Probe` can check connection metadata without executing application SQL, even before read-only verification.

## Browser and TLS

The team supplies its existing Copilot browser tool. Skills use that tool's current DOM/labels rather than fixed provider names. Keep certificates trusted using your team's normal local setup. An agent must not silently disable certificate checks. Browser passwords may appear in tool history if entered by an agent; signing in yourself or a supported secret binding avoids printing the credential file to the model.

REST authentication and base URL must come from your deployment. Username/password browser login does not prove REST uses HTTP Basic. The helper supports Basic, bearer, custom auth headers, and unauthenticated test services, but no automatic SSO or token refresh.
