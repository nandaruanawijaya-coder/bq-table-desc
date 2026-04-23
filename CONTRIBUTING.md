# Contributing to Table Documentation

> Add tables you want documented, use Claude Code for automation, or contribute manually

---

## 🚀 Recommended: Use Claude Code (Fastest)

### 1. Clone Repository

```bash
git clone https://github.com/nandaruanawijaya-coder/bq-table-desc.git
cd bq-table-desc
```

### 2. Add Tables to `table_list.md`

Edit `table_list.md` and add the tables you want documented:

```markdown
# Tables to Document

- ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable
- ledger-fcc1e.dataset.your_new_table_1
- ledger-fcc1e.dataset.your_new_table_2
- ledger-fcc1e.dataset.your_new_table_3
```

**Format**: One table per line, full BigQuery table ID (project.dataset.table)

### 3. Open Claude Code in VS Code

Click the Claude Code icon in the sidebar

### 4. Ask Claude Code to Document

Paste this prompt:

```
Document all tables in table_list.md that don't have 
documentation in table_column_description/ yet.

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow.
Replace any placeholder variables with actual values.
```

### 5. Claude Code Does Everything

Claude Code will:
- ✅ Read table_list.md
- ✅ Check what's already documented
- ✅ Skip already-documented tables
- ✅ Process only missing tables
- ✅ Query 10,000 rows from each
- ✅ Analyze all columns
- ✅ Generate JSON documentation
- ✅ Enhance descriptions
- ✅ Validate quality
- ✅ Commit each table with proper message
- ✅ Report completion

**Time**: ~10 minutes per table

### 6. Review and Push

```bash
# Check what was created
git log --oneline -5

# Push to GitHub when ready
git push origin main
# or create a PR if needed
```

---

## 📝 Manual Process (If Not Using Claude Code)

If you prefer to document tables manually:

### Step 1: Create Python Script

Claude Code will generate this, but if doing manually, create `document_[table_name].py`

See CLAUDE_CODE_AUTOMATION.md for the Python script template.

### Step 2: Run Script

```bash
python3 document_[table_name].py
```

Creates:
- `table_list/[table_name].json` (10,000 sample rows)
- `table_column_description/[table_name]_doc.json` (documentation)

### Step 3: Enhance Documentation

Edit `table_column_description/[table_name]_doc.json` and fill in:
- Clear descriptions for each column
- Business context explaining usage
- Keep example values as real data

### Step 4: Validate

Check the JSON is valid:

```bash
jq '.' table_column_description/[table_name]_doc.json
```

Verify:
- ✅ All columns have descriptions (no [TODO])
- ✅ All columns have business_context
- ✅ Example values are real data
- ✅ JSON is valid syntax

### Step 5: Commit

```bash
git add table_list/[table_name].json
git add table_column_description/[table_name]_doc.json
git commit -m "Add documentation for [table_name] table

- Documented [X] columns
- Added 10,000 row sample
- Business context and descriptions included"
```

### Step 6: Push

```bash
git push origin main
# or create a PR
```

---

## 🎯 Update Existing Documentation

### If Table Already Documented

1. **Remove old documentation**
   ```bash
   rm table_column_description/[table_name]_doc.json
   rm table_list/[table_name].json
   ```

2. **Make sure it's in table_list.md**
   ```bash
   # Add or keep in table_list.md
   echo "- ledger-fcc1e.dataset.table_name" >> table_list.md
   ```

3. **Ask Claude Code to re-document**
   - Claude Code will detect it's missing and regenerate with latest schema

---

## ✅ Quality Checklist

Before submitting:

### Documentation Completeness
- [ ] All columns documented
- [ ] No [TODO] markers remaining
- [ ] Descriptions are clear
- [ ] Business context explains usage
- [ ] Example values are real data

### File Validation
- [ ] JSON files are valid (use `jq` to check)
- [ ] Sample data file has 10,000 rows (or all if less)
- [ ] Documentation file has all required fields

### Git Workflow
- [ ] Files properly staged
- [ ] Commit message is clear and descriptive
- [ ] Code has been tested (documentation generated without errors)

---

## 💡 Best Practices

### For Column Descriptions

✅ **Good**:
- "Customer's full name (first and last)"
- "Timestamp when transaction was created"
- "EDC device identifier for payment processing"

❌ **Bad**:
- "name" (too vague)
- "data" (meaningless)
- "timestamp" (which timestamp?)

### For Business Context

✅ **Good**:
- "Used for customer communication, CRM matching, and billing"
- "Critical for transaction timestamp analysis and reconciliation"
- "Determines which payment methods are available to merchant"

❌ **Bad**:
- "Important field" (vague)
- "Database column" (technical, not business)
- "For storing data" (meaningless)

### For Example Values

✅ **Good**: Use actual data from sample rows
```json
"example_values": ["John Doe", "Jane Smith", "Bob Johnson"]
```

❌ **Bad**: Made-up values
```json
"example_values": ["example_name_1", "example_name_2"]
```

---

## 📂 File Structure to Maintain

```
table_list.md
  └─ Your list of tables to document (EDIT THIS)

table_column_description/
  └─ [table_name]_doc.json files (Claude Code creates these)

table_list/
  └─ [table_name].json files (Claude Code creates these)
```

---

## 🔄 Workflow Summary

### Quickest Way (Recommended)

```
1. Edit table_list.md
2. Ask Claude Code to follow CLAUDE_CODE_AUTOMATION.md
3. Done - Claude Code handles everything
4. Push to GitHub
```

**Time**: ~10 minutes per table

### Manual Way

```
1. Create Python script
2. Run script
3. Manually edit JSON
4. Validate documentation
5. Commit and push
```

**Time**: ~45-60 minutes per table

---

## 📞 Questions?

### For Claude Code Users
- Claude Code reads `CLAUDE_CODE_AUTOMATION.md`
- It handles errors and reports status
- Check error handling section for common issues

### For Manual Process
- See `CLAUDE_CODE_AUTOMATION.md` for Python script template
- See `README.md` for repository overview
- Check error handling in automation guide

---

## 🎉 Thank You!

Thank you for contributing to our data documentation system. Your documentation helps business stakeholders understand and query data confidently.

---

**Last Updated**: 2026-04-23  
**Recommended Method**: Claude Code Automation  
**Status**: Production Ready ✅