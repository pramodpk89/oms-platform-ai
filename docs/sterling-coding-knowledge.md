# Sterling coding knowledge

The [oms-sterling-code skill](../.github/skills/oms-sterling-code/SKILL.md) adds the team's coding definitions and conventions to this platform toolkit. Use normal Copilot agent mode for Sterling Java implementation, review, or explanation. Keep the toolkit and target Java project available in the workspace; this repo does not become a deployable Sterling application.

## Imported knowledge

Adapted from [`.sterling-ai` at source commit `dded930439c8`](https://github.com/oms-forge/sterling-codebase/tree/dded930439c8973add8cbbef3918428cc867b654/.sterling-ai):

- User-exit, event-handler, and custom-API definitions and conventions.
- Shared utility method reference and JUnit/Mockito testing patterns.
- Database-extension authoring conventions, without the attribute-resolution workflow.
- Three YAML spec templates and three worked requirement examples.

The [source manifest](sterling-coding-source.json) maps each of the 12 source files to its destination and records the original SHA-256. The skill, portability notes, and usage examples are new integration material.

## Deliberately excluded

`attribute-resolution.md` and its companion `ootb-attributes.md` catalogue are not imported. No attribute-resolution framework, MCP schema resolver, or replacement catalogue is added. The existing ERD/data-model capability is unchanged. Source application Java code, helper implementations, Maven build, dependencies, configuration, and source Copilot instructions are not imported.

## Adaptations

References load only when relevant. Original `.sterling-ai` paths become local skill links; the unavailable source schema tool is replaced by the existing data-model reference. Extension authoring retains naming/types/index conventions but omits the worked attribute-resolution decision sequence and catalogue links.

Production XML/API examples consistently use source helpers when available. Portability notes explain SDK signature verification, source package placeholders, helper availability, exception-contract inconsistencies, logging, and trigger limitations. The custom-API interface import is reconciled with the source Java implementation. YAML business examples retain their source intent and are explicitly unverified contracts, with known issues described in portability notes. No example is claimed to have compiled or run against Sterling.

## Use and maintain

Try “Explain a Sterling UE versus an event handler” or “Use the event spec template to implement this requirement in my Java project.” No setup or credentials are required for knowledge lookup. Implementation requires the target codebase and its SDK/contracts; live execution uses the existing platform skills separately.

To refresh, compare the pinned source files with the new revision, review semantic changes and the exclusions, adapt affected references/templates, then update the manifest's commit and source hashes. Do not blindly copy the entire source folder. Run `./tests/run.ps1` for repository checks and the [manual skill examples](../.github/skills/oms-sterling-code/examples.md) in Copilot. Sterling compilation/runtime validation belongs in a configured target application.

## Migration validation

On 2026-09-23, the local full suite passed 43 ERD checks, 31 Java checks, and 113 PowerShell checks. Skill validation, all new Markdown links, skill/instruction size budgets, six YAML parses, 12 source-file hash mappings, and exclusion checks passed. Copilot routing, target-application compilation, and live Sterling execution were not tested.
