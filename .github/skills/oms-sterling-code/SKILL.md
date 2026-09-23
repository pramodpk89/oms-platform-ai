---
name: oms-sterling-code
description: Explain, implement, or review Sterling OMS Java user exits, event handlers, and custom APIs using coding conventions, YAML specifications, and unit-test patterns.
---

Use for Sterling customization code and coding definitions. Documentation-only work needs no credentials or environment connection. For sample requests and expected outcomes, see [examples](examples.md).

1. Identify the target Java project, requirement, Sterling version/SDK, and available build/test setup. This toolkit supplies knowledge, not a Sterling application or SDK. Read [portability notes](references/portability.md); project interfaces, helpers, and configuration take precedence over examples.
2. Select only the relevant convention and specification:
   - **User exit (UE):** [conventions](references/ue.md), [template](assets/specs/ue-template.yaml), [example](assets/specs/examples/ue-cancel-remorse-hold.yaml).
   - **Event handler:** [conventions](references/event.md), [template](assets/specs/event-template.yaml), [example](assets/specs/examples/event-cancel-backorder-lines.yaml).
   - **Custom API:** [conventions](references/customapi.md), [template](assets/specs/customapi-template.yaml), [example](assets/specs/examples/customapi-get-customer-order-history.yaml).
3. Translate the requirement into inputs, output, logic, error behavior, and registration needs. Resolve missing contracts before executable implementation; label unresolved examples as drafts. Templates and worked examples describe intent, not validated API contracts.
4. Inspect target utilities before applying the [utility reference](references/utility-classes.md). Reuse existing wrappers, XML helpers, and constants. For explicitly requested extension changes, consult [extension conventions](references/extensions-db.md) and the existing [data-model skill](../oms-data-model/SKILL.md). No attribute-resolution framework is included.
5. Generate or review code with the [test conventions](references/junit-tests.md): meaningful success, invalid-input, and boundary cases; isolate API/service calls. Run the target project's build/tests when available and report what actually ran.

Locate API/Javadoc contracts through the [bundled documentation](../../../documentation/README.md) or the supplied target SDK. If required definitions are absent, ask for those specific inputs; never invent a tool or signature. Do not add source-project utility implementations or IBM binaries to this toolkit.

Return changed files or the explanation requested, relevant references, test results, and unresolved deployment assumptions. Code authoring does not deploy changes or invoke live APIs; use existing platform skills for separately requested execution.
