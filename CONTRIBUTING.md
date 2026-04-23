# Contributing Guide for Data Team

> Contribute to BigQuery table documentation and help maintain our data governance standards.

---

## 🎯 Before You Start

- Have **BigQuery access** to the tables you're documenting
- Have **Python 3.7+** with `google-cloud-bigquery` installed
- Have **Git** configured with GitHub access
- Read the main `README.md` for repository overview

---

## 📝 Types of Contributions

### 1. **Document a New Table** 
   - Follow [Step-by-Step Guide](#step-by-step-new-table-documentation) below
   - Expected time: 30-60 minutes per table
   - Creates: `_doc.json` file + 10,000 row sample data

### 2. **Update Existing Documentation**
   - Improve descriptions or business context
   - Add missing information or fix errors
   - Refresh sample data when table changes
   - Expected time: 5-15 minutes

### 3. **Improve Documentation Quality**
   - Add data quality metrics
   - Document table relationships
   - Create usage examples
   - Expected time: 15-30 minutes

---

## ⚡ Quick Start: Update Existing Table

### 1. Clone the repository
```bash
git clone https://github.com/nandaruanawijaya-coder/bq-table-desc.git
cd bq-table-desc
```

### 2. Create a branch
```bash
git checkout -b update/[table-name]-descriptions
```

### 3. Edit the documentation file
```bash
vim table_column_description/[table_name]_doc.json
```

### 4. Commit your changes
```bash
git add table_column_description/[table_name]_doc.json
git commit -m "Update [table_name] column descriptions"
```

### 5. Push and create PR
```bash
git push origin update/[table-name]-descriptions
```

---

## 📚 Step-by-Step: New Table Documentation

### Step 1: Verify Table Access

```bash
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) as rows FROM \`project.dataset.table_name\` LIMIT 1"
```

### Step 2: Create Branch

```bash
git checkout -b feature/document-[table_name]
```

### Step 3: Use the Automated Documentation Script

The easiest way is to use the Python script in `HOW_TO_DOCUMENT_NEW_TABLES.md`:

```python
from google.cloud import bigquery
import json

client = bigquery.Client(project='ledger-fcc1e')

TABLE_ID = 'ledger-fcc1e.your_dataset.your_table'
OUTPUT_FILE = 'your_table_name.json'

query = f"SELECT * FROM `{TABLE_ID}` LIMIT 10000"
query_job = client.query(query)

rows = list(query_job.result())
rows_list = [dict(row) for row in rows]

with open(OUTPUT_FILE, 'w') as f:
    json.dump(rows_list, f, indent=2, default=str)

print(f"✅ Saved {len(rows_list):,} rows")
```

### Step 4: Generate Documentation

Use the complete script provided in `HOW_TO_DOCUMENT_NEW_TABLES.md` to auto-generate `_doc.json` file.

### Step 5: Fill in Descriptions

Replace `[TODO]` markers with real descriptions:

```json
{
  "column_name": "created_at",
  "description": "Timestamp when transaction was created",
  "business_context": "Used for transaction timeline analysis and date-based reporting"
}
```

### Step 6: Commit

```bash
git add table_column_description/[table_name]_doc.json
git add table_list/[table_name].json
git commit -m "Add documentation for [table_name] table

- Documented X columns
- Added 10,000 row sample"
```

### Step 7: Push and Create PR

```bash
git push origin feature/document-[table_name]
```

---

## ✅ Quality Checklist

- [ ] All columns documented (no [TODO] markers)
- [ ] Data types match BigQuery
- [ ] Null percentages from actual sample
- [ ] Example values are real data
- [ ] Business context explains usage
- [ ] Sample data file included
- [ ] JSON is valid
- [ ] Commit message is clear

---

## 📞 Questions?

- See `HOW_TO_DOCUMENT_NEW_TABLES.md` for detailed guide
- Ask data team lead for BigQuery help

---

**Last Updated**: 2026-04-23