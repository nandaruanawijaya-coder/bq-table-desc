# Claude Code Table Documentation Reference

> **For Claude Code** - Read this when asked to document BigQuery tables. Data team only needs to update `table_list.md` and run Claude Code.

---

## How to Use This Document

When a data team member asks Claude Code to document tables:

```
User: "Document all tables in table_list.md that don't have documentation in table_column_description/ yet"
```

Claude Code will:
1. Read this document to understand the workflow
2. Read `table_list.md` for the list of tables and their context
3. Check `table_column_description/` for existing documentation
4. Document missing tables following the rules below
5. Commit to git

---

## Superpowers Methodology Applied

This process follows the [obra superpowers](https://github.com/obra/superpowers) framework:

- **Design Phase**: Ask clarifying questions about what makes documentation useful (answer: for AI SQL assistant)
- **Systematic Process**: Clear steps for documentation generation
- **Data-Driven**: Extract patterns from actual 10k rows of data
- **Verification**: Test descriptions against success criteria

---

## Workflow

```
READ table_list.md → EXTRACT table list with business context
  ↓
FILTER documented vs undocumented tables
  ↓
FOR EACH undocumented table:
  ├─ FETCH 10,000 rows from BigQuery
  ├─ ANALYZE each column:
  │   ├─ Detect value format (UUID, phone, enum, etc)
  │   ├─ Generate description (3 sources: name + data + context)
  │   ├─ List possible values (if ≤20 unique)
  │   └─ Set business context (from null %)
  ├─ SAVE JSON to table_column_description/[TABLE_NAME]_doc.json
  └─ GIT commit with summary
```

---

## Data Source: table_list.md Format

```markdown
# Tables to Document

- ledger-fcc1e.project.dataset.table_name
Table context: Business purpose and meaning in 1-2 sentences
```

Each table has:
- **Full table ID** (project.dataset.table)
- **Context** (2 lines max): What this table contains and how it's used

Example:
```
- ledger-fcc1e.db_accounting.prod_edc_order
Table explaining Historical EDC Order from Merchants, each row represents unique order
```

---

## Output: table_column_description JSON Schema

```json
{
  "table_name": "prod_edc_order",
  "full_table_id": "ledger-fcc1e.db_accounting.prod_edc_order",
  "total_columns": 36,
  "sample_rows_analyzed": 10000,
  "documentation_generated": "2026-05-06T11:45:00",
  "columns": [
    {
      "column_name": "order_id",
      "data_type": "STRING",
      "nullable": true,
      "null_percentage": 0.0,
      "description": "Unique order identifier in UUID v4 format. Primary key for EDC order records.",
      "business_context": "Required field - always populated",
      "example_values": ["31ca7df4-4648-41c1-bc8e-9bf25c628e16"],
      "possible_values": null
    }
  ]
}
```

**Key fields**:
- `description`: 1-2 sentence explanation (see description rules below)
- `business_context`: Populated based on null_percentage
- `possible_values`: Only present if ≤20 unique values exist (for enums/status fields)

---

## Description Generation Rules

Descriptions must help an AI SQL assistant write correct queries by explaining **what the data means and how it's used**, not just naming the field.

### Key Principle: Explanatory Descriptions

Every description must answer: **"What is this field and why does it exist in this table?"**

❌ Bad examples:
- "Province field" — just naming
- "Card Transactions field" — generic
- "Year founded field" — too short

✓ Good examples:
- "State or province level administrative division for merchant location and geographic segmentation"
- "Number or volume of card-based transactions processed. Key metric for EDC usage and card payment adoption"
- "Year the business was established. Indicates business age and operational stability"

### Description Sources (Priority Order)

Apply in order — use first match:

**1. SDC Metadata Columns** (`_sdc_*`)
```
_sdc_batched_at → "Singer data connector: timestamp when batch was processed in the pipeline"
_sdc_sequence → "Singer data connector: sequence number for change data capture ordering"
_sdc_table_version → "Singer data connector: table schema version for data lineage tracking"
_sdc_received_at → "Timestamp when record was received by data pipeline. Tracks data ingestion timing"
```

**2. UUID Format** (36-char hex: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
```
Detect: all values match UUID pattern
Generate: "Unique [entity] identifier in UUID v4 format. [Business purpose]"

Examples:
- order_id → "Unique order identifier in UUID format. Primary key for EDC order. Used for order tracking and joins"
- prospect_merchant_profile_id → "Unique identifier for merchant profile in system. Used for merchant record tracking"
```

**3. Phone Number** (8-13 digits, starts with 8)
```
Detect: all values are digits, 8-13 length, start with 8
Generate: "Phone number (10-11 digit Indonesian mobile). [Business context for how it's used]"

Examples:
- phoneNumber → "Phone number (10-11 digit Indonesian mobile). Primary key for merchant profile. Used for order linking and merchant identification"
- referee_phone → "Phone of referrer or partner. Contact information for referral channel management"
```

**4. Bank Account** (8-16 digits)
```
Detect: all values are digits, 8-16 length
Generate: "Bank account number for merchant settlement and payout"
```

**5. Coordinates & Geographic Columns**
```
lat_long → "Latitude,longitude coordinate pair for precise merchant location. Used for geographic mapping and device delivery routing"
latitude → "Latitude coordinate for merchant location. Component of geographic coordinate for mapping and analysis"
province → "State or province level administrative division for merchant location and geographic segmentation"
kabupaten → "Regency (kabupaten) administrative division. Used for merchant location detail and regional sales organization"
kecamatan → "District (kecamatan) administrative division. Used for detailed merchant location hierarchy and territory management"
```

**6. Timestamps** (data_type = TIMESTAMP, DATETIME, or contains 'date'/'time')
```
createdAt → "Timestamp when merchant profile was created. Indicates merchant onboarding date"
updatedAt → "Timestamp of last profile update. Tracks when merchant information was last modified"
latestVisitDate → "Date of last visit by MSE or sales representative. Indicates engagement frequency"
processing timestamp → "Timestamp when the data was processed through the pipeline"
```

**7. Business Metrics & Counts**
```
numberOfEmployees → "Number of employees in merchant's business. Used for business classification and capacity assessment"
estimatedCustomersPerDay → "Estimated daily customer count for the merchant. Indicates business volume and sales potential"
cardTransactions → "Number or volume of card-based transactions processed. Key metric for EDC usage and card payment adoption"
totalDailyTransactions → "Expected daily transaction count. Used for business sizing and product recommendation"
```

**8. Boolean Flags** (`is_*`, `has_*`, `*_flag`)
```
hasBRIEDC → "Boolean indicating if merchant has active BRI EDC machine. Used for product penetration analysis"
hasAndroidEDC → "Boolean indicating if merchant has Android-based EDC terminal. Identifies modern payment technology adoption"
data_source_flag → "Flag indicating the data source or origin (e.g., Backfill, CRM, API). Used for data lineage tracking"
visited_by_mee_flag → "Boolean indicating if merchant has been visited by MEE. Tracks sales engagement activity"
```

**9. Status & Lifecycle Fields**
```
status → "Order lifecycle status (Draft, Unassigned, Active, Completed, Cancelled). Indicates order processing stage"
payment_status → "Payment completion status for order. Indicates whether merchant has completed payment"
delivery_status → "Delivery progress status for EDC device. Tracks physical shipment status of device to merchant"
kyc_tier → "Merchant KYC verification tier level. Indicates compliance status and verification completeness"
parsing_status → "Status of address parsing from geocoding service. Indicates confidence level of location parsing"
```

**10. Names & Identifiers**
```
ownerName → "Merchant owner's full name. Used for KYC verification and merchant identification"
businessName → "Business or store name. Used for merchant identification and business classification"
mse_name_updated → "Name of Merchant Success Executive assigned to merchant territory. Used for sales team assignment and accountability"
```

**11. Product & Business Classification**
```
business_type → "Type of business operation (Retail, Food, Services, etc). Used for merchant segmentation and sales targeting"
businessindustry → "Industry classification for merchant business. Enables industry-specific analysis and product targeting"
storeType → "Store or business type classification. Indicates merchant business model and product suitability"
```

**12. Loan & Financial Products**
```
loanName → "Name or product type of active loan. Identifies which loan product merchant holds"
loanOwnership → "Loan product status and ownership. Indicates if merchant has active loan with BukuWarung"
interestedinloan → "Boolean indicating merchant interest in loan products. Indicates sales opportunity for financing"
completedLoanDate → "Date when merchant completed loan application. Tracks loan onboarding timeline"
```

**13. Metadata & Attachments**
```
metadata → "Additional structured data object for order. Contains supplementary information not in standard columns"
payment_metadata → "Metadata containing payment and settlement details for order. Tracks payment transaction information"
delivery_metadata → "Metadata containing delivery details: AWB, courier name, tracking dates, serial number. Used for shipment tracking"
attachments → "Attached documents or file references for order. Contains supporting documentation and proof"
gsheet_ssot_documentation → "Reference to shared spreadsheet documentation. Links to detailed source documentation"
```

**14. Referral & Partnership**
```
referee_name → "Name of referrer or partner who referred merchant. Used for partnership tracking and referral attribution"
purchase_referral → "Referral source or channel that led to order. Tracks acquisition source for analysis"
```

**15. Team & Organizational Hierarchy**
```
current_mse_hor → "Current Head of Region assigned to merchant. Indicates merchant's regional management hierarchy"
current_mse_hoa → "Current Head of Area assigned to merchant. Indicates merchant's area management oversight"
head_of_area → "Name of Area Head supervising geographic area and MSE team. Top area management for performance accountability"
area → "Geographic area region classification (Java 1-3, Sumatera 1-3, etc). Used for MSE organization and sales targets"
region → "Broad geographic region (JAVA, SUMATERA, EAST INDO). High-level geographic grouping for organizational hierarchy"
```

### Fallback (only if no patterns match)

```
For truly unclassifiable columns:
- Use the column name intelligently combined with table context
- If all values are null: "Empty column - no data currently available"
- Otherwise: "[ColumnName description] field in [table context]"
```

### Three-Source Rule

Best descriptions combine **all three sources**:
1. **Column name** — what the field is literally called
2. **Data patterns** — what format/type values take (UUID, phone, timestamps)
3. **Business context** — why this field exists and how it's used in the system

Example combining all three:
```
Column: estimatedCustomersPerDay (source 1)
Data: numeric values 10-500 (source 2)
Context: merchant segmentation, sales targeting (source 3)

Result: "Estimated daily customer count for the merchant. Indicates business volume and sales potential"
```

---

## Business Context Generation

Based on null_percentage:

```
null_percentage == 0 → "Required field - always populated"
null_percentage < 10 → "Core field - rarely empty (>90% populated)"
null_percentage < 50 → "Common field - frequently populated (>50%)"
null_percentage >= 50 → "Optional field - sparsely populated"
```

---

## Enumeration (possible_values Field)

**When to add**: Column has ≤ 20 unique non-null values across 10k rows

**How**: 
```python
unique_values = sorted(set(non_null_values))
if 0 < len(unique_values) <= 20:
    col_doc["possible_values"] = unique_values
```

**Use case**: Helps AI SQL assistant understand valid values for WHERE clauses and enums.

Example:
```json
{
  "column_name": "status",
  "possible_values": ["Active", "Cancelled", "Completed", "Draft", "Unassigned"]
}
```

---

## Implementation: In-Memory Python Execution

When documenting tables, Claude Code will:

1. **Parse table_list.md** to extract:
   - Table IDs
   - Business context for each table (used in all descriptions)

2. **For each missing table**, fetch 10,000 rows and:
   ```python
   # Detect value formats from actual sample data
   - Detect: UUID patterns, phone numbers (8-13 digits, starts with 8)
   - Detect: bank accounts (8-16 digits), coordinates, timestamps
   
   # Collect all values per column
   - Collect ALL non-null values for enumeration (if ≤20 unique)
   - Sample first 3 values for pattern detection
   
   # Generate semantic description
   - Apply Priority Order rules (SDC → UUID → phone → coords → timestamps → metrics)
   - Look up column name in comprehensive description map
   - Combine: detected format + business purpose + table context
   - NEVER fall back to bare "[ColumnName] field" descriptions
   
   # Build JSON documentation
   - description: semantic explanation (1-2 sentences minimum)
   - business_context: based on null_percentage
   - example_values: first 3 non-null values
   - possible_values: if ≤20 unique values
   
   - Save to table_column_description/[TABLE_NAME]_doc.json
   ```

3. **Git commit** with comprehensive message:
   ```
   Enhance column descriptions with business context and semantic meaning
   
   - Replace generic naming with explanatory descriptions
   - Add business purpose and usage context for each column
   - Explain how fields relate to order lifecycle, merchant profiles, team hierarchy
   - Include value semantics (product adoption, KYC verification, sales targeting)
   - Improve enumeration for low-cardinality columns
   ```

---

## Success Criteria

After documentation, verify all columns meet these standards:

✓ **Explanatory descriptions** — no bare "[ColumnName] field" or "[ColumnName] field" patterns
  - Each description should answer "what is this and why does it exist?"
  - Minimum 1-2 sentences explaining business purpose and usage
  - Example: ✓ "Estimated daily customer count. Indicates business volume and sales potential"
  - Example: ✗ "Estimated Customers Per Day field"

✓ **Value formats identified** — semantic patterns explicitly mentioned
  - UUIDs → "UUID v4 format" or "unique identifier"
  - Phone numbers → "10-11 digit Indonesian mobile"
  - Timestamps → "Timestamp when..." or "Timestamp of..."
  - Coordinates → "Latitude,longitude" or "geocoding"
  - Bank accounts → "Bank account number"

✓ **Business context included** — explain how field is used
  - Product metrics → "Used for product penetration analysis"
  - KYC fields → "Used for KYC verification and merchant profiling"
  - Sales fields → "Used for sales team assignment and accountability"
  - Timestamps → "Indicates onboarding date" or "Tracks engagement frequency"

✓ **SDC metadata clearly marked**
  - All `_sdc_*` columns identify as "Singer data connector"
  - Explain purpose: "for data lineage tracking", "for change data capture ordering"

✓ **Enum columns have `possible_values`** array
  - For columns with ≤20 unique values across 10k rows
  - Directly useful for AI SQL assistant WHERE clauses

✓ **No generic fallbacks** — descriptions avoid these patterns:
  - ✗ "XXX field"
  - ✗ "Name or title of XXX"
  - ✗ "XXX field for business operations"
  - ✗ "Empty column - no sample data available" (only if 100% null)

✓ **Business context set correctly** based on null_percentage
  - 0% null → "Required field - always populated"
  - <10% null → "Core field - rarely empty (>90% populated)"
  - <50% null → "Common field - frequently populated (>50%)"
  - ≥50% null → "Optional field - sparsely populated"

---

## Comprehensive Description Map Reference

Claude Code uses a detailed mapping of 150+ column patterns to generate explanatory descriptions. The map includes:

**Common Column Patterns:**
- **Location fields**: province, kabupaten, kecamatan, kelurahan, postal_code, address, district, regency
- **Merchant identifiers**: phoneNumber, user_id, ownerName, businessName, kyc_name
- **Business metrics**: numberOfEmployees, estimatedCustomersPerDay, totalDailyTransactions, cardTransactions
- **Product ownership**: hasBRIEDC, hasBNIEDC, hasAndroidEDC, edcOwnership, loanOwnership
- **Team hierarchy**: mse_name_updated, mse_lead, head_of_area, head_of_region, current_mse_hor, current_mse_hoa
- **Loan information**: loanName, completedLoanDate, desiredloanlimit, interestedinloan
- **Order/Transaction**: order_id, status, delivery_status, payment_status, transaction_id
- **Timestamps**: createdAt, updatedAt, latestVisitDate, _sdc_batched_at
- **Metadata**: metadata, payment_metadata, delivery_metadata, attachments
- **MEE segment**: mee_* columns for Merchant Empowerment Executive sales channel
- **Retail segment**: retail_* columns for modern retail merchants

**How the Map Works:**

When documenting a new table:
1. Claude Code reads this file for the priority rules and description examples
2. For each column, looks up the column name in the comprehensive map
3. If found, uses the mapped description
4. If not found, applies the Priority Order rules based on data patterns
5. Falls back to intelligent name-based descriptions with table context

**To Add New Column Descriptions:**

When you document a new table with new columns not in the map:
1. Claude Code will auto-generate descriptions using the Priority Order rules
2. If you find descriptions are too generic, you can:
   - Add the column pattern to this guide for future tables
   - Request an improvement in your pull request
   - Data team will review and suggest enhancements

---

## For Data Team

**To document new tables:**

1. Add to `table_list.md`:
   ```
   - ledger-fcc1e.project.dataset.new_table
   Description of what this table contains and how it's used
   ```

2. In Claude Code, ask:
   ```
   Document all tables in table_list.md that don't have 
   documentation in table_column_description/ yet
   ```

3. Claude Code will:
   - Read this file as reference
   - Follow the workflow above
   - Generate documentation
   - Commit automatically

**That's it!** No other steps needed.

---

## Reference Links

- Table List: `table_list.md`
- Documentation Output: `table_column_description/*.json`
- Sample Data: `table_list/*.json` (10k rows per table)
- Superpowers Methodology: https://github.com/obra/superpowers
