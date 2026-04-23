# BigQuery Table Documentation Repository

> **Fastest way to document BigQuery tables** - Add table names to a list, Claude Code does the rest automatically

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

| Tables | Columns | Sample Rows | Status |
|--------|---------|-------------|--------|
| 4 documented | 169 | 31,086 | ✅ Complete |

**Tables:**
- `location_gmaps_static_opentable` (16 cols, 10,000 rows)
- `mapping_area_mse_opentable` (10 cols, 1,086 rows)
- `ms_merchant_profiling_ssot_opentable` (107 cols, 10,000 rows)
- `prod_edc_order` (36 cols, 10,000 rows)

---

## 📁 Repository Structure

```
├── 📄 README.md (This file)
├── 📄 CONTRIBUTING.md (Manual guide for data team)
├── 📄 CLAUDE_CODE_AUTOMATION.md (AI automation instruction set)
├── 📄 table_list.md (Tables to document - EDIT THIS)
│
├── 📁 table_column_description/
│   ├── location_gmaps_static_opentable_doc.json
│   ├── mapping_area_mse_opentable_doc.json
│   ├── ms_merchant_profiling_ssot_opentable_doc.json
│   └── prod_edc_order_doc.json
│
└── 📁 table_list/
    ├── location_gmaps_static_opentable.json
    ├── mapping_area_mse_opentable.json
    ├── ms_merchant_profiling_ssot_opentable.json
    └── prod_edc_order.json
```

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

## 📚 Documentation Guides

| Guide | For Whom | Purpose |
|-------|----------|---------|
| **README.md** | Data Team | Overview (this file) |
| **table_list.md** | Data Team | List of tables to document |
| **CONTRIBUTING.md** | Data Team | Manual process guide |
| **CLAUDE_CODE_AUTOMATION.md** | Claude Code | Complete automation instructions |

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

## 📋 What Gets Created

For each table, Claude Code creates:

**1. Documentation File** (`table_column_description/[table_name]_doc.json`)
```json
{
  "table_name": "...",
  "total_columns": 50,
  "columns": [
    {
      "column_name": "...",
      "data_type": "STRING",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Clear description",
      "business_context": "Business usage",
      "example_values": ["val1", "val2"]
    }
  ]
}
```

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

**Last Updated**: 2026-04-23  
**Status**: Production Ready ✅  
**GitHub**: https://github.com/nandaruanawijaya-coder/bq-table-desc