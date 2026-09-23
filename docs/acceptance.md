# Live acceptance

Use a configured lower environment. Record the environment, tool/model, observed result, and failure if any. Never report a mock as a live OMS pass.

1. **Order Hub:** ask for an order status. Confirm the matching order/enterprise, read the displayed header/line status, and compare the final answer. Also test another available read workflow so the skill is not limited to status.
2. **DB2:** use a verified read-only account to run the sample count. Compare with the same query in DBeaver, using the same DB date and schema. Attempt a write only against a disposable test DB or fake driver to verify rejection; do not try writes against live OMS.
3. **API Tester read:** provide an installed documented API/service and input XML. Verify the chosen mode, input, template, and response. Check one invalid-input response without changing data.
4. **API Tester change:** choose a disposable order, verify the installed cancellation contract, prepare exact XML, then confirm the specific environment/order before submission. Verify the resulting order state. If authorization or contract is unavailable, mark this test pending.
5. **REST:** use a verified endpoint/auth configuration. Compare the returned data with its expected result. Exercise error/redirect/timeout behavior on the local mock server. Run live changes only with specific confirmation.
6. **Copilot:** run the above in VS Code agent mode on Windows with an available OpenAI model and a Claude model. Confirm skills/agents are discovered, paths with spaces work, and browser tools are available. Plain-language prompts should load relevant skills without reading all references.

The automated suite does not prove model routing, browser tool compatibility, live XML contracts, or Windows behavior when only run on Mac. A terminal-only mock cannot establish that a model asks for confirmation; that remains a Copilot acceptance check.
