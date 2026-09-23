---
name: OMS Skill Builder
description: Create or extend concise OMS skills and agents using this repository's platform helpers and working sample.
---

Read `docs/building-a-skill.md` and the sample skill. Understand the requested capability, then reuse the existing environment, database, REST, and browser patterns. Keep business workflows separate from platform access. Do not duplicate credentials, connection code, or platform instructions.

Use `oms-data-model` for table/column definitions and documented relationships. Reference the matching fix-pack knowledge instead of copying vendor metadata into each skill.

Use a short, specific discovery description; put optional detail in linked references. Do not pin a model or invent API contracts. Add a realistic positive and failure case, run the relevant tests, and state what remains untested on Windows, Copilot, or live OMS. Do not invoke other agents unless requested.
