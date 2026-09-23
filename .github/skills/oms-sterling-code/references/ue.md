# Sterling OMS — User Exit Conventions

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

## What is a User Exit?
A User Exit (UE) is a hook that Sterling calls before or after an API executes.
You implement a Sterling-provided interface (e.g. `YFSBeforeCreateOrderUE`) and
register your class in the Sterling configuration. Sterling calls your code at
the defined extension point.

## Class Structure
- **Implements**: The Sterling UE interface (e.g. `YFSBeforeCreateOrderUE`)
- **Package**: `com.mycompany.ue`
- **Naming**: `<InterfaceName>Impl.java` (e.g. `BeforeCreateOrderUEImpl.java`)
- **Method overloads**: Implement the signatures declared by the target UE interface. The example below reflects the source project; a String overload returning `null` is valid only when its contract permits it. Do not generate an unsupported overload or silently drop XML input.

## Entry Point Method
```java
@Override
public Document beforeCreateOrder(YFSEnvironment env, Document inDoc) throws YFSUserExitException {
    // logic here
    return inDoc;
}

@Override
public String beforeCreateOrder(YFSEnvironment env, String inXml) throws YFSUserExitException {
    return null;
}
```

## Logging
- Use `YFCLogCategory` — never `System.out.println` or `java.util.logging`
- Declare logger and debug flag as static finals at class level:
```java
private static final YFCLogCategory logger = YFCLogCategory.instance(MyClassName.class);
private static final boolean isDebugEnabled = logger.isDebugEnabled();
```
- Wrap all debug logging with `if (isDebugEnabled)` check
- Use `logger.beginTimer()` / `logger.endTimer()` at start/end of each method
- Timer names follow pattern: `ClassName:methodName:start` and `ClassName:methodName:end`

## Constants
- Define string constants for ALL XML attribute and element names at class level
- Naming convention: `A_` prefix for attributes, `E_` prefix for elements
```java
private static final String A_ORDER_HEADER_KEY = "OrderHeaderKey";
private static final String E_ORDER_LINES      = "OrderLines";
```

## Error Handling
- Catch `YFSException` and rethrow as-is
- Catch `Exception` separately, log it, wrap in `YFSException` with custom error code
```java
try {
    // logic
} catch (YFSException yfse) {
    throw yfse;
} catch (Exception e) {
    logger.error("Error in ClassName.methodName", e);
    YFSException yfse = new YFSException();
    yfse.setErrorCode("ERR_CUSTOM_CODE");
    yfse.setErrorDescription(e.getMessage());
    throw yfse;
}
```

## Properties
- Always include `setProperties` method:
```java
private Properties props;
public void setProperties(Properties inProps) {
    this.props = inProps;
}
```

## Class Header Comment
```java
/******************************************************************************************
 * File Name        : ClassName.java
 *
 * Description      : Brief description of what this UE does.
 *
 * Modification log :
 * ----------------------------------------------------------------------------------------
 * Ver #    Date            Author          Modification
 * ----------------------------------------------------------------------------------------
 * 1.0      DD-MM-YYYY      Dev Team        Class Created
 * ----------------------------------------------------------------------------------------*/
```

## XML Document Operations
- Use `inDoc.getDocumentElement()` to get root element
- Use `getElementsByTagName()` to navigate, cast to `Element`
- Use `getAttribute()` / `setAttribute()` for reading/writing attributes
- Use `YFCCommon.isVoid()` to check for empty/null attribute values

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
- **Get child element**: `XMLUtil.getFirstElementByName(parentEle, "OrderLine")`
- **Debug log input/output**: Use `logger.debug()` with `XMLUtil.serialize(inDoc)` — do NOT call `SterlingUtil.printInStruct()` or `SterlingUtil.printOutStruct()` for XML documents
- **Get common codes**: `SterlingUtil.getCommonCodeLongDescMap(env, codeType, orgCode)`
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
import com.yantra.yfs.japi.YFSUserExitException;
import com.mycompany.util.Constants;
import com.mycompany.util.SterlingUtil;
import com.mycompany.util.XMLUtil;
```
