# Sterling OMS — Custom API Conventions

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

## What is a Custom API?
A Custom API is a user-defined API registered in Sterling that can be invoked
like any OOTB API. The class implements `YIFCustomApi` and the entry point is
the configured method (named `invoke` in these examples). The API name is registered in Sterling configuration.

## Class Structure
- **Implements**: `com.yantra.interop.japi.YIFCustomApi`
- **Package**: `com.mycompany.customapi`
- **Naming**: `<ApiName>Impl.java` (e.g. `GetCustomerOrderHistoryImpl.java`)
- **Entry point**: `invoke(YFSEnvironment env, Document inDoc)` is the source convention; verify the configured method and interface contract.

## Entry Point Method
```java
public Document invoke(YFSEnvironment env, Document inDoc) throws YFSException {
    // logic here
    return outDoc;
}
```

Include the interface-required `setProperties(Properties)` method where applicable; verify against the target SDK. Do not add `@Override` to the configured business method unless it actually overrides a declared method.

## Calling Other Sterling APIs
When the target project has the source helpers:
```java
Document outDoc = SterlingUtil.invoke(env, Constants.API_GET_ORDER_LIST, inputDoc);
```
Otherwise use the project's established API wrapper after checking its signature.

## Input Validation
Always validate required input attributes at the start of `invoke`:
```java
Element rootEle = inDoc.getDocumentElement();
String enterpriseCode = rootEle.getAttribute("EnterpriseCode");
if (YFCCommon.isVoid(enterpriseCode)) {
    YFSException yfse = new YFSException();
    yfse.setErrorCode("ERR_MISSING_ENTERPRISE_CODE");
    yfse.setErrorDescription("EnterpriseCode is required");
    throw yfse;
}
```

## Output Document Pattern
Custom APIs build and return a new output document:
```java
Document outDoc = XMLUtil.createDocument("OrderList");
Element eleRoot = outDoc.getDocumentElement();
// populate response
return outDoc;
```

## Logging
Same as UE/Event conventions:
- `YFCLogCategory` with static final logger and `isDebugEnabled` flag
- Wrap debug logs with `if (isDebugEnabled)` check
- Use `beginTimer()` / `endTimer()` at method boundaries
- Log input parameters at debug level on entry

## Constants
Same as UE/Event conventions:
- `A_` prefix for attributes, `E_` prefix for elements
- Define ALL XML names as string constants

## Error Handling
Same pattern as Event handlers — `YFSException` with custom error codes.

## Class Header Comment
Same format as UE/Event — include file name, description, and modification log.

## Utility Classes
Use the shared utility classes in `com.mycompany.util`.
Read [utility classes](utility-classes.md) when the target project supplies these helpers.

Quick guide — which method to call:
- **Call a Sterling API**: `SterlingUtil.invoke(env, Constants.API_GET_ORDER_LIST, inDoc)` — NEVER use `YIFApi` directly
- **Call API with output template**: `SterlingUtil.invokeAPI(env, templateName, apiName, inDoc)`
- **Execute a service/flow**: `SterlingUtil.executeFlow(env, serviceName, inDoc)` or `SterlingUtil.invokeService(env, serviceName, inDoc)`
- **Create XML document**: `XMLUtil.createDocument("Order")` — NEVER use `DocumentBuilderFactory` directly
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
import com.yantra.yfc.util.YFCCommon;
import com.yantra.yfs.japi.YFSEnvironment;
import com.yantra.yfs.japi.YFSException;
import com.yantra.interop.japi.YIFCustomApi;
import com.mycompany.util.Constants;
import com.mycompany.util.SterlingUtil;
import com.mycompany.util.XMLUtil;
```
