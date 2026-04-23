# BigQuery Table Documentation Repository

> **For Data Team Use** - Collaborative documentation system for BigQuery tables. Maintain comprehensive column-level documentation, sample data, and best practices for data governance.

---

## 📚 Overview

This repository serves as the **Single Source of Truth (SSOT)** for BigQuery table documentation. It enables the data team to:

- ✅ Document all columns with data types, descriptions, and business context
- ✅ Maintain 10,000+ row samples for data quality analysis
- ✅ Track data lineage and relationships between tables
- ✅ Provide clear guidance for business stakeholders querying the data
- ✅ Follow a standardized documentation process

---

## 📁 Repository Structure

```
├── README.md (This file - For data team)
├── HOW_TO_DOCUMENT_NEW_TABLES.md (Complete guide with Python scripts)
├── table_list.md (Original table references)
│
├── table_column_description/        📄 DOCUMENTATION FILES
│   ├── location_gmaps_static_opentable_doc.json (16 columns)
│   ├── mapping_area_mse_opentable_doc.json (10 columns)
│   ├── ms_merchant_profiling_ssot_opentable_doc.json (107 columns)
│   └── prod_edc_order_doc.json (36 columns)
│
└── table_list/                      💾 SAMPLE DATA (10K rows each)
    ├── location_gmaps_static_opentable.json (10,000 rows)
    ├── mapping_area_mse_opentable.json (1,086 rows - all)
    ├── ms_merchant_profiling_ssot_opentable.json (10,000 rows)
    └── prod_edc_order.json (10,000 rows)
```

---

## 🎯 Currently Documented Tables

| Table | Columns | Rows | Status |
|-------|---------|------|--------|
| `location_gmaps_static_opentable` | 16 | 10,000 | ✅ Complete |
| `mapping_area_mse_opentable` | 10 | 1,086 | ✅ Complete |
| `ms_merchant_profiling_ssot_opentable` | 107 | 10,000 | ✅ Complete |
| `prod_edc_order` | 36 | 10,000 | ✅ Complete |
| **TOTAL** | **169** | **31,086** | ✅ **Complete** |

---

## 🚀 Quick Start for Data Team

### 1. **View Documentation for a Table**

Each table has a corresponding `_doc.json` file in `table_column_description/`:

```bash
# View table structure
cat table_column_description/location_gmaps_static_opentable_doc.json | jq '.columns[] | {name: .column_name, type: .data_type, description}'

# Or use any JSON viewer for the complete documentation
```

### 2. **Check Sample Data**

Review 10,000 rows of actual data from each table:

```bash
cat table_list/location_gmaps_static_opentable.json | jq '.[0:5]'  # First 5 rows
```

### 3. **Understand Column Details**

Each column includes:
- **column_name**: Exact BigQuery column name
- **data_type**: STRING, INTEGER, ARRAY, JSON, etc.
- **nullable**: true/false
- **null_percentage**: % of NULL values in sample
- **description**: What this column stores
- **business_context**: How this column is used
- **example_values**: Real data samples

---

## 📝 How to Update Documentation

### Update Existing Table Documentation

1. **Open the documentation file** in `table_column_description/`:
   ```bash
   vim table_column_description/location_gmaps_static_opentable_doc.json
   ```

2. **Edit column descriptions** and business_context:
   ```json
   {
     "column_name": "area",
     "description": "Geographic area classification for operational grouping",
     "business_context": "Used for regional segmentation in analytics dashboards",
   }
   ```

3. **Commit and push** your changes:
   ```bash
   git add table_column_description/
   git commit -m "Update location_gmaps_static_opentable descriptions"
   git push origin main
   ```

### Update Sample Data

When table schema or data significantly changes:

```bash
python3 document_table.py ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable ./table_list
git add table_list/location_gmaps_static_opentable.json
git commit -m "Refresh location_gmaps_static_opentable sample data (10,000 rows)"
git push origin main
```

---

## ➕ How to Add a New Table

### Step 1: Follow the Complete Guide

Read the detailed guide with code examples:

```bash
cat HOW_TO_DOCUMENT_NEW_TABLES.md
```

### Step 2: Use the Automated Script

The quickest way using the provided Python script:

```bash
# Create a Python file with the documentation script
python3 document_table.py \
  ledger-fcc1e.your_dataset.your_table_name \
  ./table_column_description

python3 document_table.py \
  ledger-fcc1e.your_dataset.your_table_name \
  ./table_list
```

### Step 3: Enhance Documentation

Add meaningful descriptions and business context to each column:

```bash
vim table_column_description/your_table_name_doc.json
```

### Step 4: Commit and Push

```bash
git add table_column_description/your_table_name_doc.json
git add table_list/your_table_name.json
git commit -m "Add documentation for your_table_name table

- Documented all X columns
- Added 10,000 row sample
- Added business context and descriptions"
git push origin main
```

---

## 📋 Documentation Standards

All table documentation must follow this structure:

### Required Fields:

```json
{
  "table_name": "exact_table_name",
  "full_table_id": "project.dataset.table",
  "total_columns": 50,
  "sample_rows_analyzed": 10000,
  "documentation_generated": "2026-04-23T...",
  "columns": [
    {
      "column_name": "column_name",
      "data_type": "STRING|INTEGER|ARRAY|JSON|etc",
      "nullable": true/false,
      "null_percentage": 0.0,
      "description": "What this column stores",
      "business_context": "How/why this column is used",
      "example_values": ["example1", "example2", "example3"]
    }
  ]
}
```

### Best Practices:

✅ **DO:**
- Use exact BigQuery column names
- Include accurate null percentages from sample data
- Provide real example values from actual data
- Explain business purpose, not just technical definition
- Update when table schema changes
- Keep sample data fresh (refresh annually or after major changes)

❌ **DON'T:**
- Make up data types - verify from BigQuery
- Use vague descriptions
- Mix technical and business language
- Leave [TODO] markers in final documentation
- Delete old documentation without archiving

---

## 🔄 Collaboration Workflow

### For Small Updates:

```bash
git checkout -b update/column-descriptions
# Make edits
git add .
git commit -m "Update descriptions for [table_name]"
git push origin update/column-descriptions
# Create Pull Request on GitHub
```

### For New Tables:

```bash
git checkout -b feature/document-new-table-[name]
# Run documentation script
# Edit and enhance
git add .
git commit -m "Document [table_name] table"
git push origin feature/document-new-table-[name]
# Create Pull Request on GitHub
```

### Review Checklist:

- [ ] All columns are documented
- [ ] Data types are accurate
- [ ] Null percentages are based on sample data
- [ ] Descriptions are clear and non-technical
- [ ] Business context explains usage
- [ ] Example values are real data
- [ ] Sample data file included
- [ ] Commit message is descriptive

---

## 🛠️ Data Team Tools

### Query Schema Information:

```bash
# Get table schema from BigQuery
bq show --schema --format=prettyjson ledger-fcc1e.dataset.table_name

# Count rows
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) as rows FROM \`ledger-fcc1e.dataset.table_name\`"
```

### Python Scripts in Repository:

- `document_table.py` - Complete automated documentation
- `analyze_columns.py` - Analyze table structure (included in HOW_TO guide)
- See `HOW_TO_DOCUMENT_NEW_TABLES.md` for complete code

### Required Environment:

```bash
# Install BigQuery Python client
pip install google-cloud-bigquery

# Authenticate
gcloud auth application-default login
```

---

## 📊 Data Quality Metrics

Each documented table includes quality metrics:

- **Null percentage per column** - Data completeness
- **Data types** - Schema validation
- **Example values** - Data format verification
- **Sample rows analyzed** - Statistical confidence (10,000+ recommended)

Use these to understand data reliability before building reports.

---

## 🔗 Table Relationships

Document relationships to help stakeholders understand join logic:

```
location_gmaps_static_opentable
    ↓ (address, area, province)
ms_merchant_profiling_ssot_opentable
    ↓ (area, region)
mapping_area_mse_opentable

prod_edc_order
    ↓ (janus_account_id, business_type)
ms_merchant_profiling_ssot_opentable
```

Add relationship documentation to the table's `_doc.json` file.

---

## 🤝 Contributing

### To contribute to documentation:

1. **Fork or Clone** this repository
2. **Create a branch** for your changes (`feature/` or `update/` prefix)
3. **Follow documentation standards** (see section above)
4. **Test your documentation** with `document_table.py` script
5. **Commit with clear messages** describing what was added/updated
6. **Push to GitHub** and create a Pull Request
7. **Request review** from data team lead

### Commit Message Format:

```
[TYPE] Brief description (50 chars max)

Detailed explanation if needed:
- What was added/updated
- Why this change was made
- Any relevant context
```

Types: `[ADD]` `[UPDATE]` `[FIX]` `[DOCS]` `[REFRESH]`

---

## 📞 Support & Questions

### Common Questions:

**Q: How often should I update sample data?**  
A: Update annually or when table schema changes significantly

**Q: Can I document tables outside of ledger-fcc1e project?**  
A: Yes, but update the `full_table_id` field and ensure BigQuery access

**Q: What if a column doesn't have any description yet?**  
A: Use `[TODO] Add description` temporarily and complete during review

**Q: How do I know if my documentation is complete?**  
A: Use the verification script in `HOW_TO_DOCUMENT_NEW_TABLES.md`

---

## 📈 Version History

| Date | Changes | Author |
|------|---------|--------|
| 2026-04-23 | Initial setup with 4 tables (169 columns documented) | Data Team |

---

## 📞 Contact

- **Data Team Lead**: [Add contact info]
- **Repository**: https://github.com/nandaruanawijaya-coder/bq-table-desc
- **Related Docs**: See `HOW_TO_DOCUMENT_NEW_TABLES.md`

---

**Last Updated**: 2026-04-23  
**Status**: ✅ Ready for Data Team Use  
**License**: Internal Use
