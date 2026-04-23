# How to Document a New BigQuery Table

> **Simplest way**: Use Claude Code - It reads the full automation guide and handles everything automatically

---

## 🚀 Quick Start (5 Steps)

### Step 1: Clone Repository

```bash
git clone https://github.com/nandaruanawijaya-coder/bq-table-desc.git
cd bq-table-desc
```

Or in VS Code:
- `Cmd/Ctrl + Shift + P` → Search "Git: Clone"
- Paste: `https://github.com/nandaruanawijaya-coder/bq-table-desc.git`

### Step 2: Create Branch

```bash
git checkout -b feature/document-[your-table-name]

# Example:
git checkout -b feature/document-user_profiles
```

### Step 3: Open Claude Code

In VS Code:
- Click the **Claude Code icon** in the sidebar
- Or press the Claude Code button in the editor

### Step 4: Ask Claude Code

Copy and paste this exact prompt:

```
I need to document a BigQuery table using the automation guide in this repository.

Table ID: ledger-fcc1e.[dataset].[table_name]

Please:
1. Read CLAUDE_CODE_AUTOMATION.md for the complete workflow
2. Follow all 8 steps to document the table
3. Generate Python script
4. Execute script
5. Enhance documentation with descriptions and business context
6. Validate all documentation
7. Commit to git
8. Report when complete

Replace [dataset] and [table_name] with the actual values.
```

### Step 5: Claude Code Does Everything

Claude Code will:
✅ Generate Python script  
✅ Query 10,000 sample rows  
✅ Analyze all columns  
✅ Create documentation JSON  
✅ Enhance descriptions  
✅ Validate everything  
✅ Commit to git  
✅ Report completion  

**That's it! Documentation is done.** 🎉

---

## 📚 Documentation Files

This repository includes:

| File | Purpose | Read When |
|------|---------|-----------|
| **README.md** | Overview for data team | First time using repo |
| **CONTRIBUTING.md** | Manual contribution guide | If not using Claude Code |
| **CLAUDE_CODE_AUTOMATION.md** | Complete automation guide | Claude Code reads this automatically |
| **HOW_TO_DOCUMENT_NEW_TABLES.md** | This file - Quick guide | Before using Claude Code |

---

## 🤖 Why Use Claude Code?

### ✅ Advantages

- **Automatic**: No manual steps needed
- **Fast**: 5-10 minutes per table
- **Accurate**: Follows detailed automation guide
- **Smart**: Enhances documentation intelligently
- **Safe**: Validates everything before committing

### vs Manual Process

| Task | Claude Code | Manual |
|------|-------------|--------|
| Generate script | Automatic | Manual write |
| Query data | Automatic | Manual test |
| Analyze columns | Automatic | Manual analysis |
| Create JSON | Automatic | Manual edit |
| Enhance descriptions | Automatic | Manual edit |
| Validate | Automatic | Manual check |
| Git commit | Automatic | Manual git |
| **Total Time** | **10 min** | **45-60 min** |

---

## 💡 What Claude Code Reads

Claude Code automatically reads:
- **CLAUDE_CODE_AUTOMATION.md** - Complete automation instructions
- **Existing documentation** - Examples to match style
- **Python BigQuery client** - Documentation as needed
- **GitHub API** - For git operations

**You only need to provide**: The table ID in your prompt

---

## 🔍 What Gets Created

After Claude Code completes, you'll have:

```
✅ table_list/[table_name].json
   └─ 10,000 rows of sample data

✅ table_column_description/[table_name]_doc.json
   └─ Complete column documentation with:
      • Data types
      • Null percentages
      • Clear descriptions
      • Business context
      • Real example values

✅ document_[table_name].py
   └─ Python script used to generate documentation

✅ Git commit
   └─ Changes committed and ready to push
```

---

## 📋 Table ID Format

Your prompt must include the table ID in this format:

```
ledger-fcc1e.dataset.table_name
```

Examples:
```
✅ ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable
✅ ledger-fcc1e.db_accounting.prod_edc_order
✅ ledger-fcc1e.analytics.customer_transactions
```

---

## ⚠️ Prerequisites

Before asking Claude Code:

- ✅ Clone the repository
- ✅ Open in VS Code
- ✅ Install Claude Code extension
- ✅ Authenticate to Claude Code
- ✅ Have BigQuery access

Check BigQuery access:
```bash
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable\` LIMIT 1"
```

Should return a number, not an error.

---

## 🎯 Step-by-Step Example

### Your Input to Claude Code:

```
I need to document a BigQuery table.

Table ID: ledger-fcc1e.analytics.customer_events

Please read CLAUDE_CODE_AUTOMATION.md and document this table following all steps.
```

### Claude Code Does:

1. ✅ Reads CLAUDE_CODE_AUTOMATION.md
2. ✅ Generates `document_customer_events.py`
3. ✅ Executes script → fetches 10,000 rows
4. ✅ Analyzes 50 columns
5. ✅ Creates `table_column_description/customer_events_doc.json`
6. ✅ Enhances all descriptions with business context
7. ✅ Validates documentation quality
8. ✅ Commits to git with proper message
9. ✅ Reports: "Documentation complete! Ready to push."

### You Do:

```bash
# Optional: Review the generated files
cat table_column_description/customer_events_doc.json

# Push to GitHub when ready
git push origin feature/document-customer_events

# Create PR on GitHub
```

---

## 🛠️ If Something Goes Wrong

If Claude Code reports an error:

1. **Table not found**: Verify table ID is correct
2. **Permission denied**: Run `gcloud auth application-default login`
3. **Python error**: Claude Code will fix it automatically
4. **JSON error**: Claude Code will validate and fix

Claude Code has built-in error handling and will report what to do.

---

## 📞 Need Help?

### If Claude Code:
- ✅ Completes successfully → Documentation is done!
- ❌ Reports an error → Follow the error instructions it provides
- ❓ Asks a question → Answer based on your table

### If you need help:
- Check **CLAUDE_CODE_AUTOMATION.md** for technical details
- Check **CONTRIBUTING.md** for manual process
- Ask data team lead for table-specific questions

---

## ✅ Verification Checklist

After Claude Code finishes, verify:

```bash
# Check files were created
ls -lh table_list/[table_name].json
ls -lh table_column_description/[table_name]_doc.json

# Verify JSON is valid
jq '.' table_column_description/[table_name]_doc.json

# Check git commit
git log --oneline -1
```

All should show ✅ without errors.

---

## 🎉 You're Done!

Documentation is complete and ready. 

**Next step**: Create a Pull Request on GitHub

```bash
# View what was changed
git status

# Push to GitHub
git push origin feature/document-[table_name]
```

Then go to GitHub and create a PR. Done! 🚀

---

## 📚 For More Details

For complete technical documentation on the automation process, Claude Code reads:

**👉 [CLAUDE_CODE_AUTOMATION.md](CLAUDE_CODE_AUTOMATION.md)**

This guide is written specifically so Claude Code can understand and execute the entire workflow automatically.

---

**Last Updated**: 2026-04-23  
**Recommended**: Use Claude Code for fastest documentation  
**Status**: Production Ready ✅