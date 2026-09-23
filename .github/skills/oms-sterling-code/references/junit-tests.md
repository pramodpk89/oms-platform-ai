# Sterling OMS — JUnit 5 Test Conventions

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

## Tests for generated business logic
Provide corresponding tests for new UE, event, and custom API behavior. The source convention is JUnit 5 with Mockito; follow an existing target test stack when present.

## Class Structure
- **Package**: Mirror the source package under `src/test/java/` (e.g. `com.mycompany.ue` → `src/test/java/com/mycompany/ue/`)
- **Naming**: `<ClassName>Test.java` (e.g. `BeforeCreateOrderUEImplTest.java`)
- **Annotations**: Use `@ExtendWith(MockitoExtension.class)` on the test class

## Mocking Sterling Objects
Sterling objects cannot be instantiated directly. Always mock them:
```java
@Mock
private YFSEnvironment mockEnv;
```
- Mock `YFSEnvironment` — never instantiate it
- Create real XML `Document` objects using `DocumentBuilderFactory` for test inputs — do NOT mock Document/Element

## Test Input XML
Build test XML documents using standard DOM:
```java
private Document createOrderDocument(boolean includePaymentMethod, boolean includeBillTo) throws Exception {
    DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
    Document doc = factory.newDocumentBuilder().newDocument();
    Element orderEle = doc.createElement("Order");
    doc.appendChild(orderEle);
    // add child elements as needed for the test scenario
    return doc;
}
```

## Test Scenarios — MUST cover all three:
1. **Positive/happy path**: Valid input, expected successful output
2. **Negative/error path**: Missing or invalid input, expected exception with correct error code
3. **Edge cases**: Empty elements, missing optional elements, boundary conditions

## Test Method Naming
Use descriptive names that state the scenario and expected outcome:
```java
@Test
void shouldReturnDocumentWhenPaymentMethodPresent() { }

@Test
void shouldThrowExceptionWhenPaymentMethodMissing() { }

@Test
void shouldCopyShipToToBillToWhenBillToMissing() { }
```

## Assertions
- Use JUnit 5 assertions: `assertEquals`, `assertNotNull`, `assertThrows`
- For exception tests, verify both the exception type AND the error code:
```java
YFSUserExitException ex = assertThrows(YFSUserExitException.class, () -> {
    ueImpl.beforeCreateOrder(mockEnv, inputDoc);
});
assertEquals("YFS_PAYMENT_REQUIRED", ex.getErrorCode());
```
- For XML output, verify attributes on the returned document:
```java
Document result = ueImpl.beforeCreateOrder(mockEnv, inputDoc);
Element billTo = (Element) result.getElementsByTagName("PersonInfoBillTo").item(0);
assertNotNull(billTo);
assertEquals("123 Main St", billTo.getAttribute("AddressLine1"));
```

## Key Imports
```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import javax.xml.parsers.DocumentBuilderFactory;
import com.yantra.yfs.japi.YFSEnvironment;
```

## DO NOT
- Do NOT mock `Document` or `Element` — create real XML objects
- Use the target project’s test stack; these examples use JUnit 5
- Do NOT skip negative test cases — every error path in the spec must be tested
- Do NOT use `System.out.println` in tests — use assertions
