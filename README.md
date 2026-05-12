# BigQuery Table Documentation for AI SQL Assistant

> **Purpose**: Semantic column descriptions optimized for AI-driven SQL generation. Document tables automatically using Claude Code.

---

## 📋 Copy-Paste Prompt for Claude Code

**Use this prompt exactly when asking Claude Code to document tables:**

```
Document all tables in table_list.md that don't have documentation 
in table_column_description/ yet. 

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow.

**CRITICAL: Extract CREATE Query First**

For each table:
1. Run: bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.type'
2. If VIEW: Extract SQL with: bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.view.query' -r
3. If TABLE: Note it's raw source data (no SQL available)
4. Use extracted query to explain HOW each column is formed

**Apply 4-Source Semantic Logic (Priority Order):**

1. **Source 1 (Priority 1): Analyze Column Formation in CREATE Query**
   - CASE statements → explain ALL conditions and result categories
   - Aggregations (COUNT/SUM) → explain what's counted and what filters applied
   - Joins/lookups → explain table references
   - Functions → explain when/how generated
   - Raw columns → explain source table and purpose
   - Description MUST explain formation logic, not just column name

2. **Source 2 (Priority 2): Value Format Detection**
   - _sdc_* → "Singer data connector pipeline metadata"
   - UUIDs → "Unique {entity} identifier in UUID v4 format"
   - Phone (8-13 digits, starts 8) → "Phone number (10-11 digit Indonesian mobile)"
   - Timestamps → "Timestamp when {action} occurred"
   - Coordinates → "Latitude,longitude coordinate pair"
   - Enumerations (≤20 unique) → list all possible values

3. **Source 3 (Priority 3): Business Context**
   - Use table context from table_list.md
   - Credit assessment → loan/risk analysis
   - Sales/route → merchant outreach
   - Visits → engagement tracking
   - Profiles → KYC/product adoption
   - Payments → settlement/revenue

4. **Source 4 (Priority 4): Sample Data Analysis**
   - Null % → field importance (Required/Core/Common/Optional)
   - Unique values → possible_values array if ≤20
   - Example values from actual data

**JSON Requirements:**
- `semantic_source`: sql_definition, value_format, business_context, sample_data (or combination)
- `possible_values`: For enum columns (≤20 unique)
- `business_context`: Required/Core/Common/Optional based on null %
- `description`: Answer "What is this and why does it exist?"

**Validation:**
- All 10 success criteria from README (each column)
- No generic "[Field]" patterns
- SQL definitions extracted for calculated columns
- Format detection: UUID, phone, timestamp, enum identified
- Descriptions ≥40 characters (meaningful)
- semantic_source and business_context present
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
```

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
