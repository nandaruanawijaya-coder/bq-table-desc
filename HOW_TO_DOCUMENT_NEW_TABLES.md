# How to Document New BigQuery Tables using Claude Code

> **Complete workflow**: Pull repo → Open in VS Code → Use Claude Code to generate all documentation automatically

---

## 📋 Overview

This guide walks you through documenting a BigQuery table from start to finish using:
- **VS Code** - Your code editor
- **Claude Code** - AI assistant integrated in VS Code
- **BigQuery** - Data source

**Total Time**: 30-45 minutes per table

---

## 🔧 Prerequisites

Before you start, ensure you have:

### 1. Install VS Code Extensions
- **Claude Code** (Official Anthropic extension)
  - Open VS Code
  - Go to Extensions (`Cmd/Ctrl + Shift + X`)
  - Search "Claude"
  - Install "Claude Code" by Anthropic

- **Python extension** (for syntax highlighting)
  - Search "Python" in Extensions
  - Install "Python" by Microsoft

### 2. Authenticate Claude Code
1. Open VS Code Command Palette (`Cmd/Ctrl + Shift + P`)
2. Search "Claude: Sign In"
3. Authenticate with your Claude account

### 3. Check BigQuery Access
```bash
# Open Terminal in VS Code (Ctrl + `)
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable\` LIMIT 1"

# Should return a number, not an error
```

---

## 🚀 Step-by-Step Workflow

### Step 1: Clone Repository in VS Code

```bash
# Open VS Code Terminal (Ctrl + `)
# Run:
git clone https://github.com/nandaruanawijaya-coder/bq-table-desc.git
cd bq-table-desc
```

Or use VS Code's built-in:
1. `Cmd/Ctrl + Shift + P`
2. Search "Git: Clone"
3. Paste: `https://github.com/nandaruanawijaya-coder/bq-table-desc.git`

### Step 2: Open in VS Code

```bash
code bq-table-desc
```

Or:
1. File → Open Folder
2. Select the `bq-table-desc` folder

---

### Step 3: Create Feature Branch

In VS Code Terminal:

```bash
# Create new branch for your table
git checkout -b feature/document-[your-table-name]

# Example:
git checkout -b feature/document-user_profiles
```

You'll see the branch name in VS Code's bottom status bar.

---

### Step 4: Use Claude Code to Generate Everything

This is where Claude Code helps you automate the documentation!

#### 4A. Ask Claude Code to Create the Python Script

1. **Open Claude Code** in VS Code (Click Claude icon in sidebar)
2. **Paste this prompt** into Claude:

```
I need to document a BigQuery table. Create a Python script that:
1. Queries 10,000 rows from: ledger-fcc1e.[dataset].[table_name]
2. Analyzes all columns (name, type, nullability)
3. Generates a _doc.json file with complete documentation

The script should:
- Save sample data to table_list/[table_name].json
- Create documentation in table_column_description/[table_name]_doc.json
- Include data types, null percentages, and example values

Replace [dataset] and [table_name] with actual values.
```

**Claude Code will generate a complete Python script!**

#### 4B. Create the Script File

1. **Right-click** in Explorer → New File
2. Name it: `document_[your_table_name].py`
3. **Copy-paste** the Python code Claude generated

#### 4C: Run the Script via Claude Code

1. **Open the script** in editor
2. **Ask Claude Code**:
```
Run this Python script to generate documentation for my table.
Check if there are any errors and fix them if needed.
```

Claude Code will execute it and show results!

#### 4D: Claude Code Enhances Documentation

Ask Claude Code:

```
Now improve the generated _doc.json documentation:
1. Add clear descriptions for each column
2. Add business context explaining how each column is used
3. Ensure all descriptions are clear and non-technical
4. Keep example values as actual data (don't modify them)

The file is in: table_column_description/[table_name]_doc.json
```

Claude Code can edit the file directly! ✨

---

### Step 5: Review Generated Files

In VS Code Explorer, verify:

✅ `table_list/[table_name].json` - Sample data (should be 10,000 rows)
✅ `table_column_description/[table_name]_doc.json` - Complete documentation

**Tip**: Click the files to preview them in VS Code!

---

### Step 6: Make Final Edits (if needed)

If you want to tweak anything:

1. **Open the _doc.json file**
2. **Select text** you want to improve
3. **Ask Claude Code** (with selection):

```
Can you improve this description to be more business-focused
and explain why this column is important?
```

Claude Code will rewrite just that section!

---

### Step 7: Commit to Git

In VS Code:

1. **Open Source Control** (`Ctrl + Shift + G`)
2. **Stage changes** - Click `+` next to files
3. **Write commit message**:
```
Add documentation for [table_name] table

- Documented all X columns
- Added 10,000 row sample
- Included business context and descriptions
```

4. **Commit** - Press `Cmd/Ctrl + Enter`
5. **Push** - Click "Publish Branch"

---

### Step 8: Create Pull Request

1. Go to GitHub: https://github.com/nandaruanawijaya-coder/bq-table-desc
2. Click "New Pull Request"
3. Select your branch
4. Add title and description
5. Submit!

---

## 💡 Claude Code Tips & Tricks

### Use Claude Code's /analyze Command

```
/analyze table_column_description/[table_name]_doc.json

This shows you:
- How many columns documented
- Which ones need better descriptions
- Data quality insights
```

### Ask Claude to Validate

```
Check if this documentation is complete:
- All columns documented?
- Null percentages reasonable?
- Example values are real data?
- Business context clear?
```

Claude will verify everything!

### Use Claude for Git Help

```
Help me create a good git commit message for documenting
the [table_name] table with all the changes I made.
```

Claude generates the commit message for you!

### Generate Documentation Standards

```
Based on the existing table documentation in this repo,
what should the documentation look like for my new table?
Show me an example of a well-documented column.
```

Claude shows you the pattern!

---

## 🎯 Quick Reference: Claude Code Prompts

### Initial Script Generation
```
Create a Python script to document BigQuery table:
ledger-fcc1e.[dataset].[table_name]
- Query 10,000 rows
- Analyze column types
- Generate JSON documentation
- Save sample data
```

### Enhance Descriptions
```
Improve all column descriptions in [file] to be:
- Business-focused
- Non-technical
- Explain usage and importance
- Keep example values unchanged
```

### Validate Documentation
```
Review this documentation file and tell me:
1. Are all columns documented?
2. Are descriptions clear?
3. Are example values real data?
4. Is business context helpful?
5. What could be improved?
```

### Format & Style
```
Check if this documentation follows the project standards:
- See examples in: table_column_description/
- All columns have description + business_context?
- Data types correct?
- Example values format correct?
```

---

## 📊 Example: Full Workflow

### You Ask Claude Code:
```
I want to document this BigQuery table:
ledger-fcc1e.analytics.customer_transactions

Create everything I need:
1. Python script to fetch 10,000 rows
2. Full documentation JSON
3. Good descriptions and business context
```

### Claude Code:
✅ Creates `document_customer_transactions.py`
✅ Generates sample data JSON
✅ Creates _doc.json with all 50+ columns
✅ Adds detailed descriptions
✅ Provides business context
✅ Includes real example values

### You:
1. Review the files (2 minutes)
2. Make any tweaks using Claude (5 minutes)
3. Commit to git (2 minutes)
4. Create PR (1 minute)

**Done in 10 minutes!** 🎉

---

## ⚠️ Troubleshooting

### Issue: Python script fails to run
```
Ask Claude Code:
"Fix this Python script error: [paste error message]"
```

### Issue: BigQuery authentication error
```bash
# In VS Code Terminal:
gcloud auth application-default login
```

Then ask Claude Code to try again.

### Issue: JSON file has errors
```
Ask Claude Code:
"Validate this JSON file and fix any errors: [file path]"
```

### Issue: Can't find Claude Code
1. Make sure it's installed from Extensions
2. Make sure you're signed in (`Claude: Sign In`)
3. Look for Claude icon in VS Code sidebar
4. Click it to open the chat panel

---

## ✅ Quality Checklist

Before creating your PR, verify:

- [ ] Python script ran without errors
- [ ] Sample data file created (table_list/[name].json)
- [ ] Documentation file created (table_column_description/[name]_doc.json)
- [ ] All columns have descriptions (no [TODO])
- [ ] Business context added for each column
- [ ] Example values are real data
- [ ] JSON is valid (no syntax errors)
- [ ] Files added to git
- [ ] Commit message is clear

**Tip**: Ask Claude Code to check the list for you!

```
Check if my documentation meets this checklist:
[paste checklist]
```

---

## 🔄 VS Code Keyboard Shortcuts You'll Use

| Action | Mac | Windows/Linux |
|--------|-----|---------------|
| Terminal | Ctrl + ` | Ctrl + ` |
| Command Palette | Cmd + Shift + P | Ctrl + Shift + P |
| Search File | Cmd + F | Ctrl + F |
| Replace | Cmd + H | Ctrl + H |
| Source Control | Ctrl + Shift + G | Ctrl + Shift + G |
| Git Commit | Cmd + K Cmd + O | Ctrl + K Ctrl + O |
| Claude Code | Click sidebar | Click sidebar |

---

## 📝 Example Prompts for Different Tables

### For Location/Geographic Tables:
```
This table contains location data. Improve descriptions to show:
- How coordinates are formatted
- What geographic levels are included
- How this data is used for analysis
```

### For Transaction Tables:
```
This is a transaction table. Add context about:
- How amounts are stored (currency, decimals)
- How dates are formatted
- What transaction types exist
- How this links to other tables
```

### For Merchant/Business Tables:
```
This is a merchant master data table. Explain:
- How merchant status is tracked
- What identifiers are primary keys
- How this connects to transactions
- Business use cases
```

---

## 🚀 Speed Tips

**Fastest workflow:**
1. Clone repo (1 min)
2. Create branch (1 min)
3. Ask Claude Code for script (2 min)
4. Run script (3 min)
5. Ask Claude to enhance (5 min)
6. Review (2 min)
7. Commit & push (2 min)

**Total: ~16 minutes!**

---

## 📞 Need Help?

### From Claude Code Directly
Just ask it anything:
- "How do I use this Python library?"
- "Fix this script error"
- "Improve these descriptions"
- "What's the best way to handle this?"

Claude Code is always there to help!

### From the Community
- Check CONTRIBUTING.md for guidelines
- Look at existing documentation for examples
- Ask your data team lead

---

## 🎓 Learn More

- **Python BigQuery**: Ask Claude Code for help
- **VS Code Tips**: `Cmd/Ctrl + Shift + P` → Help
- **Git Workflows**: Ask Claude Code for git help
- **Documentation Standards**: See other tables in repo

---

**Last Updated**: 2026-04-23  
**Designed for**: VS Code + Claude Code workflow  
**Status**: Production Ready ✅
