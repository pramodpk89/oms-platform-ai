# Applying the source conventions

These references capture the team's Sterling coding knowledge from `oms-forge/sterling-codebase`; they are not IBM SDK specifications. See [migration provenance](../../../../docs/sterling-coding-knowledge.md) for the pinned source and exclusions.

## Target contracts come first

- `com.mycompany` is the source package. `SterlingUtil`, `XMLUtil`, and `Constants` are application helpers, not IBM APIs and not included in this toolkit. Inspect their actual methods, argument order, constants, and behavior in the target project before generating imports or calls. If absent, use the target's equivalent or request the required implementation.
- Confirm UE interfaces, supported overloads, return values, and checked exceptions against the target SDK. A String overload returning `null` is a source example, not a default implementation for every UE.
- The source convention names `com.yantra.yif.japi.YIFCustomApi`, but its actual `src/main/java/com/mycompany/api/CustomAPIImpl.java` imports `com.yantra.interop.japi.YIFCustomApi` and implements `setProperties`. The migrated reference uses that observed import; confirm the target SDK. `invoke` is the chosen business-method name, not evidence that the interface declares it.
- Confirm event/service method signatures, whether output is consumed by another API, and registration in the target configuration. Building `changeOrder` input is distinct from executing `changeOrder`.
- Preserve documented error codes and causes using supported exception constructors/setters. The source's UE exception examples and JUnit expectations differ; match tests to the actual interface and agreed error contract.

## XML, logging, and helper behavior

Use existing XML helpers in production when available. Standard DOM is appropriate for standalone test fixtures. Check direct-child versus descendant behavior before traversing nested orders, lines, and extensions; `getElementsByTagName` searches descendants. Do not assume that every `Extn` maps to a separate hang-off table.

Use target logging conventions, balanced timers (including failure paths), and approved identifiers. Do not copy whole order/payment XML into logs; source serialization snippets demonstrate utility signatures only. Redact sensitive data. Static debug flags in the examples may not track runtime log-level changes.

Mock environments and API/service boundaries, including static helpers if the target test setup supports them. Tests must not contact OMS. Use the existing test stack; JUnit 5/Mockito is the source default, not a reason to replace the project's build.

## Worked examples need contract review

- The remorse-hold example combines `YFSBeforeCreateOrderUE` with a 30-minute age check and cancellation of an existing order. It does not establish that this hook will fire after 30 minutes. Confirm the trigger, persistence, timestamps/time zone, and recursion behavior before choosing an implementation.
- `BOPIS`, `DFS`, `REMORSE_HOLD`, statuses, organizations, and service names are project examples. Verify configured values and API cancellation semantics.
- The customer-history example's filters and `getShipmentListForOrder` name are unverified requirements. Verify available APIs and output templates; account for pagination and repeated API calls when implementing.
- Extension names, types, paths, and mappings are illustrative. Use target extension definitions and matching documentation; this migration adds no attribute resolver or schema-change automation.
