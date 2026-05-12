# BigQuery Table Documentation for AI SQL Assistant

> **Purpose**: Create rich, semantic column descriptions optimized for AI-driven SQL query generation. Document BigQuery tables automatically using Claude Code.

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Add Table to `table_list.md`

```markdown
# Tables to Document

- ledger-fcc1e.dataset.your_new_table
- ledger-fcc1e.dataset.another_table
```

### 2️⃣ Open Claude Code in VS Code

Click the Claude Code icon in the sidebar

### 3️⃣ Ask Claude Code

```
Document all tables in table_list.md that don't have 
documentation in table_column_description/ yet.

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow with 
4-source semantic logic (SQL definition → format → context → data).
```

Or use the full prompt from the **"Copy-Paste Prompt for Claude Code"** section below for complete validation steps.

**Done!** ✅ Claude Code will:
- Query 10,000 rows from each missing table
- Analyze all columns
- Create JSON documentation
- Commit to git
- Report completion

---

## 📊 Current Status

| Tables | Columns | Sample Rows | Description Quality | Status |
|--------|---------|-------------|---------------------|--------|
| **8 documented** | **532** | **67,086+** | **4-source semantic** | ✅ **Production Ready** |
| **1 undocumented** | **28+** | — | pending | 🔄 In Queue |

**Tables with 4-Source Semantic Descriptions:**
- `location_gmaps_static` (16 cols) — Geocoding data with coordinates and administrative divisions
- `mapping_area_mse_opentable` (10 cols) — MSE team organizational hierarchy and territory mapping
- `ms_merchant_profiling_ssot` (107 cols) — Comprehensive merchant profile with business metrics and product ownership
- `prod_edc_order` (36 cols) — EDC order lifecycle with merchant details and delivery metadata
- `mee_weekly_route_plan` (40 cols) — Weekly MEE route planning and visit tracking
- `credit_memo` (75 cols) — Merchant loan assessment and credit evaluation
- `ms_form_hiring_and_active` (170 cols) — MSE/RSE hiring process and activity tracking
- `retail_ph_visit_ssot` (78 cols) — Retail Sales Executive visit tracking in Philippines

**Table Pending Documentation:**
- `payments_ssot` (28+ cols) — Payment products, transaction settlement, revenue tracking (queued)

**Description Quality**: All 532 columns have 4-source semantic descriptions:
- ✓ **Table Context** — Business meaning from table_list.md
- ✓ **SQL Definition** — Transformation logic from BigQuery metadata
- ✓ **Schema & Data** — Value formats (UUID, phone, enum, metric) from actual samples
- ✓ **Semantic Rules** — Business purpose and usage context
- ✓ **Quality Guarantee** — Zero generic "[Field]" patterns, all descriptions ≥30 chars
- ✓ **Enumeration** — Low-cardinality columns (<20 unique values) list all possible values

---

## 📁 Repository Structure

```
├── 📄 README.md (Overview - this file)
├── 📄 CLAUDE_CODE_AUTOMATION.md (Reference guide for Claude Code automation)
├── 📄 CONTRIBUTING.md (Guide for data team - quick reference)
├── 📄 table_list.md (List of tables to document - EDIT THIS FILE)
│
├── 📁 table_column_description/ (8 tables, 432 columns total)
│   ├── location_gmaps_static_doc.json (16 columns)
│   ├── mapping_area_mse_opentable_doc.json (10 columns)
│   ├── ms_merchant_profiling_ssot_doc.json (107 columns)
│   ├── prod_edc_order_doc.json (36 columns)
│   ├── mee_weekly_route_plan_doc.json (40 columns)
│   ├── credit_memo_doc.json (75 columns)
│   ├── ms_form_hiring_and_active_doc.json (170 columns)
│   └── retail_ph_visit_ssot_doc.json (78 columns)
│
└── 📁 table_list/ (Sample data for validation)
    ├── location_gmaps_static.json (10,000 rows)
    ├── mapping_area_mse_opentable.json (1,086 rows)
    ├── ms_merchant_profiling_ssot.json (10,000 rows)
    ├── prod_edc_order.json (10,000 rows)
    ├── mee_weekly_route_plan.json (10,000 rows)
    ├── credit_memo.json (5,542 rows)
    ├── ms_form_hiring_and_active.json (10,000 rows)
    └── retail_ph_visit_ssot.json (1,551 rows)
```

**Key Files:**
- **table_list.md** — Active list of tables to document (data team edits this)
- **CLAUDE_CODE_AUTOMATION.md** — Reference guide for Claude Code (automated documentation generation)
- **CONTRIBUTING.md** — Quick start guide for data team

---

## 🎯 How It Works

### For Data Team

1. **Maintain list** - Add tables to `table_list.md`
2. **Use Claude Code** - Ask it to document missing tables
3. **Claude Code does**:
   - ✅ Reads table_list.md
   - ✅ Checks what's already documented
   - ✅ Processes only new tables
   - ✅ Queries 10,000 rows
   - ✅ Analyzes columns
   - ✅ Generates documentation
   - ✅ Commits to git

### For Claude Code

Claude Code reads **CLAUDE_CODE_AUTOMATION.md** which contains:
- Complete 8-step workflow
- Python script template
- Column enhancement rules
- Validation procedures
- Error handling matrix
- Git procedures

No additional prompts needed - it's fully self-documented!

---

## 📚 Documentation Files

| File | Audience | Purpose |
|------|----------|---------|
| **README.md** | Data Team | Overview and quick reference (this file) |
| **table_list.md** | Data Team | Active list of tables to document — **EDIT THIS** |
| **CONTRIBUTING.md** | Data Team | Step-by-step quick start guide |
| **CLAUDE_CODE_AUTOMATION.md** | Claude Code | Complete automation reference with description rules and examples |

**For Data Team**: Start with this README, then edit `table_list.md`, then ask Claude Code to document  
**For Claude Code**: Read `CLAUDE_CODE_AUTOMATION.md` for complete workflow instructions

---

## 🚀 Typical Workflow

### Add Multiple Tables at Once

```markdown
# table_list.md

- ledger-fcc1e.analytics.user_profiles
- ledger-fcc1e.analytics.transaction_history
- ledger-fcc1e.analytics.merchant_metrics
```

Ask Claude Code once:
```
Document all tables in table_list.md that don't have 
documentation yet. Follow CLAUDE_CODE_AUTOMATION.md.
```

Claude Code will:
- Document all 3 tables
- Commit each with proper message
- Report completion

**Time**: ~30 minutes for 3 tables instead of 2+ hours manually

---

## 📋 Copy-Paste Prompt for Claude Code

Use this exact prompt when asking Claude Code to document tables:

```
Document all tables in table_list.md that don't have documentation 
in table_column_description/ yet. 

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow.

**Apply the 4-Source Semantic Logic (Priority Order):**

1. **Source 1 (Priority 1): SQL Definition**
   - Extract CASE statements → explain conditions and categories
   - Extract aggregations (COUNT/SUM) → explain what's being counted and filters
   - Extract joins/lookups → explain table references and relationships
   - For raw columns → explain source table and business purpose
   
2. **Source 2 (Priority 2): Value Format Detection**
   - _sdc_* columns → "Singer data connector pipeline metadata"
   - UUID patterns → "Unique {entity} identifier in UUID v4 format"
   - Phone numbers (8-13 digits, starts with 8) → "Phone number (10-11 digit Indonesian mobile)"
   - Timestamps → "Timestamp when {action} occurred"
   - Coordinates (lat,long) → "Latitude,longitude coordinate pair"
   - Enumerations (≤20 unique values) → list all possible values
   
3. **Source 3 (Priority 3): Business Context**
   - Apply table context from table_list.md
   - Use domain: credit assessment → loan/risk, sales/route → merchant outreach, 
     visits → engagement tracking, profiles → KYC/product adoption, payments → settlement
   
4. **Source 4 (Priority 4): Sample Data Analysis**
   - Calculate null percentage → determine field importance (Required/Core/Common/Optional)
   - Extract enumeration values → add to possible_values array if ≤20 unique
   - Get example values from actual data

**For JSON Output:**
- Add `semantic_source` field (values: sql_definition, value_format, business_context, sample_data, or combination)
- Include `possible_values` array for low-cardinality columns
- Set `business_context` based on null percentage
- Ensure all descriptions answer: "What is this and why does it exist?"

**Scaling Optimizations (for 10+ tables):**
- Use pattern caching to reuse UUID/phone/timestamp patterns across tables
- Batch process in groups of 5 tables in parallel
- Skip re-querying unchanged schemas (incremental updates)
- Commit 1 per 5 tables (not per table)

---

**✓ TESTING CHECKLIST** (verify all before committing)

- [ ] All columns have descriptions (no [TODO] or empty descriptions)
- [ ] No generic patterns ("Field for X", "[ColumnName] field") remain
- [ ] SQL definitions extracted for calculated columns (CASE, COUNT, SUM, joins)
- [ ] Format detection worked: UUID, phone, timestamps, coordinates identified
- [ ] Low-cardinality columns have possible_values arrays (≤20 unique)
- [ ] All descriptions are ≥30 characters (meaningful, not generic)
- [ ] semantic_source field present in all columns
- [ ] JSON files are valid (use jq to verify)
- [ ] Git commits created with descriptive messages
- [ ] Pattern cache updated (.claude/pattern_cache.json) for reuse

---

**✓ SUCCESS CRITERIA FOR EACH COLUMN**

Description must answer: **"What is this and why does it exist?"**

Examples of ✅ **GOOD** descriptions:
- "Unique order identifier in UUID format. Primary key for EDC orders. Used for order tracking and joins"
- "Phone number (10-11 digit Indonesian mobile). Primary merchant identifier for order lookup"
- "Order lifecycle status (Draft, Unassigned, Active, Completed, Cancelled). Indicates order processing stage"
- "Estimated daily customer count for merchant. Indicates business volume and sales potential"
- "Timestamp when Singer data connector batch was processed in the pipeline"
- "Credit risk category from Pefindo score: High (≥80), Medium (≥50), Low (<50). Used for loan approval decisions"

Examples of ❌ **BAD** descriptions to avoid:
- "Order Id field"
- "Phone field"
- "Status field"
- "Estimated Customers Per Day field"
- "Timestamp field"
- "Hasbriedc field"

---

**✓ VALIDATION COMMANDS**

Run these after documentation to verify quality:

Check for generic descriptions (should return nothing):
\`\`\`bash
jq '.columns[] | select(.description | test("^[A-Z][a-z]+ field$|field for")) | .column_name' \
  table_column_description/[table_name]_doc.json
\`\`\`

Check description length (should have few/none <30 chars):
\`\`\`bash
jq '.columns[] | select(.description | length < 30) | {name: .column_name, len: (.description | length)}' \
  table_column_description/[table_name]_doc.json
\`\`\`

Verify semantic_source is present (should return nothing):
\`\`\`bash
jq '.columns[] | select(.semantic_source == null or .semantic_source == "") | .column_name' \
  table_column_description/[table_name]_doc.json
\`\`\`

Check enumeration values:
\`\`\`bash
jq '.columns[] | select(.possible_values != null) | {name: .column_name, count: (.possible_values | length)}' \
  table_column_description/[table_name]_doc.json | head -20
\`\`\`

Verify JSON validity:
\`\`\`bash
jq '.' table_column_description/[table_name]_doc.json > /dev/null && echo "✅ Valid JSON"
\`\`\`

---

**✓ QUALITY REVIEW CHECKLIST** (before committing)

- [ ] Read 5 random column descriptions (ensure they explain business meaning, not just naming)
- [ ] Check 3 status/enum columns have possible_values listed
- [ ] Verify 2 timestamp columns mention when/why the timestamp is recorded
- [ ] Check if any ID columns are described as UUID/phone/identifier
- [ ] Review git log to see commit messages include "4-source semantic" + sources combined
- [ ] Verify pattern cache was updated (check .claude/pattern_cache.json exists)
- [ ] Git status is clean (all changes committed)
- [ ] Ready to push to GitHub for review

Report completion when all criteria are met! 🎉
```

---

## 🎯 Description Quality: Why This Matters for AI

All 169 columns now have **semantic descriptions** that explain business meaning, not just field names. This helps AI SQL assistants write better queries.

### Examples of Enhanced Descriptions

**Before** (Generic):
```
"Yearofbirth field"
"Estimatedcustomersperday field"
"Province field"
```

**After** (Semantic & Explanatory):
```
"Year merchant owner was born. Used for KYC demographic verification and merchant profiling"
"Estimated daily customer count for the merchant. Indicates business volume and sales potential"
"State or province level administrative division for merchant location and geographic segmentation"
```

### What Makes Descriptions Effective

✅ **Answer: "What is this and why does it exist?"**
```
Good: "Estimated daily customer count. Indicates business volume and sales potential"
Bad: "Estimatedcustomersperday field"
```

✅ **Include usage context**
```
Good: "Boolean indicating if merchant has active BRI EDC machine. Used for product penetration analysis"
Bad: "Hasbriedc field"
```

✅ **Identify value formats**
```
Good: "Phone number (10-11 digit Indonesian mobile). Primary identifier for order lookup"
Bad: "Phone field"
```

✅ **Explain business relationships**
```
Good: "Name of Merchant Success Executive assigned to merchant territory. Used for sales team assignment and accountability"
Bad: "MSE name field"
```

---

## 📋 What Gets Created

For each table, Claude Code creates:

**1. Documentation File** (`table_column_description/[table_name]_doc.json`)
```json
{
  "table_name": "prod_edc_order",
  "full_table_id": "ledger-fcc1e.db_accounting.prod_edc_order",
  "total_columns": 36,
  "sample_rows_analyzed": 10000,
  "columns": [
    {
      "column_name": "order_id",
      "data_type": "STRING",
      "nullable": true,
      "null_percentage": 0.0,
      "description": "Unique order identifier in UUID format. Primary key for EDC order. Used for order tracking and joins",
      "business_context": "Required field - always populated",
      "example_values": ["31ca7df4-4648-41c1-bc8e-9bf25c628e16"],
      "possible_values": null
    },
    {
      "column_name": "status",
      "data_type": "STRING",
      "nullable": true,
      "null_percentage": 0.0,
      "description": "Order lifecycle status (Draft, Unassigned, Active, Completed, Cancelled). Indicates order processing stage",
      "business_context": "Required field - always populated",
      "example_values": ["Unassigned", "Active", "Completed"],
      "possible_values": ["Active", "Cancelled", "Completed", "Draft", "Rejected", "Unassigned"]
    }
  ]
}
```

**Key Features:**
- `description` — Semantic explanation of business meaning (not just field naming)
- `business_context` — Why this field matters (Required/Core/Common/Optional based on null percentage)
- `possible_values` — Enum values for low-cardinality columns (helps AI understand valid values)
- `example_values` — Real sample data from 10,000 rows analyzed

**2. Sample Data File** (`table_list/[table_name].json`)
- 10,000 rows of actual BigQuery data
- Supports data quality analysis
- Helps validate documentation

**3. Git Commit**
- Automatic commit with descriptive message
- Ready to push to GitHub
- Can be reviewed before merging

---

## ✨ Key Features

✅ **Fast** - ~10 minutes per table with Claude Code  
✅ **Automatic** - Claude Code follows automation guide  
✅ **Smart** - Skips tables already documented  
✅ **Scalable** - Document 10+ tables at once  
✅ **Quality** - Validation at each step  
✅ **Consistent** - All tables follow same format  

---

## 🎓 Using the Documentation

### View Table Structure

```bash
# See column names and types
jq '.columns[] | {name: .column_name, type: .data_type}' \
  table_column_description/[table_name]_doc.json
```

### Check Sample Data

```bash
# View first 5 rows
jq '.[0:5]' table_list/[table_name].json
```

### Search for Column

```bash
# Find columns mentioning "user"
jq '.columns[] | select(.column_name | contains("user"))' \
  table_column_description/[table_name]_doc.json
```

---

## ✅ Testing & Validation

After Claude Code documents tables, verify quality using these checks:

### Quick Quality Check (5 minutes)

**1. Check for generic descriptions:**
```bash
# Should return NOTHING - if it returns columns, quality is poor
jq '.columns[] | select(.description | test("^[A-Z][a-z]+ field$")) | .column_name' \
  table_column_description/[table_name]_doc.json
```

**2. Spot-check 5 random descriptions:**
```bash
jq '.columns[0:5] | .[] | {name: .column_name, desc: .description}' \
  table_column_description/[table_name]_doc.json
```
✓ Each description should be 30+ characters  
✓ Each should explain business meaning, not just naming

**3. Verify JSON is valid:**
```bash
jq '.' table_column_description/[table_name]_doc.json > /dev/null && echo "✅ Valid JSON"
```

**4. Check enumeration for status columns:**
```bash
jq '.columns[] | select(.column_name | test("status|type|state")) | {name: .column_name, values: .possible_values}' \
  table_column_description/[table_name]_doc.json
```
✓ Status/type columns should have possible_values listed

### Comprehensive Validation (15 minutes)

**5. Count description quality:**
```bash
# Count columns with good descriptions (>50 chars)
jq '[.columns[] | select(.description | length > 50)] | length' \
  table_column_description/[table_name]_doc.json

# Out of total
jq '.total_columns' table_column_description/[table_name]_doc.json
```
✓ Target: 90%+ of descriptions should be >50 characters

**6. Verify all required fields:**
```bash
# Check for null descriptions or missing fields
jq '.columns[] | select(.description == null or .description == "" or .business_context == null) | .column_name' \
  table_column_description/[table_name]_doc.json
```
✓ Should return: nothing (all columns must have descriptions)

**7. Sample data validation:**
```bash
# Verify sample data exists and has rows
jq 'length' table_list/[table_name].json
```
✓ Should be >100 rows

---

## 📞 Common Questions

**Q: How do I add a new table?**  
A: Add it to `table_list.md` with a brief business context, then copy-paste the Claude Code prompt above.

**Q: What if table is already documented?**  
A: Claude Code checks and skips it automatically.

**Q: Can I document multiple tables at once?**  
A: Yes! Add them all to `table_list.md`, use the prompt once.

**Q: How do I know if documentation is good quality?**  
A: Run the testing checks above. All columns should have descriptions ≥30 chars, no generic "[Field]" patterns.

**Q: What if descriptions are poor quality?**  
A: Delete the documentation file from `table_column_description/` and ask Claude Code again with the prompt. It will regenerate with better quality.

**Q: Do I need to manually edit documentation?**  
A: Only for final polish. Claude Code creates good documentation automatically.

**Q: How is this different from manual documentation?**  
A: This uses 4 sources (table context + SQL + schema + data) to generate descriptions. Manual would take 2-3 hours per table. This takes 10 minutes.

---

## 🔄 Update Workflow

When table schema changes:

1. Remove from `table_column_description/` folder
2. Keep it in `table_list.md`
3. Ask Claude Code to re-document it
4. It will create fresh documentation with latest schema

---

## 📖 For More Information

- **Manual Process**: See `CONTRIBUTING.md`
- **Automation Details**: See `CLAUDE_CODE_AUTOMATION.md`
- **Tables to Document**: Edit `table_list.md`

---

## 🎯 Next Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/nandaruanawijaya-coder/bq-table-desc.git
   cd bq-table-desc
   ```

2. **Add tables to document**
   ```bash
   vim table_list.md  # Add your table IDs
   ```

3. **Use Claude Code**
   - Open in VS Code
   - Ask Claude to follow CLAUDE_CODE_AUTOMATION.md
   - Provide table_list.md path

4. **Review & Push**
   ```bash
   git push origin main  # or create PR
   ```

---

**Last Updated**: 2026-05-06  
**Status**: Production Ready ✅  
**Description Quality**: Enhanced with semantic context for all 169 columns  
**GitHub**: https://github.com/nandaruanawijaya-coder/bq-table-desc