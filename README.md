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
Follow CLAUDE_CODE_AUTOMATION.md for complete workflow.
```

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
| 4 documented | 169 | 31,086+ | Enhanced semantic | ✅ Production Ready |

**Tables with Semantic Descriptions:**
- `location_gmaps_static` (16 cols) — Geocoding data with coordinates and administrative divisions
- `mapping_area_mse_opentable` (10 cols) — MSE team organizational hierarchy and territory mapping
- `ms_merchant_profiling_ssot` (107 cols) — Comprehensive merchant profile with business metrics and product ownership
- `prod_edc_order` (36 cols) — EDC order lifecycle with merchant details and delivery metadata

**Description Quality**: All 169 columns have enhanced semantic descriptions explaining:
- ✓ What the field represents (business meaning, not just naming)
- ✓ How it's used (product adoption metrics, KYC verification, sales targeting, etc)
- ✓ Value format (UUID, phone number, coordinates, timestamps, etc)
- ✓ Business context (required vs optional, core vs supplementary)

---

## 📁 Repository Structure

```
├── 📄 README.md (Overview - this file)
├── 📄 CLAUDE_CODE_AUTOMATION.md (Reference guide for Claude Code automation)
├── 📄 CONTRIBUTING.md (Guide for data team - quick reference)
├── 📄 table_list.md (List of tables to document - EDIT THIS FILE)
│
├── 📁 table_column_description/
│   ├── location_gmaps_static_doc.json (Geocoding data - 16 columns)
│   ├── mapping_area_mse_opentable_doc.json (MSE hierarchy - 10 columns)
│   ├── ms_merchant_profiling_ssot_doc.json (Merchant profiles - 107 columns)
│   └── prod_edc_order_doc.json (EDC orders - 36 columns)
│
└── 📁 table_list/
    ├── location_gmaps_static.json (10,000 sample rows)
    ├── mapping_area_mse_opentable.json (1,086 sample rows)
    ├── ms_merchant_profiling_ssot.json (10,000 sample rows)
    └── prod_edc_order.json (10,000 sample rows)
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

## 📞 Common Questions

**Q: How do I add a new table?**  
A: Add it to `table_list.md`, then ask Claude Code to document it.

**Q: What if table is already documented?**  
A: Claude Code checks and skips it automatically.

**Q: Can I document multiple tables at once?**  
A: Yes! Add them all to `table_list.md`, ask Claude Code once.

**Q: What if Claude Code fails?**  
A: See error message in CLAUDE_CODE_AUTOMATION.md error handling section.

**Q: Do I need to manually edit documentation?**  
A: Only if you want to improve descriptions. Claude Code creates good documentation automatically.

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