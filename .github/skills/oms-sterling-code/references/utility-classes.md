# Sterling OMS — Utility Class Method Reference

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

All utility classes are in `com.mycompany.util`. Use these instead of writing boilerplate.

---

## SterlingUtil — Calling APIs, Services, and Flows

### When to use which method:

| You need to... | Call this | Example |
|----------------|-----------|---------|
| Call a Sterling OOTB API (getOrderList, changeOrder, etc.) | `SterlingUtil.invoke(env, apiName, inDoc)` | `SterlingUtil.invoke(env, Constants.API_CHANGE_ORDER, changeOrderDoc)` |
| Call an API with an output template (named) | `SterlingUtil.invokeAPI(env, templateName, apiName, inDoc)` | `SterlingUtil.invokeAPI(env, Constants.TEMPLATE_GET_ORDER_LIST, Constants.API_GET_ORDER_LIST, inputDoc)` |
| Call an API with an output template (Document) | `SterlingUtil.invokeAPI(env, templateDoc, apiName, inDoc)` | `SterlingUtil.invokeAPI(env, templateDoc, "getCompleteOrderDetails", inputDoc)` |
| Call an API with XML string input | `SterlingUtil.invokeAPI(env, apiName, xmlString)` | `SterlingUtil.invokeAPI(env, "getOrderList", "<Order OrderNo='123'/>")` |
| Execute a Sterling service/flow | `SterlingUtil.executeFlow(env, serviceName, inDoc)` | `SterlingUtil.executeFlow(env, Constants.SRVC_POST_EMAIL_UPDATES, emailDoc)` |
| Execute a service (alias for executeFlow) | `SterlingUtil.invokeService(env, serviceName, inDoc)` | `SterlingUtil.invokeService(env, "PostItemListForIV", itemDoc)` |
| Execute a service with XML string input | `SterlingUtil.invokeService(env, serviceName, xmlString)` | `SterlingUtil.invokeService(env, "ExportPaymentData", xmlStr)` |

### Other SterlingUtil helpers:

| Method | Purpose | Example |
|--------|---------|---------|
| `invokeCommonCode(env, codeType)` | Get common code list for a code type | `SterlingUtil.invokeCommonCode(env, "REMORSE_HOLD")` |
| `invokeCommonCode(env, codeType, orgCode)` | Get common code for a code type + org | `SterlingUtil.invokeCommonCode(env, "SFS_TIME_FORMAT", "DEFAULT")` |
| `getCommonCodeLongDescMap(env, codeType, orgCode)` | Returns Map of CodeValue → LongDescription | `Map<String,String> map = SterlingUtil.getCommonCodeLongDescMap(env, "HOLD_TYPE", "DEFAULT")` |
| `getCommonCodeShortDescMap(env, codeType, orgCode)` | Returns Map of CodeValue → ShortDescription | `Map<String,String> map = SterlingUtil.getCommonCodeShortDescMap(env, "NODE_TYPE", "DEFAULT")` |
| `isValidString(str)` | Check if string is non-null and non-empty | `if (SterlingUtil.isValidString(orderNo))` |
| `getNodeTypeForOrganization(env, orgCode)` | Returns node type (Store, DC, Vendor) for an org | `String type = SterlingUtil.getNodeTypeForOrganization(env, shipNode)` |
| `getShipNodeType(env, shipNode)` | Returns ship node type | `String nodeType = SterlingUtil.getShipNodeType(env, "6001")` |
| `convertStatusToDouble(status)` | Convert status string to Double for comparison | `Double d = SterlingUtil.convertStatusToDouble("3200")` |
| `getCurrentDateTime()` | Get current timestamp in Sterling format | `String now = SterlingUtil.getCurrentDateTime()` |
| ~~`printInStruct`/`printOutStruct`~~ | **DO NOT USE** for XML documents — these methods take `YFSExtnPaymentCollectionInputStruct`/`OutputStruct`, NOT `(env, Document)`. For debug logging XML, use `logger.debug("message: " + XMLUtil.serialize(inDoc))` inside an `if (isDebugEnabled)` check. |
| `addNotesOnOrderLines(env, inDoc, noteText, lineList)` | Add notes to specific order lines | `SterlingUtil.addNotesOnOrderLines(env, orderDoc, "Cancelled by system", cancelledLines)` |

---

## XMLUtil — Creating and Manipulating XML Documents

### Document creation:

| Method | Purpose | Example |
|--------|---------|---------|
| `XMLUtil.createDocument(rootTag)` | Create a new Document with root element | `Document doc = XMLUtil.createDocument("Order")` |
| `XMLUtil.newDocument()` | Create an empty Document (no root) | `Document doc = XMLUtil.newDocument()` |
| `XMLUtil.getDocument(xmlString)` | Parse XML string into Document | `Document doc = XMLUtil.getDocument("<Order OrderNo='123'/>")` |
| `XMLUtil.getDocument(inputStream)` | Parse InputStream into Document | `Document doc = XMLUtil.getDocument(is)` |

### Element operations:

| Method | Purpose | Example |
|--------|---------|---------|
| `XMLUtil.getAttribute(element, attrName)` | Get attribute value (returns "" if null) | `String val = XMLUtil.getAttribute(orderEle, "OrderNo")` |
| `XMLUtil.setAttribute(element, attrName, value)` | Set attribute value | `XMLUtil.setAttribute(orderEle, "Status", "1100")` |
| `XMLUtil.getFirstElementByName(parent, tagName)` | Get first child element by tag name | `Element lineEle = XMLUtil.getFirstElementByName(orderEle, "OrderLine")` |
| `XMLUtil.appendChild(doc, parent, childTag, value)` | Create child element with text content | `XMLUtil.appendChild(doc, orderEle, "Note", "some text")` |
| `XMLUtil.createElement(doc, tag, attributes)` | Create element with attributes (Hashtable) | `XMLUtil.createElement(doc, "OrderLine", attrMap)` |

### Serialization:

| Method | Purpose | Example |
|--------|---------|---------|
| `XMLUtil.serialize(node)` | Serialize node to XML string | `String xml = XMLUtil.serialize(inDoc)` |
| `XMLUtil.getXMLString(document)` | Get document as XML string | `String xml = XMLUtil.getXMLString(outDoc)` |
| `XMLUtil.getElementXMLString(element)` | Get element as XML string | `String xml = XMLUtil.getElementXMLString(orderEle)` |

### Navigation:

| Method | Purpose | Example |
|--------|---------|---------|
| `XMLUtil.getElementsByTagName(parent, tag)` | Get child elements as List | `List lines = XMLUtil.getElementsByTagName(orderEle, "OrderLine")` |
| `XMLUtil.getSubNodeList(parent, tag)` | Get sub-nodes as List | `List items = XMLUtil.getSubNodeList(lineEle, "Item")` |

---

## Constants — Application-Wide Constants

Use `Constants.*` instead of inline strings. Key constant categories:

| Category | Example Constants | Usage |
|----------|-------------------|-------|
| API names | `Constants.API_GET_ORDER_LIST`, `Constants.API_CHANGE_ORDER`, `Constants.API_CHANGE_ORDER_STATUS` | First arg to `SterlingUtil.invoke()` |
| Service names | `Constants.SRVC_POST_EMAIL_UPDATES`, `Constants.SRVC_GET_APPEASEMENTS` | Arg to `SterlingUtil.executeFlow()` or `invokeService()` |
| Hold types | `Constants.STR_REMORSE_HOLD_TYPE`, `Constants.STR_AUTH_HOLD_TYPE`, `Constants.AVS_HOLD_TYPE` | Set on OrderHoldType element |
| Hold statuses | `Constants.STR_HOLD_CREATED_STATUS` ("1100"), `Constants.STR_HOLD_RESOLVE_STATUS` ("1300") | Status attribute on holds |
| Order statuses | `Constants.ORDER_RELEASED_STATUS` ("3200"), `Constants.ORDER_CANCELLED_STATUS` ("9000") | Status comparisons |
| Values | `Constants.STR_VAL_Y`, `Constants.STR_VAL_N`, `Constants.STR_VAL_EACH` | Common attribute values |
| Templates | `Constants.TEMPLATE_GET_ORDER_LIST`, `Constants.TEMPLATE_GET_COMPLETE_ORDER_DETAILS` | Output templates for API calls |
| Org codes | `Constants.SELLER_ORGANIZATION`, `Constants.CATALOG_ORGANIZATION` | Enterprise/org values |

**Always search Constants.java for an existing constant before creating a new inline string.**
