# Sterling OMS — Event Handler Conventions

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

## What is an Event Handler?
An Event Handler is a plain Java class invoked when a Sterling transaction event
fires (e.g. `SCHEDULE_ORDER.ON_BACKORDER`, `CREATE_ORDER.ON_SUCCESS`). Unlike UEs,
event handlers do NOT implement any Sterling interface. The class and method are
registered in Sterling's event configuration.

## Class Structure
- **Implements**: Nothing — plain Java class
- **Package**: `com.mycompany.event`
- **Naming**: `<DescriptiveAction>Impl.java` (e.g. `CancelOrderLineOnBackorderImpl.java`)
- **Entry point**: A single public method with signature `public Document methodName(YFSEnvironment env, Document inDoc)`
- **Method name**: Descriptive of the action (e.g. `cancelOrderOnBackorder`)

## Entry Point Method
```java
public Document cancelOrderOnBackorder(YFSEnvironment env, Document inDoc) {
    // logic here
    return outDoc;
}
```

## Output Document Pattern
Event handlers typically build a NEW output document (not modify the input):
```java
Document outDoc = XMLUtil.createDocument("Order");
Element eleOrderOut = outDoc.getDocumentElement();
```
This output document often feeds into a Sterling API like `changeOrder`.

## Logging
Same as UE conventions:
- `YFCLogCategory` with static final logger and `isDebugEnabled` flag
- Wrap debug logs with `if (isDebugEnabled)` check
- Use `beginTimer()` / `endTimer()` at method boundaries
- Log key identifiers (OrderHeaderKey, OrderLineKey) at debug level

## Constants
Same as UE conventions:
- `A_` prefix for attributes, `E_` prefix for elements
- Define ALL XML names as string constants at class level

## Error Handling
Same pattern as UE but throws `YFSException` (not `YFSUserExitException`):
```java
try {
    // logic
} catch (Exception e) {
    logger.error("Error in ClassName.methodName", e);
    YFSException yfse = new YFSException();
    yfse.setErrorCode("ERR_CUSTOM_CODE");
    yfse.setErrorDescription(e.getMessage());
    throw yfse;
}
```

## Class Header Comment
Same format as UE — include file name, description, and modification log.

## Utility Classes
Use the shared utility classes in `com.mycompany.util`.
Read [utility classes](utility-classes.md) when the target project supplies these helpers.

Quick guide — which method to call:
- **Call a Sterling API**: `SterlingUtil.invoke(env, Constants.API_CHANGE_ORDER, inDoc)`
- **Call API with output template**: `SterlingUtil.invokeAPI(env, templateName, apiName, inDoc)`
- **Execute a service/flow**: `SterlingUtil.executeFlow(env, serviceName, inDoc)` or `SterlingUtil.invokeService(env, serviceName, inDoc)`
- **Create XML document**: `XMLUtil.createDocument("Order")` — NOT `DocumentBuilderFactory`
- **Parse XML string**: `XMLUtil.getDocument(xmlString)`
- **Serialize to string**: `XMLUtil.serialize(node)` or `XMLUtil.getXMLString(doc)`
- **Debug log**: Use `logger.debug()` with `XMLUtil.serialize(inDoc)` — do NOT call `SterlingUtil.printInStruct()` or `SterlingUtil.printOutStruct()` for XML documents
- **Constants**: Always use `Constants.*` for API names, service names, hold types, statuses, templates

## Key Imports
```java
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import com.yantra.yfc.log.YFCLogCategory;
import com.yantra.yfs.japi.YFSEnvironment;
import com.yantra.yfs.japi.YFSException;
import com.mycompany.util.Constants;
import com.mycompany.util.SterlingUtil;
import com.mycompany.util.XMLUtil;
```
