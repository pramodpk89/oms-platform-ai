# Sterling OMS — Database Extensions & Table Mapping

Adapted source-project guidance. Apply the [portability notes](portability.md) before using these examples; target-project contracts take precedence.

## API to Table Mapping
These are the primary tables that Sterling APIs read/write:

| API | Primary Table | Related Tables |
|-----|--------------|----------------|
| createOrder / changeOrder | YFS_ORDER_HEADER | YFS_ORDER_LINE, YFS_ORDER_HOLD_TYPE, YFS_PERSON_INFO, YFS_PAYMENT |
| createShipment / changeShipment | YFS_SHIPMENT | YFS_SHIPMENT_LINE, YFS_CONTAINER_DETAILS |
| scheduleOrder | YFS_ORDER_RELEASE | YFS_ORDER_RELEASE_LINE |
| confirmShipment | YFS_SHIPMENT | YFS_SHIPMENT_LINE, YFS_ORDER_LINE (status update) |
| createReturn / receiveOrder | YFS_ORDER_HEADER | YFS_ORDER_LINE, YFS_RECEIPT_HEADER, YFS_RECEIPT_LINE |
| manageItem | YFS_ITEM | YFS_ITEM_ATTR, YFS_CATEGORY_ITEM |

## When to Extend a Table (Extensions.xml)
Add a column to Extensions.xml when:
- The spec requires capturing a new attribute that doesn't exist in OOTB schema
- The attribute needs to persist across API calls (not just transient in-memory data)
- Use the existing [data-model skill](../../oms-data-model/SKILL.md) for documented schema and the target project’s extension definitions for customization details.

## Extensions.xml Conventions
- **Column naming**: Always prefix with `EXTN_` (e.g. `EXTN_LOYALTY_TIER`)
- **XMLName**: CamelCase with `Extn` prefix (e.g. `ExtnLoyaltyTier`)
- **Name**: Same as XMLName
- **Location**: `src/main/resources/Extensions.xml`
- **Structure**:
```xml
<Attribute ColumnName="EXTN_NEW_FIELD"
           DataType="VARCHAR" Size="50"
           Nullable="true"
           XMLName="ExtnNewField"
           Name="ExtnNewField"
           Type="Char" />
```

## Data Type Reference
| Type | DataType | Type attr | Notes |
|------|----------|-----------|-------|
| String | VARCHAR | Char | Use Size for max length |
| Number | DECIMAL | Number | Use Size and Scale |
| Flag (Y/N) | VARCHAR Size="1" | Char | Use for boolean flags |
| Date | TIMESTAMP | DateTime | Sterling date format |
| Integer | INTEGER | Number | Whole numbers |

## Index Conventions
- Name format: `EXTN_<TABLE_SHORT>_<COLUMN_SHORT>_IDX`
- Example: `EXTN_ORD_HDR_CHANNEL_IDX` for EXTN_ORDER_CHANNEL on YFS_ORDER_HEADER
- Only add index if the column is used in queries/lookups

## XML Element to Table Mapping
| XML Element | Sterling Table |
|-------------|---------------|
| Order | YFS_ORDER_HEADER |
| OrderLine | YFS_ORDER_LINE |
| OrderHoldType | YFS_ORDER_HOLD_TYPE |
| PersonInfoShipTo / PersonInfoBillTo | YFS_PERSON_INFO |
| PaymentMethod | YFS_PAYMENT |
| Shipment | YFS_SHIPMENT |
| ShipmentLine | YFS_SHIPMENT_LINE |
| Item | YFS_ITEM |
| Receipt | YFS_RECEIPT_HEADER |
| ReceiptLine | YFS_RECEIPT_LINE |
| Extn | Deployment-specific extension storage; inspect the target extension definition |
