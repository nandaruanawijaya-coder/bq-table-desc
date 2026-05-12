# CLAUDE_CODE_AUTOMATION.md (Simplified)

> **For Claude Code** - Read this when asked to document BigQuery tables. All critical logic is here; read sequentially.

---

## How to Use This Document

When asked to document tables, Claude Code will:
1. Read `table_list.md` for list of tables and context
2. Check `table_column_description/` for existing documentation
3. Document missing tables using the workflow below
4. Commit to git with summary

---

## Workflow: 4-Source Semantic Logic

For EACH undocumented table:

1. **Extract CREATE Query** (mandatory) — Get SQL from BigQuery
2. **Analyze Column Formation** (Sources 1-4) — Explain how each column is formed
3. **Generate JSON** — Save to `table_column_description/[TABLE]_doc.json`
4. **Validate** — Check all columns meet success criteria
5. **Commit** — One commit per table or per 5 tables (batch)

---

## Step 1: Extract CREATE Query (Mandatory First Step)

Every column's description comes FROM the SQL, not from guessing the column name.

```bash
# Check table type
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.type'
# Output: "VIEW" or "TABLE"

# If VIEW: Extract the SQL
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.view.query' -r > /tmp/create_query.sql

# If TABLE: Note it's raw source data (no SQL available)
```

**Why this matters:**
- VIEW: SQL shows exactly how columns are calculated (CASE, COUNT, SUM, JOIN, etc)
- TABLE: Raw source columns — use column names + business context

**Example: mee_weekly_route_plan (VIEW)**

```sql
SELECT 
  mee_id,
  COUNT(CASE WHEN product = 'PM1_EDC' THEN transaction_id END) as pm1_edc_trx,
  CASE WHEN merchant_has_edc = False THEN 'prospect' ELSE 'existing' END as edc_prospect
FROM transactions
GROUP BY mee_id
```

| Column | Formation | Meaning |
|--------|-----------|---------|
| `pm1_edc_trx` | `COUNT(CASE WHEN product='PM1_EDC'...)` | Counts ONLY PM1_EDC, excludes others |
| `edc_prospect` | `CASE WHEN merchant_has_edc=False...` | 'prospect' (no EDC) or 'existing' (has EDC) |

---

## Step 2-5: Analyze Columns Using 4 Sources (Priority Order)

For EACH column, apply these sources in order:

### Source 1 (Priority 1): SQL Definition

If column appears in SELECT clause with CASE/COUNT/SUM/JOIN/FUNCTION:

- **CASE statement** → Explain all conditions and result categories
- **COUNT/SUM/AVG** → Explain what's counted and which rows included (filters)
- **JOIN/LOOKUP** → Explain what table is referenced
- **FUNCTION** (CURRENT_TIMESTAMP, etc) → Explain when/how generated
- **Raw column** → Explain source table and meaning

**Examples:**
- `COUNT(CASE WHEN product='PM1_EDC' THEN trx_id)` → "Counts ONLY PM1_EDC products, other products excluded"
- `CASE WHEN score >= 80 THEN 'High'...` → "Risk category: High (≥80), Medium (≥50), Low (<50)"
- `CASE WHEN has_edc = False THEN 'prospect'...` → "EDC status: 'prospect' (no EDC) or 'existing' (has EDC)"

### Source 2 (Priority 2): Value Format Detection

From sample data, identify:

| Format | Detection | Description |
|--------|-----------|-------------|
| _sdc_* | Starts with _sdc_ | "Singer data connector: [pipeline tracking purpose]" |
| UUID | 36-char pattern | "Unique [entity] identifier in UUID v4 format" |
| Phone | 8-13 digits, starts 8 | "Phone number (10-11 digit Indonesian mobile)" |
| Timestamp | ISO 8601 pattern | "Timestamp when [action] occurred" |
| Coordinates | lat,long pattern | "Latitude,longitude coordinate pair" |
| Bank account | 8-16 digits | "Bank account number" |
| Enumeration | ≤20 unique values | List all possible values |

### Source 3 (Priority 3): Business Context

Add from `table_list.md` context and table purpose:
- Credit assessment → loan approval, risk analysis
- Sales/route → merchant outreach, targeting
- Visits → engagement tracking
- Merchant profile → KYC, product adoption
- Payments → settlement, revenue

### Source 4 (Priority 4): Sample Data

- **Null percentage** → Set `business_context`: Required/Core/Common/Optional
- **Enumeration** → If ≤20 unique, add `possible_values` array
- **Examples** → Extract 2-3 real values

---

## Output JSON Schema

```json
{
  "table_name": "mee_weekly_route_plan",
  "full_table_id": "ledger-fcc1e.fs_datamart.mee_weekly_route_plan",
  "total_columns": 10,
  "columns": [
    {
      "column_name": "pm1_edc_trx",
      "data_type": "INTEGER",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Weekly count of PM1_EDC product transactions only. Other payment products excluded. Calculated as COUNT(CASE WHEN product='PM1_EDC' THEN transaction_id END) per MEE per week.",
      "business_context": "Core field - >90% populated",
      "example_values": [45, 120, 67],
      "possible_values": null,
      "semantic_source": "sql_definition + sample_data"
    }
  ]
}
```

---

## Description Generation Rules (15 Semantic Categories)

Apply these patterns when generating descriptions:

**1. SDC Metadata** (_sdc_* columns)
- `_sdc_batched_at` → "Singer data connector: timestamp when batch was processed in pipeline"

**2. UUID** (Unique Identifiers)
- `order_id` → "Unique order identifier in UUID format. Primary key for EDC orders"

**3. Phone Numbers** (8-13 digits, starts 8)
- `phone_number` → "Phone number (10-11 digit Indonesian mobile). Primary identifier for merchant lookup"

**4. Bank Accounts** (8-16 digits)
- `settlement_account` → "Bank account number for merchant settlement and payout"

**5. Geographic** (Addresses, provinces, coordinates)
- `province` → "State or province level administrative division for geographic segmentation"
- `lat_long` → "Latitude,longitude coordinate pair for precise merchant location"

**6. Timestamps**
- `created_at` → "Timestamp when merchant account was created. Indicates onboarding date"
- `CURRENT_TIMESTAMP()` → "Timestamp when view was materialized. Generated at query execution, NOT historical"

**7. Business Metrics & Counts**
- `estimated_customers_per_day` → "Estimated daily customer count. Indicates business volume and sales potential"
- `transaction_count` → "Count of transactions completed. Key metric for EDC usage"

**8. Boolean Flags** (is_*, has_*, *_flag)
- `has_bri_edc` → "Boolean indicating merchant owns BRI EDC machine. Used for product penetration analysis"
- `is_active` → "Boolean indicating if sales executive is actively engaged"

**9. Status & Lifecycle**
- `status` → "Order processing stage: Draft, Unassigned, Active, Completed, Cancelled"
- `kyc_tier` → "KYC verification tier. Indicates compliance and verification level"

**10. Names & Identifiers**
- `mse_name` → "Name of Merchant Success Executive assigned to territory. Used for sales team accountability"

**11. Product Classification**
- `business_type` → "Business operation type: Retail, Food, Services, etc. Used for merchant segmentation"

**12. Loan & Financial**
- `loan_ownership` → "Indicates if merchant has active loan with BukuWarung"
- `final_score` → "Merchant credit score (0-1 scale). Determines loan approval eligibility"

**13. Metadata & Attachments**
- `metadata` → "Additional structured data for order. Contains supplementary information"

**14. Referral & Partnership**
- `referee_name` → "Name of referrer. Used for partnership tracking and attribution"

**15. Team Hierarchy**
- `current_mse_hoa` → "Head of Area assigned to merchant. Indicates area management hierarchy"
- `area` → "Geographic area region (Java 1-3, Sumatera 1-3). Used for MSE organization"

---

## Success Criteria (Per Column)

Every column MUST pass ALL checks:

| Criteria | ✅ Good | ❌ Bad |
|----------|---------|--------|
| **Explains WHAT** | "Counts ONLY PM1_EDC products, other products excluded" | "Count of transactions" |
| **Formation Logic** | Includes CASE/COUNT/SUM/FILTER details from SQL | Generic naming without logic |
| **Value Format** | "UUID v4 format" OR "Phone (10-11 digit)" OR "Timestamp when..." | "Some identifier" OR "A date" |
| **Business Context** | "Used for loan approval determination" | "Score field" |
| **Length** | ≥40 characters (meaningful) | <40 chars (too generic) |
| **Enum Values** | `possible_values: ["Active", "Completed", ...]` | Missing for status columns |
| **business_context** | "Required field" / "Core" / "Common" / "Optional" | Null or missing |
| **semantic_source** | "sql_definition + value_format + ..." | Null or missing |
| **No Generic Patterns** | Specific explanation | "[ColumnName] field" |
| **SDC Columns** | "Singer data connector: [purpose]" | Treated as regular field |

---

## Validation Commands

Run these after generating JSON (all should return EMPTY):

```bash
# Check 1: Empty descriptions
jq '.columns[] | select(.description == null or .description == "") | .column_name' FILE.json

# Check 2: Too short (<40 chars)
jq '.columns[] | select((.description | length) < 40) | .column_name' FILE.json

# Check 3: Generic "[Field]" patterns
jq '.columns[] | select(.description | test("field$|field for")) | .column_name' FILE.json

# Check 4: Missing business_context
jq '.columns[] | select(.business_context == null) | .column_name' FILE.json

# Check 5: Missing semantic_source
jq '.columns[] | select(.semantic_source == null) | .column_name' FILE.json

# Check 6: Enum columns without possible_values
jq '.columns[] | select((.description | test("status|categories")) and (.possible_values == null)) | .column_name' FILE.json
```

---

## Instructions for Data Team

### Add Tables to table_list.md
```markdown
- ledger-fcc1e.dataset.table_name
One sentence describing what this table contains.
```

### Ask Claude Code
```
Document all tables in table_list.md that don't have documentation 
in table_column_description/ yet. Follow CLAUDE_CODE_AUTOMATION.md.
```

### Claude Code Will Do This
1. Read table_list.md (identify undocumented tables)
2. For each table:
   - Extract CREATE query (if VIEW)
   - Query 10,000 sample rows
   - Analyze each column using 4 sources
   - Generate JSON documentation
   - Validate all columns
   - Commit to git
3. Report completion

**Time: ~10 minutes per table**

---

## FAQ

**Q: What if the table is a VIEW?**
A: Extract the SQL using `bq show --format=json ... | jq '.view.query'`. Analyze how each column is formed in the SELECT clause.

**Q: What if it's a raw TABLE?**
A: No SQL available. Use column names + business context from table_list.md + format detection from sample data.

**Q: How do I know if a description needs SQL context?**
A: Check `semantic_source`. If it contains `sql_definition`, the description MUST explain CASE/COUNT/SUM/FILTER logic from the SQL.

**Q: What if I document a table and later find it's actually a VIEW with SQL?**
A: Delete the JSON file and re-run documentation. Claude Code will extract the SQL and produce richer descriptions.

**Q: Can I document multiple tables at once?**
A: Yes. Add all to table_list.md and ask Claude Code once. It will process batches of 5 in parallel for 3x speedup.

**Q: How much faster is batch processing?**
A: Single table: 10 min. Five tables serial: 50 min. Five tables parallel: 12 min.

---

## Data Sources

- **table_list.md** — List of tables to document (add new ones here)
- **table_column_description/*.json** — Generated documentation
- **.claude/pattern_cache.json** — Cached patterns for reuse (auto-managed)

---

## Reference

- Obra Superpowers: https://github.com/obra/superpowers
- BigQuery Documentation: https://cloud.google.com/bigquery/docs
