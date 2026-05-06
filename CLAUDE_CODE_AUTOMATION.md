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

Descriptions must help an AI SQL assistant write correct queries. **Never use bare fallbacks like "Field for X"**.

### Priority Order (apply first match)

**1. SDC Metadata Columns** (`_sdc_*`)
```
_sdc_batched_at → "Singer data connector: timestamp when batch was processed in the pipeline"
_sdc_sequence → "Singer data connector: sequence number for change data capture ordering"
_sdc_table_version → "Singer data connector: table schema version for data lineage tracking"
```

**2. UUID Format** (36-char hex: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
```
Detect: all values match UUID pattern
Generate: "Unique [entity] identifier in UUID v4 format. [Context]"

Examples:
- order_id → "Unique order identifier in UUID v4 format. Primary key for EDC order records."
- user_id_uuid → "Unique user identifier in UUID v4 format."
```

**3. Phone Number** (8-13 digits, starts with 8)
```
Detect: all values are digits, 8-13 length, start with 8
Generate: "Phone number (10-11 digit Indonesian mobile, no country code prefix). [Context]"

Examples in different contexts:
- In EDC context: "...Primary identifier for EDC order lookup and joins."
- In merchant context: "...Primary key for merchant identification."
```

**4. Bank Account** (8-16 digits)
```
Detect: all values are digits, 8-16 length
Generate: "Bank account number for merchant settlement and payout."
```

**5. Column Name + Table Context**
```
status column in EDC context → "EDC order status field. Indicates current state in the order lifecycle."
name column in bank context → "Name of the merchant's bank for settlement."
date/timestamp columns → "Timestamp when..." or "Timestamp of..."
location columns → "Geographic location field derived from geocoding API."
amount columns → "Monetary amount field in IDR."
```

**6. Infer from Name (for empty/sparse columns)**
```
If column has no valid sample data (all null or no non-empty values):
- Extract core meaning from column name
- Combine with table context
- Mark as optional

Examples:
- ecom_user_id in prod_edc_order → "Ecommerce user identifier for linking with ecommerce platform orders (optional in this data)"
- coordinates in prod_edc_order → "Geographic coordinates for delivery location mapping (optional in this data)"
```

### Fallback (if nothing matches)
```
Use capitalized column name as description:
"Bank Account field"
"Postal Code field"
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
   - Business context for each table

2. **For each missing table**, fetch 10,000 rows and:
   ```python
   - Collect ALL values per column (for enumeration)
   - Sample first 5 values (for description generation)
   - Detect value format using regex patterns
   - Generate description using rules above
   - Build JSON documentation
   - Save to table_column_description/[TABLE_NAME]_doc.json
   ```

3. **Git commit** with message:
   ```
   Document [TABLE_NAMES] with AI SQL-focused descriptions
   
   - Value format detection (UUID, phone, enum, etc)
   - Descriptions optimized for query generation
   - Enumeration for low-cardinality columns
   ```

---

## Success Criteria

After documentation, verify:

✓ All columns have descriptions (never empty or "Field for X")
✓ Enum columns have `possible_values` array
✓ SDC metadata columns clearly identified
✓ Phone numbers mention "10-11 digit Indonesian"
✓ UUIDs mention "UUID v4 format"
✓ Business context set based on null %

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
