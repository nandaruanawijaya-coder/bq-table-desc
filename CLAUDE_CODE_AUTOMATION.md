# Claude Code Automation Guide for Table Documentation

> **For Claude Code & AI Assistants** - Complete instruction set to automatically document BigQuery tables without additional prompts

---

## 📋 Purpose

This document enables Claude Code and other AI assistants to:
- Automatically document any BigQuery table
- Generate Python scripts
- Create JSON documentation
- Enhance descriptions and business context
- Validate documentation quality
- Commit and push to GitHub

**No additional prompts needed** - Claude Code can read this and execute all steps.

---

## 🎯 Automated Workflow Overview

```
INPUT: BigQuery table identifier (project.dataset.table)
  ↓
STEP 1: Validate table access
  ↓
STEP 2: Generate Python script to query 10,000 rows
  ↓
STEP 3: Execute script to fetch data
  ↓
STEP 4: Analyze columns and generate JSON documentation
  ↓
STEP 5: Enhance descriptions with business context
  ↓
STEP 6: Validate documentation quality
  ↓
STEP 7: Commit to git and push
  ↓
OUTPUT: Complete documentation ready for PR
```

---

## 🔍 STEP 1: Input Validation

When receiving a documentation request, Claude Code MUST:

### 1.1 Extract Table Information
```
Pattern: project-id.dataset.table_name

Examples (VALID):
  ✅ ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable
  ✅ ledger-fcc1e.db_accounting.prod_edc_order
  ✅ project-123.dataset_name.table_name

Invalid formats:
  ❌ dataset.table_name (missing project)
  ❌ table_name (missing project and dataset)
  ❌ project.table (missing dataset)
```

### 1.2 Validate Access
Before proceeding, Claude Code MUST verify:

```bash
# Terminal: Check if table exists and get row count
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`[project].[dataset].[table]\` LIMIT 1"

# Expected: A number (row count)
# If error: Stop and report access denied
```

---

## 🐍 STEP 2: Generate Python Script

Claude Code MUST generate a Python script that:

### 2.1 Script Requirements

**Input Variables**:
```python
PROJECT_ID = 'ledger-fcc1e'
TABLE_ID = '[full-table-id-from-input]'
TABLE_NAME = '[table-name-only]'
DATASET = '[dataset-from-table-id]'
```

**Script must**:
1. Import required libraries: `google.cloud.bigquery`, `json`, `datetime`
2. Query exactly 10,000 rows (or all rows if table has fewer)
3. Analyze each column for:
   - Column name
   - Data type (STRING, INTEGER, FLOAT, BOOLEAN, ARRAY, JSON, NULL, etc.)
   - Null count and percentage
   - Sample values (non-null only, max 3)
4. Save sample data to: `table_list/[TABLE_NAME].json`
5. Generate documentation to: `table_column_description/[TABLE_NAME]_doc.json`

### 2.2 Script Template

```python
from google.cloud import bigquery
import json
from collections import defaultdict
from datetime import datetime

# Configuration
PROJECT_ID = 'ledger-fcc1e'
TABLE_ID = '[project.dataset.table]'
TABLE_NAME = '[table_name_only]'

def analyze_data_type(value):
    """Determine data type of value"""
    if value is None:
        return 'NULL'
    if isinstance(value, bool):
        return 'BOOLEAN'
    if isinstance(value, int):
        return 'INTEGER'
    if isinstance(value, float):
        return 'NUMERIC'
    if isinstance(value, list):
        return 'ARRAY'
    if isinstance(value, dict):
        return 'JSON'
    if isinstance(value, str):
        return 'STRING (LONG)' if len(value) > 50 else 'STRING'
    return 'UNKNOWN'

# Step 1: Fetch sample data
print(f"⏳ Fetching 10,000 rows from {TABLE_ID}...")
client = bigquery.Client(project=PROJECT_ID)
query = f"SELECT * FROM `{TABLE_ID}` LIMIT 10000"
query_job = client.query(query)

rows = list(query_job.result())
rows_list = [dict(row) for row in rows]

# Save sample data
sample_file = f'table_list/{TABLE_NAME}.json'
with open(sample_file, 'w') as f:
    json.dump(rows_list, f, indent=2, default=str)
print(f"✅ Saved {len(rows_list):,} rows to {sample_file}")

# Step 2: Analyze columns
print(f"⏳ Analyzing columns...")
columns_info = defaultdict(lambda: {
    'types': defaultdict(int),
    'null_count': 0,
    'sample_values': [],
})

for row in rows_list:
    for col, value in row.items():
        data_type = analyze_data_type(value)
        columns_info[col]['types'][data_type] += 1
        if value is None:
            columns_info[col]['null_count'] += 1
        else:
            columns_info[col]['sample_values'].append(value)
            if len(columns_info[col]['sample_values']) > 10:
                columns_info[col]['sample_values'] = columns_info[col]['sample_values'][:10]

# Step 3: Build documentation
print(f"⏳ Creating documentation...")
doc = {
    "table_name": TABLE_NAME,
    "full_table_id": TABLE_ID,
    "total_columns": len(columns_info),
    "sample_rows_analyzed": len(rows_list),
    "documentation_generated": datetime.now().isoformat(),
    "columns": []
}

for col in sorted(columns_info.keys()):
    info = columns_info[col]
    primary_type = max(info['types'].items(), key=lambda x: x[1])[0] if info['types'] else 'NULL'
    null_pct = (info['null_count'] / len(rows_list) * 100) if len(rows_list) > 0 else 0
    
    col_doc = {
        "column_name": col,
        "data_type": primary_type,
        "nullable": True if null_pct > 0 else False,
        "null_percentage": round(null_pct, 2),
        "description": "[TODO] Add description",
        "business_context": "[TODO] Add context",
        "example_values": [v for v in info['sample_values'][:3] if v is not None]
    }
    doc['columns'].append(col_doc)

# Save documentation
doc_file = f'table_column_description/{TABLE_NAME}_doc.json'
with open(doc_file, 'w') as f:
    json.dump(doc, f, indent=2, default=str)

print(f"✅ Created documentation for {len(columns_info)} columns")
print(f"✅ Documentation saved to {doc_file}")
```

---

## ▶️ STEP 3: Execute Python Script

Claude Code MUST:

### 3.1 Execution Steps
```bash
# 1. Create the script file
# 2. Save it in repository root as: document_[TABLE_NAME].py
# 3. Execute it via terminal: python3 document_[TABLE_NAME].py
# 4. Check for errors and report status
```

### 3.2 Success Indicators
Script completed successfully when:
- ✅ No Python errors
- ✅ Sample data file created: `table_list/[TABLE_NAME].json`
- ✅ Documentation file created: `table_column_description/[TABLE_NAME]_doc.json`
- ✅ Both files are valid JSON
- ✅ Column count > 0

### 3.3 Error Handling
If script fails:
1. **AuthenticationError**: User needs to run `gcloud auth application-default login`
2. **TableNotFoundError**: Verify table ID and BigQuery access
3. **JSONDecodeError**: Check that sample data is valid JSON
4. **FileNotFoundError**: Ensure directories exist (they should)

---

## ✏️ STEP 4: Enhance Documentation

Claude Code MUST enhance the generated `_doc.json` file by:

### 4.1 For Each Column

**Replace [TODO] markers with real content**:

```json
{
  "column_name": "example_column",
  "description": "[ENHANCE THIS]",
  "business_context": "[ENHANCE THIS]"
}
```

### 4.2 Description Guidelines

✅ **Good Descriptions**:
- What data is stored
- Format/type of data
- Any special encoding
- Related columns
- Example: "Customer's full name (first + last). Format: 'FirstName LastName'"

❌ **Bad Descriptions**:
- Generic ("data", "information")
- Too technical
- Database-focused
- Too long (>1 sentence)

### 4.3 Business Context Guidelines

✅ **Good Context**:
- Why this column exists
- How it's used in business
- What reports use it
- Important for what analysis
- Example: "Used for customer communication, mail delivery, and CRM matching. Essential for all customer-facing operations."

❌ **Bad Context**:
- Technical implementation
- Database schema info
- What method created it
- Too vague

### 4.4 Automated Enhancement Process

Claude Code SHOULD:

1. **Analyze existing descriptions** in similar tables (location, merchant, order tables)
2. **Apply same quality level** to new table
3. **Use business terminology** not technical jargon
4. **Keep descriptions concise** (1-2 sentences max)
5. **Verify example values** are real (not made up)
6. **Cross-reference columns** (explain relationships)

### 4.5 Column Type-Specific Enhancements

**For STRING columns**:
- Explain format (freeform text, codes, IDs)
- Max length if relevant
- Character encoding if special

**For NUMERIC columns**:
- Currency type if applicable
- Decimal places
- Range if bounded
- Units (IDR, percentage, count)

**For DATE/TIMESTAMP columns**:
- Timezone if applicable
- What event this represents
- Is it nullable? Why?

**For BOOLEAN/ARRAY columns**:
- What values mean
- What each element represents
- How to interpret nulls

**For JSON columns**:
- General structure
- What it contains
- Common fields

---

## ✅ STEP 5: Validation

Claude Code MUST validate documentation before committing:

### 5.1 Validation Checklist

```
For each column:
  ☑️ column_name: Not empty, matches BigQuery name
  ☑️ data_type: Valid BigQuery type
  ☑️ nullable: Boolean true/false
  ☑️ null_percentage: 0-100 number
  ☑️ description: No [TODO], clear and concise
  ☑️ business_context: No [TODO], explains usage
  ☑️ example_values: Array with 0-3 real values

For document:
  ☑️ JSON is valid (no syntax errors)
  ☑️ All required fields present
  ☑️ table_name matches filename
  ☑️ total_columns > 0
  ☑️ sample_rows_analyzed > 0

For sample data:
  ☑️ JSON is valid
  ☑️ Row count > 0
  ☑️ Contains actual BigQuery data
```

### 5.2 Validation Script

Claude Code SHOULD run:

```python
import json

# Validate documentation file
doc_file = f'table_column_description/{TABLE_NAME}_doc.json'
with open(doc_file, 'r') as f:
    doc = json.load(f)

errors = []

# Check required fields
for col in doc['columns']:
    if '[TODO]' in col.get('description', ''):
        errors.append(f"{col['column_name']}: Missing description")
    if '[TODO]' in col.get('business_context', ''):
        errors.append(f"{col['column_name']}: Missing business context")
    if not col.get('column_name'):
        errors.append("Column missing name")
    if not col.get('data_type'):
        errors.append("Column missing data type")

if errors:
    print("❌ Validation errors:")
    for error in errors:
        print(f"  - {error}")
else:
    print("✅ Documentation is complete and valid!")
    print(f"   Columns: {len(doc['columns'])}")
    print(f"   Sample rows: {doc['sample_rows_analyzed']:,}")
```

---

## 📤 STEP 6: Git Commit & Push

Claude Code MUST commit with proper git workflow:

### 6.1 Git Commands

```bash
# 1. Check current branch
git branch

# 2. Stage files
git add table_list/[TABLE_NAME].json
git add table_column_description/[TABLE_NAME]_doc.json
git add document_[TABLE_NAME].py  # Optional, but good to keep

# 3. Verify files are staged
git status

# 4. Commit with descriptive message
git commit -m "Add documentation for [TABLE_NAME] table

- Documented [X] columns
- Added 10,000 row sample data
- Included business context and descriptions
- Data quality: [% null columns, key metrics]"

# 5. Push to remote
git push origin main
```

### 6.2 Commit Message Format

```
[ACTION] [TABLE_NAME]: Brief description

Detailed explanation:
- What was done
- Key statistics
- Any important notes
- Quality metrics

Format:
  ✅ "Add documentation for user_profiles: 50 columns documented"
  ✅ "Update merchant_data: Enhanced descriptions and added context"
  ✅ "Refresh location_data: 10,000 row sample updated"
  
  ❌ "Fixed stuff"
  ❌ "Documentation"
  ❌ "Update"
```

### 6.3 Push Variations

```bash
# If pushing to main (approved change):
git push origin main

# If pushing new feature branch:
git push -u origin feature/document-[TABLE_NAME]

# If authentication fails:
# - Check GitHub access token
# - Verify SSH key setup
# - Run: git config --global credential.helper store
```

---

## 📊 Expected Output Structure

After completing all steps, Claude Code MUST create:

### 6.1 File: `table_column_description/[TABLE_NAME]_doc.json`

```json
{
  "table_name": "[table_name]",
  "full_table_id": "[project.dataset.table]",
  "total_columns": [number],
  "sample_rows_analyzed": [number],
  "documentation_generated": "[ISO timestamp]",
  "columns": [
    {
      "column_name": "[name]",
      "data_type": "[type]",
      "nullable": [boolean],
      "null_percentage": [0-100],
      "description": "[clear description]",
      "business_context": "[business usage]",
      "example_values": ["val1", "val2", "val3"]
    }
  ]
}
```

### 6.2 File: `table_list/[TABLE_NAME].json`

```json
[
  { "column1": value1, "column2": value2, ... },
  { "column1": value1, "column2": value2, ... },
  ...  (10,000 rows or all rows if less than 10,000)
]
```

---

## 🎯 Decision Trees for Claude Code

### Q: Should I proceed without user confirmation?

**YES** - if:
- Table ID is valid and formatted correctly
- BigQuery access is confirmed
- Files were successfully generated
- Documentation is complete and validated

**NO** - if:
- Table not found or access denied
- Script execution failed
- Documentation incomplete (has [TODO])
- Validation failed
- Any required field is missing

### Q: Should I enhance descriptions automatically?

**YES** - if:
- Documentation has [TODO] markers
- Similar columns exist in other tables
- Data types allow inference of meaning
- Example values are informative

**NO** - if:
- Domain knowledge required
- Business context unclear
- Example values don't reveal purpose
- Table is proprietary/sensitive

### Q: Should I commit to main or create a PR?

**CREATE BRANCH** (recommended):
```bash
git checkout -b feature/document-[TABLE_NAME]
# ... make changes ...
git push origin feature/document-[TABLE_NAME]
# Create PR on GitHub
```

**COMMIT TO MAIN** only if:
- Pre-approved by data team lead
- Documentation is 100% complete
- Validation passed
- No other changes pending

---

## 🚨 Error Handling Matrix

| Error | Cause | Solution | Claude Action |
|-------|-------|----------|---------------|
| `NotFound: Table ...` | Table doesn't exist | Verify table ID | STOP, report error |
| `Permission denied` | No BigQuery access | Run auth login | STOP, report error |
| `JSONDecodeError` | Invalid JSON in files | Check syntax | Auto-fix or STOP |
| `FileNotFoundError` | Directory missing | Create directory | Create and retry |
| `[TODO] in description` | Incomplete enhancement | Add descriptions | Auto-enhance or flag |
| `Null percentage > 90%` | Very sparse column | Document as optional | Note in context |
| `Git authentication failed` | Bad credentials | Refresh token | STOP, report error |

---

## 📋 Pre-Execution Checklist

Before Claude Code starts, verify:

- ✅ Repository cloned locally
- ✅ User is in correct directory: `bq-table-desc`
- ✅ BigQuery authentication active: `gcloud auth application-default login`
- ✅ Python 3.7+ installed with `google-cloud-bigquery`
- ✅ Git configured: `git config --global user.name` and `git config --global user.email`
- ✅ GitHub SSH key or token configured
- ✅ Table ID provided in correct format

---

## 🎓 Learning from Existing Tables

Claude Code SHOULD analyze existing documentation:

### Examine These Files for Patterns:
```
table_column_description/location_gmaps_static_opentable_doc.json
table_column_description/ms_merchant_profiling_ssot_opentable_doc.json
table_column_description/prod_edc_order_doc.json
```

### Learn From:
- Description length and style
- Business context depth
- Example value formatting
- Null percentage interpretation
- Data type accuracy

---

## ⚙️ Configuration Variables

Claude Code MUST use:

```python
# Project configuration
PROJECT_ID = 'ledger-fcc1e'  # BukuWarung's BigQuery project

# Directory configuration
SAMPLE_DIR = 'table_list'
DOC_DIR = 'table_column_description'

# Query configuration
SAMPLE_SIZE = 10000  # rows to fetch
EXAMPLE_COUNT = 3  # sample values per column

# File naming
SAMPLE_FILE = f'{SAMPLE_DIR}/{TABLE_NAME}.json'
DOC_FILE = f'{DOC_DIR}/{TABLE_NAME}_doc.json'
SCRIPT_FILE = f'document_{TABLE_NAME}.py'

# Git configuration
BRANCH_PREFIX = 'feature/document-'
COMMIT_PREFIX = 'Add documentation for'
```

---

## 🔄 Workflow Summary for Claude Code

```
INPUT: BigQuery table ID
  ↓
VALIDATE: Table exists & accessible
  ↓
GENERATE: Python script
  ↓
EXECUTE: Script (query + analyze)
  ↓
ENHANCE: Documentation descriptions
  ↓
VALIDATE: All fields complete
  ↓
COMMIT: Git commit with message
  ↓
PUSH: To GitHub (main or feature branch)
  ↓
OUTPUT: Documentation complete
  ↓
REPORT: Success/Failure status
```

---

## ✅ Success Criteria

Documentation is complete when:

✅ All 4 files created:
- `document_[TABLE_NAME].py` (script)
- `table_list/[TABLE_NAME].json` (sample data)
- `table_column_description/[TABLE_NAME]_doc.json` (documentation)
- Git commit created

✅ Quality checks pass:
- No [TODO] markers remain
- All descriptions clear and concise
- All business context filled in
- Example values are real data
- JSON validates correctly

✅ Git workflow complete:
- Files staged properly
- Commit message descriptive
- Pushed to GitHub
- Ready for PR review

---

## 📞 Support for Claude Code

When Claude Code encounters issues:

1. **Check this document** - Find the relevant section
2. **Use error handling matrix** - Find your error type
3. **Apply recommended solution** - Follow the steps
4. **Report status** - What succeeded, what failed
5. **Ask for help** - Involve data team lead if needed

---

**Last Updated**: 2026-04-23  
**Version**: 1.0  
**For**: Claude Code & AI Assistants  
**Status**: Production Ready ✅