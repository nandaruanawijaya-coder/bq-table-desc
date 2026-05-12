# BigQuery Table Documentation for AI SQL Assistant

> **Purpose**: Semantic column descriptions optimized for AI-driven SQL generation. Document tables automatically using Claude Code.

---

## 📋 Copy-Paste Prompt for Claude Code

**Use this prompt exactly when asking Claude Code to document tables:**

```
Document all tables in table_list.md that don't have documentation 
in table_column_description/ yet. 

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow and Obra Superpowers methodology.

**Obra Superpowers Framework:**
- Design: SQL definition is the priority source for descriptions (not column names)
- Systematic Process: Apply 4-source logic in strict priority order
- Data-Driven: Extract real patterns from 10,000 sample rows
- Verification: Enforce validation rules on every column (no generic descriptions)

**CRITICAL: Extract Creation Query First (PRIMARY Source of Truth)**

The creation query (CREATE TABLE or CREATE TABLE AS SELECT) is the authoritative source for understanding how columns were formed. It answers all questions about column origin, transformation, aggregation, and filtering.

For each table, extract in this priority order:

```bash
# Step 1: For VIEWs - Extract SQL definition
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.view.query' -r

# Step 2: For TABLEs - Query INFORMATION_SCHEMA to find ORIGINAL creation query
bq query --use_legacy_sql=false "
  SELECT creation_time, query, statement_type
  FROM \`ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT\`
  WHERE statement_type IN ('CREATE_TABLE', 'CREATE_TABLE_AS_SELECT')
    AND destination_table.table_id = 'TABLE_NAME'
    AND destination_table.dataset_id = 'DATASET_NAME'
  ORDER BY creation_time ASC LIMIT 1
"

# Step 3: If original creation query not found, find MOST RECENT transformation
bq query --use_legacy_sql=false "
  SELECT creation_time, query, statement_type
  FROM \`ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT\`
  WHERE referenced_tables LIKE '%DATASET_NAME.TABLE_NAME%'
    AND statement_type IN ('INSERT', 'CREATE_TABLE_AS_SELECT', 'UPDATE')
  ORDER BY creation_time DESC LIMIT 1
"

# Step 4: If no query found, check metadata for hints
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '{description, labels}' -r
```

**What the creation query reveals:**
- **Base columns**: Passed through directly from source table
- **Derived columns**: CASE statements with thresholds, COUNT/SUM aggregations, CAST/CONCAT transformations
- **Source tables**: Which tables are joined or unioned
- **Filters**: WHERE conditions that reduce row count
- **Aggregations**: GROUP BY logic and what's counted/summed
- **Deduplication**: DISTINCT, ROW_NUMBER partitioning, or duplicate handling

**Apply 4-Source Semantic Logic (Priority Order):**

1. **Source 1 (Priority 1): SQL Definition (from creation query)**
   - **CASE statements** → explain ALL conditions and thresholds (e.g., "APPROVED if score ≥0.75, REJECTED if <0.75")
   - **Aggregations** → explain what's counted and filters (e.g., "COUNT ONLY PM1_EDC products, others excluded")
   - **Priority logic** → explain fallback order (e.g., "Priority: verification_date → submission_date → updated_at")
   - **Window functions** → explain deduplication or ranking (e.g., "Latest record per merchant by date")
   - **Threshold derivation** → explain score/value thresholds
   - **UNION ALL** → note which data sources are combined
   - **Transformations** → CAST, CONCAT, string functions, date math
   - **Joins** → explain which tables are combined and how

2. **Source 2 (Priority 2): Value Format Detection + Column Name Semantics**
   - **Value formats** (from sample data): _sdc_* → "Singer data connector...", UUIDs → "UUID v4 format", Phone → "10-11 digit Indonesian mobile", Timestamps → "Timestamp when...", Coordinates → "Latitude,longitude pair"
   - **Column name patterns** (if no SQL found): has_*, is_* → "Boolean indicating...", *_name → "Name of...", *_at/*_date → "Timestamp when...", *_count/*_total → "Count of...", *_score → "Score for...", *_id/*_number → "Unique identifier...", *_status/*_type → "Classification of..."
   - **Enumerations**: If ≤20 unique values, list all in possible_values array

3. **Source 3 (Priority 3): Business Context**
   - Use table context from table_list.md
   - Credit assessment → loan approval, risk analysis, KYC verification
   - Sales/route → merchant outreach, territory assignment, targeting
   - Visits → engagement tracking, sales activity
   - Profiles → product adoption, KYC status, merchant verification
   - Payments → settlement, revenue tracking, cash flow

4. **Source 4 (Priority 4): Sample Data Analysis**
   - Null percentage → Set business_context (Required 0% null, Core >90%, Common >50%, Optional <50%)
   - Enumeration → If ≤20 unique, add possible_values array with all values
   - Example values → Extract 2-3 real values from actual data

**JSON Requirements:**
- `semantic_source`: sql_definition, value_format, business_context, sample_data (or combination)
- `possible_values`: For enum columns (≤20 unique)
- `business_context`: Required/Core/Common/Optional based on null %
- `description`: Answer "What is this and why does it exist?"

**Validation (All Columns MUST PASS):**
- ✅ Explains WHAT: "Counts ONLY PM1_EDC, others excluded" (not "Count of transactions")
- ✅ Formation logic: If SQL found → explain CASE/COUNT/JOIN/aggregation details. If no SQL → column semantics + business meaning
- ✅ Value format: "UUID v4", "Phone (10-11 digit)", "Timestamp when..." (detected from sample data)
- ✅ Business context: "Used for loan approval", "Tracks merchant volume" (not generic "Score field" or "field for...")
- ✅ Length: ≥40 characters (meaningful, not <40 too generic)
- ✅ Enum values: possible_values array with all ≤20 unique values (e.g., ["APPROVED", "REJECTED"])
- ✅ business_context field: "Required/Core/Common/Optional" (not null)
- ✅ semantic_source field: Show what sources were used (e.g., "sql_definition + value_format + business_context")
- ✅ No data-type patterns: NOT "Text or string value", "Integer numeric", "Name or text identifier"
- ✅ SDC columns: "Singer data connector: [purpose]" (not treated as regular fields)
- ✅ Creation query analyzed: If SQL found, description must reference it (transformation logic, aggregation details, etc)
```

---

## ⚡ Quick Start (3 Steps)

1. **Edit `table_list.md`**
   ```markdown
   - ledger-fcc1e.dataset.your_table
   Brief description of what table contains.
   ```

2. **Open Claude Code** in VS Code

3. **Copy the prompt above and ask Claude Code**

Done! ✅ Claude Code will:
- Extract CREATE queries from BigQuery
- Query 10,000 sample rows
- Analyze columns using 4-source logic
- Generate JSON documentation
- Validate all columns
- Commit to git

---

## 📊 Current Status

| Aspect | Status |
|--------|--------|
| **Tables Documented** | 8 (532 columns) |
| **Tables Pending** | 1 (payments_ssot) |
| **Quality** | 4-source semantic descriptions |
| **All descriptions** | ≥40 chars, explain business meaning |

**Documented Tables:**
- `location_gmaps_static` (16 cols) — Geocoding coordinates
- `mapping_area_mse_opentable` (10 cols) — MSE hierarchy
- `ms_merchant_profiling_ssot` (107 cols) — Merchant profile
- `prod_edc_order` (36 cols) — EDC order lifecycle
- `mee_weekly_route_plan` (40 cols) — MEE route planning
- `credit_memo` (75 cols) — Loan assessment
- `ms_form_hiring_and_active` (170 cols) — Hiring process
- `retail_ph_visit_ssot` (78 cols) — Visit tracking

---

## 🎯 How It Works

### For Data Team
1. Add tables to `table_list.md`
2. Copy the prompt above and ask Claude Code
3. Claude Code documents everything automatically

### For Claude Code
- Read `CLAUDE_CODE_AUTOMATION.md` (306 lines, complete workflow)
- Extract CREATE query from BigQuery
- Apply 4-source logic to each column
- Generate semantic descriptions
- Validate and commit

---

## 📁 Repository Structure

```
├── README.md (this file)
├── CLAUDE_CODE_AUTOMATION.md (workflow reference)
├── CONTRIBUTING.md (quick start guide)
├── table_list.md (tables to document — EDIT THIS)
├── table_column_description/ (generated documentation)
│   ├── [table_name]_doc.json (for each table)
│   └── ...
└── table_list/ (sample data for validation)
    ├── [table_name].json (10k rows)
    └── ...
```

---

## ✅ Success Criteria for Each Column

Every column MUST pass ALL 10 checks:

| # | Criteria | ✅ Good | ❌ Bad |
|---|----------|---------|--------|
| 1 | **Explains WHAT** | "Counts ONLY PM1_EDC, others excluded" | "Count of transactions" |
| 2 | **Formation Logic** | Includes CASE/COUNT/SUM details | Missing logic explanation |
| 3 | **Value Format** | "UUID v4" OR "Phone" OR "Timestamp when..." | "Some identifier" |
| 4 | **Business Context** | "Used for loan approval" | "Score field" |
| 5 | **Length** | ≥40 characters | <40 chars |
| 6 | **Enum Values** | `possible_values: ["Active", "Draft"]` | Missing for status cols |
| 7 | **business_context** | "Required/Core/Common/Optional" | Null/missing |
| 8 | **No Generic** | Specific explanation | "[ColumnName] field" |
| 9 | **semantic_source** | "sql_definition + value_format" | Null/missing |
| 10 | **SDC Columns** | "Singer data connector: [purpose]" | Treated as regular |

---

## 🔍 Validation Commands

Run after documentation (all should return EMPTY):

```bash
# Check 1: No empty descriptions
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

# Check 7: Generic data-type descriptions (NEW)
jq '.columns[] | select(.description | test("^(Text or string|Integer numeric|Numeric value|Name or text) value")) | .column_name' FILE.json
```

**All 7 checks should return EMPTY.** If check 7 catches columns, they need semantic descriptions (column meaning + business context), not just data types.

---

## 📝 Output Example

```json
{
  "table_name": "prod_edc_order",
  "total_columns": 36,
  "columns": [
    {
      "column_name": "order_id",
      "data_type": "STRING",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Unique order identifier in UUID format. Primary key for EDC orders. Used for tracking and joins",
      "business_context": "Required field - always populated",
      "example_values": ["31ca7df4-4648..."],
      "possible_values": null,
      "semantic_source": "sql_definition + value_format"
    },
    {
      "column_name": "status",
      "data_type": "STRING",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Order lifecycle stage. Categories: Draft → Unassigned → Active → Completed/Cancelled",
      "business_context": "Core field - >90% populated",
      "example_values": ["Active", "Completed"],
      "possible_values": ["Active", "Cancelled", "Completed", "Draft", "Unassigned"],
      "semantic_source": "sql_definition + sample_data"
    }
  ]
}
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Overview and quick start (this file) |
| **CLAUDE_CODE_AUTOMATION.md** | Complete workflow reference (read by Claude Code) |
| **CONTRIBUTING.md** | Quick start for data team |
| **table_list.md** | List of tables to document (EDIT THIS) |

---

## ❓ FAQ

**Q: How do I add a new table?**  
A: Add to `table_list.md` with description, then use the prompt above.

**Q: Can I document multiple tables at once?**  
A: Yes. Add all to `table_list.md`, use the prompt once. Processes 5 in parallel = 3x faster.

**Q: What if table is already documented?**  
A: Claude Code skips it automatically.

**Q: How long does one table take?**  
A: ~10 minutes per table. 10 tables in ~30 minutes (parallel).

**Q: What if descriptions are poor?**  
A: Delete the JSON file, ask Claude Code again. It will regenerate.

**Q: How is this different from manual?**  
A: Uses 4 sources (table context + SQL + schema + data). Manual takes 2-3 hours/table. This takes 10 minutes.

**Q: What if table schema changes?**  
A: Remove from `table_column_description/`, keep in `table_list.md`, ask Claude Code to re-document.

---

## 🚀 Typical Workflow

```
1. Edit table_list.md
   - ledger-fcc1e.analytics.user_profiles
   - ledger-fcc1e.analytics.transactions
   
2. Copy the prompt above
3. Ask Claude Code
4. Wait ~30 minutes
5. Review and push to GitHub
```

---

## 🎓 Using the Documentation

```bash
# Find all UUID columns
jq '.columns[] | select(.description | test("UUID"))' table_column_description/[table]_doc.json

# List all status columns with possible values
jq '.columns[] | select(.possible_values != null)' table_column_description/[table]_doc.json

# Check column count
jq '.total_columns' table_column_description/[table]_doc.json
```

---

## ✨ Key Features

✅ **Fast** — 10 min/table  
✅ **Automatic** — Claude Code handles everything  
✅ **Smart** — Skips already-documented tables  
✅ **Scalable** — Document 10+ tables at once  
✅ **Quality** — Validation at each step  

---

**Status**: Production Ready ✅  
**Last Updated**: May 12, 2026  
**GitHub**: https://github.com/nandaruanawijaya-coder/bq-table-desc
