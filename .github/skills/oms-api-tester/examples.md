# API Tester example prompts

Execution requires a configured API Tester URL, browser access, credentials, a user-specified API or service name, and user-supplied input XML compatible with the installed contract. The identifier below is illustrative; use your test environment's identifiers.

> Using the bundled API documentation, explain the input required by getOrderDetails. Do not invoke it.

Expected: consult the documented contract and describe required identifiers, without opening a database connection or submitting a request.

> In local API Tester, look up order 10001 using getOrderDetails. Check the input contract first and ask for any required identifiers that are missing.

Expected: ask the user to provide input XML for `getOrderDetails` before invoking. Explain required identifiers from the documented contract if helpful, but do not generate and submit a payload from the order number.

## Worked example: getOrderDetails

User input:

```text
<Order OrderHeaderKey="123"/> getOrderDetails
```

Fill the API Tester as follows:

- **Is a Service?**: unchecked.
- **API Name**: `getOrderDetails`.
- **Service Name**: empty.
- **UserId / Password**: the selected environment's configured credentials, entered using supported secret handling or by the user directly in the tester.
- **Message**: `<Order OrderHeaderKey="123"/>`.
- **Template**: empty for this example; clear any previous template.

Validate the input against the installed contract, then click **Test API Now!** once. Inspect the actual response and summarize the returned order details or OMS error. Do not claim order `123` exists or invent a successful response. This is an illustrative identifier, not a recorded live test.

If the user provides only `getOrderDetails`, ask: “Please provide the input XML for getOrderDetails, for example `<Order OrderHeaderKey="123"/>`, using your actual order header key.” Wait for their XML before submitting. If they already provided the complete input above, do not ask again.

## Additional example prompts

> Invoke getOrderDetails in local API Tester.

Expected: ask for input XML and do not submit until it is provided.

> Run this in local API Tester: <Order OrderHeaderKey="123"/>

Expected: ask which API or configured service to invoke, and clarify its type if necessary. Retain the supplied XML; do not guess the operation from the Order element.

> In local API Tester, invoke the documented read-only service using the XML I attach. Return only its result summary.

Expected: ask for the exact service name because it was not supplied. Once the name and attached input XML are available, verify the service's effect and contract, check Is a Service?, fill Service Name, put the XML in Message, fill request credentials safely, and click Test API Now! once. Inspect both HTTP and application errors.

> Prepare an API Tester request to cancel test order 10001, but do not submit it.

Expected: find the deployment-supported operation and contract. Do not invent a cancelOrder API or submit a write.

> The API Tester request timed out after submission. Check whether it completed before retrying.

Expected: investigate the outcome; never automatically repeat a potentially successful write.
