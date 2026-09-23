# API Tester example prompts

Execution requires a configured API Tester URL, browser access, and deployment-compatible API contracts. Replace order numbers and supply required enterprise/document identifiers for your test environment.

> Using the bundled API documentation, explain the input required by getOrderDetails. Do not invoke it.

Expected: consult the documented contract and describe required identifiers, without opening a database connection or submitting a request.

> In local API Tester, look up order 10001 using getOrderDetails. Check the input contract first and ask for any required identifiers that are missing.

Expected: prepare valid input from the documented contract, invoke through the browser, and summarize the response. Do not guess enterprise identifiers.

> In local API Tester, invoke the documented read-only service using the XML I attach. Return only its result summary.

Expected: verify the service's effect and contract, select the correct mode, and inspect both HTTP and application errors.

> Prepare an API Tester request to cancel test order 10001, but do not submit it.

Expected: find the deployment-supported operation and contract. Do not invent a cancelOrder API or submit a write.

> The API Tester request timed out after submission. Check whether it completed before retrying.

Expected: investigate the outcome; never automatically repeat a potentially successful write.
