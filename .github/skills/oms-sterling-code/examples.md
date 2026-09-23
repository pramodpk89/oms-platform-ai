# Sterling coding skill: practical examples

Use these prompts in Copilot with this toolkit open. For implementation, also open the target Sterling Java project and identify its folder. Replace `com.acme.oms` and example business values with your project's actual package and configuration.

The expected outputs below describe acceptance criteria, not code already generated or tested. Knowledge questions and specification drafting need no OMS connection. Implementation needs the target SDK/API contracts and existing helpers.

## 1. Understand the extension points

**Prompt**

> Use oms-sterling-code to explain a user exit, an event handler, and a custom API. Give a practical use case for each, explain who calls it and what it returns, and show how I would choose between them.

**Expected output:** A concise explanation grounded in the [UE](references/ue.md), [event](references/event.md), and [custom API](references/customapi.md) conventions. Distinguish an SDK-defined hook from a configured event method or custom service method. Treat registration details as deployment-specific.

## 2. Turn a business requirement into a specification

**Prompt**

> Use oms-sterling-code to draft a custom API specification for customer order history. The caller provides an enterprise and customer identifier, with an optional date range. Return matching orders and their shipment summary. Include validation, pagination, error behavior, and questions we must resolve before coding. Do not implement yet.

**Expected output:** A filled [custom API template](assets/specs/customapi-template.yaml), plus unresolved contracts such as the actual customer identifier, supported filters, shipment lookup, and output shape. Do not treat the [source example](assets/specs/examples/customapi-get-customer-order-history.yaml) as proof of available APIs.

## 3. Implement a user exit from a specification

**Prompt**

> Use oms-sterling-code in the target Java project to implement the UE specification below. Inspect the SDK interface and existing XML helpers first. Add tests and run the project build if dependencies are available. Report any missing contracts before producing executable code.

```yaml
type: UE
interface: YFSBeforeCreateOrderUE
class_name: DefaultBillToFromShipToUEImpl
package: com.acme.oms.ue
what: Default a missing billing address from the shipping address
logic: |
  1. Preserve an existing PersonInfoBillTo unchanged.
  2. If PersonInfoBillTo is absent and PersonInfoShipTo exists,
     copy the agreed address fields into a new PersonInfoBillTo.
  3. If both are absent, leave the input unchanged.
  4. Return the input document with any defaults applied.
notes: |
  Confirm the allowed address fields and element placement from
  the target API contract. Do not copy identifiers or unrelated fields.
```

**Expected output:** Implementation in the target source tree, corresponding tests, and registration notes. Verify the actual interface signatures; do not generate a String overload merely because a source example has one. Tests cover preserving BillTo, copying approved fields, both addresses absent, and avoiding unintended changes to ShipTo.

## 4. Implement a backorder event handler

**Prompt**

> Use oms-sterling-code with the backorder event example. Our requirement is to prepare cancellation input for eligible BOPIS and DFS lines. The configured downstream service invokes changeOrder; the Java handler must only return the document. Confirm the event input and cancellation contract in our project, then implement the handler and tests. Define the no-match behavior from the service contract.

**Expected output:** An event implementation based on the [event convention](references/event.md) and [backorder spec](assets/specs/examples/event-cancel-backorder-lines.yaml), using verified business values and XML. Tests cover eligible lines, mixed eligible/ineligible lines, no matches, and missing required identifiers. Verify that the handler itself does not invoke cancellation and that its no-match output matches the downstream service's expectations.

## 5. Implement a custom API from an approved spec

**Prompt**

> Use oms-sterling-code to implement our approved customer-history YAML specification in the target Java project. Locate our configured business-method name, YIFCustomApi interface, API wrappers, and output templates. Reuse those helpers. Add tests for valid results, no matches, invalid required input, and downstream API failure. Include pagination behavior from the approved spec.

**Expected output:** A custom API class and tests using the target interface and helpers, plus required configuration changes or notes. Verify setProperties and the configured business method separately. Do not assume invoke is an interface override or invent a shipment API. If the approved spec or contracts are missing, identify them and prepare a draft rather than claiming a tested implementation.

## 6. Review existing Sterling code

**Prompt**

> Use oms-sterling-code to review the selected UE class and its tests. Check the actual SDK signature, XML traversal, helper usage, constants, exception behavior, logging, and API calls. Give actionable findings with file and line references. Do not change code yet.

**Expected output:** Findings tied to observed code and contracts, with consequences and suggested fixes. Check descendant versus direct-child traversal, error-code preservation, sensitive XML logging, and whether tests isolate API calls. Treat the source conventions as guidance rather than universal SDK rules.

## 7. Add meaningful tests

**Prompt**

> Use oms-sterling-code to add tests for the selected event handler using our existing test stack. Create real XML input documents, mock the environment and API boundary, and cover success, invalid input, empty lines, and mixed line types. Run the tests and report the results.

**Expected output:** Behavior tests following the [test conventions](references/junit-tests.md), adapted to the target test stack. Assert output content and relevant API interactions, not just non-null results. No test contacts live OMS. If dependencies prevent execution, state which checks remain unrun.

## 8. Handle missing SDK or helper definitions

**Prompt**

> Use oms-sterling-code to draft a before-create UE from my requirement. I have not supplied our Sterling SDK or utility classes yet. Tell me what you need to complete the implementation.

**Expected output:** A clearly marked draft specification and a focused list of missing items: target interface signature, applicable XML contract, package/helper definitions, and build setup. No invented utility imports, compilation claims, or requests for live credentials.

## 9. Catch a mismatched execution trigger

**Prompt**

> Use the source remorse-hold example to cancel an order if its hold is still active after 30 minutes. Can we implement this using the before-create UE named in the example?

**Expected output:** Explain that a before-create hook does not establish a later timed execution. Confirm the scheduled/event trigger, persisted order identity, hold configuration, timestamp handling, and cancellation contract before implementation. Consult the [portability notes](references/portability.md); do not silently implement the source example as a working timer.

## Scope boundary

The attribute-resolution framework and OOTB attribute catalogue remain excluded. None of these examples adds a resolver, deploys code, or authorizes a live API operation. For separately requested execution, use the existing platform skills and their normal confirmation rules.

## Manual acceptance

Try the definition prompt, one implementation prompt with a configured target project, and one missing-contract prompt in Copilot. Check that the skill loads relevant references, respects the requested output, handles missing contracts, and reports actual test results. Repository packaging checks do not establish Copilot routing or Sterling runtime compatibility.
