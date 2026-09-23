# Build a skill

Use `sample-orders-today` as a working example. It contains one short SKILL.md and one SQL file, reusing the DB2 foundation for everything else.

For data-model knowledge, use `oms-data-model` and its fix-pack-specific references. Do not embed a copy of the full ERD or duplicate table definitions in new skills. See [ERD maintenance](erd-knowledge.md).

For Sterling Java customization knowledge, reuse [oms-sterling-code](../.github/skills/oms-sterling-code/SKILL.md). Its references and spec templates describe UEs, events, custom APIs, utilities, and tests; target SDK contracts take precedence. See [migration scope](sterling-coding-knowledge.md).

1. Define the capability and one realistic user request. Decide whether it is platform access or a business workflow using existing access skills.
2. Create `.github/skills/<lowercase-hyphen-name>/SKILL.md`. Include YAML `name` matching the folder and a specific `description` explaining when it applies. Avoid descriptions like “all OMS tasks”.
3. Explain required inputs, the action, expected output, and material failure cases. Link the foundations instead of copying connection/authentication logic. Keep optional contracts/examples in linked references, loaded only when needed.
4. Add a script only for repeatable execution. Put request bodies, SQL, or templates beside the skill; credentials remain in `.local/`.
5. Test a successful request, missing inputs, wrong environment, and relevant failure. Changes need the existing confirmation pattern; DB2 stays read-only.
6. Run `./tests/run.ps1`, then try a natural-language prompt in Copilot. Check the chosen skill, selected environment, final answer, and unnecessary tool calls. Repeat with an available OpenAI and Claude model; model selection stays with the user.

Minimal frontmatter:

```yaml
---
name: your-workflow
description: Explain the specific capability and when a user needs it.
---
```

Aim for a skill under 450 words, not a large manual. The test suite enforces that budget and a small always-loaded instruction file. Word counts are a proxy, not an exact token measurement. Avoid scripts that regenerate themselves or read their own source on every invocation. Return counts and selected fields; provide large artifacts only when requested.

Agents define a useful role and route to skills. Create `.github/agents/<name>.agent.md` only when a distinct role helps the team. Use `name` and `description`; omit model to respect the user's model choice, and avoid hardcoded browser tool IDs shared installations may not have.

Do not duplicate this entire repo into each skill or silently substitute REST for a requested browser workflow. New workflows should add their own contracts and examples without narrowing the foundational skills.
