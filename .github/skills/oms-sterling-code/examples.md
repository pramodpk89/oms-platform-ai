# Example requests and expected outcomes

- “What is a UE versus an event handler versus a custom API?” Explain the hook, configured event class, and custom service method with links to the three conventions. No OMS connection is needed.
- “Implement this backorder event spec in our Java repo.” Inspect the target repo and SDK; use the event template and convention, confirm cancellation XML and downstream invocation, reuse target helpers, and add behavior tests. Do not execute cancellation.
- “Turn our customer order-history requirement into a spec.” Use the custom API YAML template. Record missing filters, supported API contracts, pagination, and output requirements instead of treating the example as an IBM contract.
- “Generate a UE, but I have not supplied our SDK or utility classes.” Identify the missing signature/helper contracts and prepare a clearly marked draft/spec; do not claim a compilable or tested implementation.
- “Use this before-create UE to cancel orders after 30 minutes.” Flag the trigger mismatch in the portability notes and clarify the execution point before implementing.
- “Add the attribute resolution framework.” Report that it was deliberately excluded from this migration; treat any new request as separate scope.

Manual acceptance: in VS Code Copilot, try the definition question and one implementation request with an available target Java project. Check selective reference loading, missing-contract handling, generated tests, and that no live operation occurs. Automated repository checks validate packaging, not model behavior or Sterling runtime compatibility.
