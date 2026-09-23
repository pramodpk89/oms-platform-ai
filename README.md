# Sterling OMS toolkit

Reusable platform skills for GitHub Copilot agent mode in VS Code: Order Hub, API Tester, REST, read-only DB2, and environment configuration. Sterling OMS 10 is the initial target; UI and API contracts vary by fix pack and customization.

## Start on Windows

1. Open this repository folder in VS Code with Copilot and your configured browser tool.
2. In a PowerShell terminal run `./scripts/init.ps1`. Supply URLs, the working DBeaver DB2 host/port, credential values, Java path, and JDBC driver path.
3. Run `./scripts/check-setup.ps1 -Connect`.
4. Use normal Copilot agent mode or select **OMS Operator**. Choose your available OpenAI or Claude model in Copilot.

Java 8+ is needed only for DB2; Python and Node.js are not required. Windows PowerShell 5.1 and PowerShell 7 are targeted. Java compilation is for maintainers only; the small helper JAR is included. The IBM driver is supplied separately from DBeaver or IBM.

Try “Check order 10001 in local Order Hub”, “Count orders created today in local DB2”, or “Invoke this documented service through local API Tester using this XML”. These are examples, not the limits of the skills.

## Extend and share

Import monthly ERD knowledge with `./scripts/update-erd.ps1 -ZipPath <file.zip> -FixPack <version>`. Search it with `./scripts/find-erd.ps1 -Query 'order'`. The `oms-data-model` skill uses this versioned reference for both agents. See [ERD maintenance](docs/erd-knowledge.md) for environment mapping and change reports. Generated vendor knowledge stays local.

Start with [building a skill](docs/building-a-skill.md) and [sample-orders-today](.github/skills/sample-orders-today/SKILL.md). **OMS Skill Builder** can help author new skills. Keep this repo open in the workspace when using its skills; they do not automatically become available in unrelated repos. Teams may install/copy the foundations through their normal shared-skill process, preserving referenced helpers.

See [setup](docs/setup.md), [acceptance checks](docs/acceptance.md), and [testing](docs/testing.md). Run `./tests/run.ps1` for the automated suite (maintainer JDK 9+ required). No live OMS data is changed by that suite.

## Design

Small skills describe workflows; shared helpers execute repeatable operations. Agents select skills without duplicating their content. Configuration and credentials are separate local JSON files. Seven skill descriptions are discoverable, but detailed instructions load only when relevant. No model is pinned, no agent framework or automatic delegation is required, and response limits reduce unnecessary context.

DB2 access requires a verified SELECT-only account. API/UI changes get one confirmation. Credentials are plaintext in `.local/credentials.json`, excluded from Git; Git-ignore is not encryption or a backup protection mechanism.

Conventions follow [VS Code skills](https://code.visualstudio.com/docs/agent-customization/agent-skills) and [custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents). JDBC packaging follows the [IBM driver distribution guidance](https://www.ibm.com/support/pages/db2-jdbc-driver-versions-and-downloads).
