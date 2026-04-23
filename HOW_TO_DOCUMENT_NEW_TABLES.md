# How to Document New BigQuery Tables

This guide explains the step-by-step process to create comprehensive column-level documentation for any BigQuery table, similar to what was done for the 4 tables in this project.

## Overview

The documentation process involves:
1. Querying 10,000 sample rows from the table
2. Analyzing the data to extract column information (names, types, nullability)
3. Creating detailed JSON documentation with descriptions and business context

---

## Prerequisites

- **BigQuery CLI** (`bq` command) - for initial validation
- **Python 3.7+** with `google-cloud-bigquery` library
- **Authentication** to BigQuery project

Check your setup:
```bash
bq ls --project_id=your-project-id
python3 -c "from google.cloud import bigquery; print('✓ BigQuery Python library installed')"
```

---

## Step 1: Identify Your Table

First, determine which table you want to document:

```
Format: project-id.dataset.table_name
Example: ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable
```

### Verify table exists and get row count:

```bash
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) as total_rows FROM \`project-id.dataset.table_name\`"
```

Example:
```bash
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) as total_rows FROM \`ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable\`"
# Output: total_rows
#         218416
```

---

## Step 2: Query 10,000 Sample Rows

Create a Python script to fetch sample data and save to JSON:

```python
from google.cloud import bigquery
import json

# Configuration
PROJECT_ID = 'ledger-fcc1e'  # Change to your project
TABLE_ID = 'ledger-fcc1e.datamart_opentable.your_table_name'  # Change table
OUTPUT_FILE = 'your_table_name.json'

# Query
client = bigquery.Client(project=PROJECT_ID)
query = f"SELECT * FROM `{TABLE_ID}` LIMIT 10000"
query_job = client.query(query)

# Convert to JSON
rows = list(query_job.result())
rows_list = [dict(row) for row in rows]

# Save
with open(OUTPUT_FILE, 'w') as f:
    json.dump(rows_list, f, indent=2, default=str)

print(f"✅ Saved {len(rows_list):,} rows to {OUTPUT_FILE}")
```

### Or use the batch script below for multiple tables:

```python
from google.cloud import bigquery
import json

client = bigquery.Client(project='ledger-fcc1e')

tables = [
    {
        'table_id': 'ledger-fcc1e.dataset_name.table_name_1',
        'output_file': 'table_name_1.json'
    },
    {
        'table_id': 'ledger-fcc1e.dataset_name.table_name_2',
        'output_file': 'table_name_2.json'
    }
]

for config in tables:
    print(f"⏳ Fetching {config['table_id']}...")
    
    query = f"SELECT * FROM `{config['table_id']}` LIMIT 10000"
    query_job = client.query(query)
    
    rows = list(query_job.result())
    rows_list = [dict(row) for row in rows]
    
    with open(config['output_file'], 'w') as f:
        json.dump(rows_list, f, indent=2, default=str)
    
    print(f"   ✅ Saved {len(rows_list):,} rows")
```

### Run it:
```bash
python3 fetch_sample_data.py
```

---

## Step 3: Generate Column Documentation

Once you have the sample data JSON file, create a Python script to analyze and document all columns:

```python
import json
import os
from collections import defaultdict

def analyze_data_type(value):
    """Determine data type of a value"""
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
        if len(value) > 50:
            return 'STRING (LONG)'
        return 'STRING'
    return 'UNKNOWN'

def get_sample_values(values, limit=3):
    """Get non-null sample values"""
    samples = []
    for v in values:
        if v is not None and len(samples) < limit:
            samples.append(v)
    return samples

def analyze_table(input_file, table_name, output_file):
    """Analyze table and create documentation"""
    print(f"Analyzing {table_name}...")
    
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    # Collect column information
    columns_info = defaultdict(lambda: {
        'types': defaultdict(int),
        'null_count': 0,
        'sample_values': [],
    })
    
    for row in data:
        if not isinstance(row, dict):
            continue
        for col, value in row.items():
            data_type = analyze_data_type(value)
            columns_info[col]['types'][data_type] += 1
            if value is None:
                columns_info[col]['null_count'] += 1
            else:
                columns_info[col]['sample_values'].append(value)
                if len(columns_info[col]['sample_values']) > 10:
                    columns_info[col]['sample_values'] = columns_info[col]['sample_values'][:10]
    
    # Build documentation
    doc = {
        "table_name": table_name,
        "total_columns": len(columns_info),
        "sample_rows_analyzed": len(data),
        "documentation_generated": datetime.now().isoformat(),
        "columns": []
    }
    
    for col in sorted(columns_info.keys()):
        info = columns_info[col]
        primary_type = max(info['types'].items(), key=lambda x: x[1])[0] if info['types'] else 'NULL'
        null_percentage = (info['null_count'] / len(data) * 100) if len(data) > 0 else 0
        
        col_doc = {
            "column_name": col,
            "data_type": primary_type,
            "nullable": True if null_percentage > 0 else False,
            "null_percentage": round(null_percentage, 2),
            "description": f"[TODO] Add description for {col}",
            "business_context": f"[TODO] Add business context for {col}",
            "example_values": get_sample_values(info['sample_values'], 3)
        }
        doc['columns'].append(col_doc)
    
    # Save
    with open(output_file, 'w') as f:
        json.dump(doc, f, indent=2, default=str)
    
    print(f"✅ Created {output_file} ({len(columns_info)} columns)")

# Usage
from datetime import datetime

analyze_table(
    input_file='your_table_name.json',
    table_name='your_table_name',
    output_file='your_table_name_doc.json'
)
```

### Run it:
```bash
python3 analyze_columns.py
```

This will create `your_table_name_doc.json` with all columns documented.

---

## Step 4: Enhance Documentation with Business Context

Edit the generated `_doc.json` file to add meaningful descriptions and business context for each column.

### Template for each column:

```json
{
  "column_name": "example_column",
  "data_type": "STRING",
  "nullable": true,
  "null_percentage": 5.2,
  "description": "Brief description of what this column contains",
  "business_context": "How this column is used in business operations",
  "example_values": ["value1", "value2", "value3"]
}
```

### Best practices for descriptions:

- **Description**: What data does this column store? (e.g., "Customer's first name", "Order creation timestamp")
- **Business Context**: Why is this data important? How is it used? (e.g., "Used for customer communication and reporting", "Tracks order lifecycle")
- **Example Values**: Real samples from the data to show format and content

---

## Step 5: Final Verification

Create a verification script to check your documentation:

```python
import json

def verify_documentation(doc_file):
    """Verify documentation completeness"""
    with open(doc_file, 'r') as f:
        doc = json.load(f)
    
    print(f"📋 TABLE: {doc['table_name']}")
    print(f"   Total Columns: {doc['total_columns']}")
    print(f"   Sample Rows: {doc['sample_rows_analyzed']}")
    
    missing_desc = 0
    missing_context = 0
    
    for col in doc['columns']:
        if '[TODO]' in col.get('description', ''):
            missing_desc += 1
        if '[TODO]' in col.get('business_context', ''):
            missing_context += 1
    
    print(f"\n   ✅ Columns with description: {doc['total_columns'] - missing_desc}/{doc['total_columns']}")
    print(f"   ✅ Columns with business context: {doc['total_columns'] - missing_context}/{doc['total_columns']}")
    
    if missing_desc > 0 or missing_context > 0:
        print(f"\n   ⚠️  {missing_desc + missing_context} columns need review")
    else:
        print(f"\n   ✅ Documentation complete!")

verify_documentation('your_table_name_doc.json')
```

---

## Complete Workflow Script

Here's a complete script that does Steps 2-3 together:

**File: `document_table.py`**

```python
#!/usr/bin/env python3
"""
Complete workflow to document a BigQuery table
Usage: python3 document_table.py <full_table_id> <output_folder>
Example: python3 document_table.py ledger-fcc1e.dataset.table_name ./docs
"""

import sys
import json
from google.cloud import bigquery
from collections import defaultdict
from datetime import datetime

def analyze_data_type(value):
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

def document_table(table_id, output_folder='.'):
    """
    Complete documentation workflow for a BigQuery table
    
    Args:
        table_id: Full table ID (project.dataset.table)
        output_folder: Where to save files
    """
    
    print(f"📊 Documenting table: {table_id}")
    
    # Extract table name for file naming
    table_name = table_id.split('.')[-1]
    sample_file = f"{output_folder}/{table_name}.json"
    doc_file = f"{output_folder}/{table_name}_doc.json"
    
    # Step 1: Fetch sample data
    print(f"⏳ Fetching 10,000 sample rows...")
    client = bigquery.Client()
    query = f"SELECT * FROM `{table_id}` LIMIT 10000"
    query_job = client.query(query)
    
    rows = list(query_job.result())
    rows_list = [dict(row) for row in rows]
    
    # Save sample data
    with open(sample_file, 'w') as f:
        json.dump(rows_list, f, indent=2, default=str)
    print(f"   ✅ Saved {len(rows_list):,} rows to {sample_file}")
    
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
        "table_name": table_name,
        "full_table_id": table_id,
        "total_columns": len(columns_info),
        "sample_rows_analyzed": len(rows_list),
        "documentation_generated": datetime.now().isoformat(),
        "columns": []
    }
    
    for col in sorted(columns_info.keys()):
        info = columns_info[col]
        primary_type = max(info['types'].items(), key=lambda x: x[1])[0] if info['types'] else 'NULL'
        null_percentage = (info['null_count'] / len(rows_list) * 100) if len(rows_list) > 0 else 0
        
        col_doc = {
            "column_name": col,
            "data_type": primary_type,
            "nullable": True if null_percentage > 0 else False,
            "null_percentage": round(null_percentage, 2),
            "description": f"[TODO] Add description",
            "business_context": f"[TODO] Add business context",
            "example_values": [v for v in info['sample_values'][:3] if v is not None]
        }
        doc['columns'].append(col_doc)
    
    # Save documentation
    with open(doc_file, 'w') as f:
        json.dump(doc, f, indent=2, default=str)
    print(f"   ✅ Created {doc_file}")
    
    print(f"\n✅ DOCUMENTATION COMPLETE")
    print(f"   Total columns: {doc['total_columns']}")
    print(f"   Sample rows: {len(rows_list):,}")
    print(f"\n📝 Next steps:")
    print(f"   1. Review {doc_file}")
    print(f"   2. Edit descriptions and business_context for each column")
    print(f"   3. Add [TODO] tags for missing information")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 document_table.py <table_id> [output_folder]")
        print("Example: python3 document_table.py ledger-fcc1e.dataset.table_name ./docs")
        sys.exit(1)
    
    table_id = sys.argv[1]
    output_folder = sys.argv[2] if len(sys.argv) > 2 else '.'
    
    document_table(table_id, output_folder)
```

**Run it:**
```bash
python3 document_table.py ledger-fcc1e.dataset.your_table_name ./output_folder
```

---

## File Organization

Recommended folder structure for documentation:

```
table-description/
├── table_column_description/           # All documentation files
│   ├── table_name_1_doc.json
│   ├── table_name_2_doc.json
│   └── ...
├── table_list/                          # 10,000 row samples
│   ├── table_name_1.json
│   ├── table_name_2.json
│   └── ...
├── HOW_TO_DOCUMENT_NEW_TABLES.md       # This guide
└── README.md                           # Quick reference
```

---

## Key Metrics to Track

In your documentation, include these metrics for each table:

```json
{
  "table_name": "...",
  "total_columns": 50,
  "sample_rows_analyzed": 10000,
  "documentation_generated": "2026-04-23T12:00:00",
  "data_quality_metrics": {
    "columns_with_nulls": 25,
    "columns_always_populated": 25,
    "average_null_percentage": 15.5
  }
}
```

---

## Column Documentation Checklist

For each column, ensure you have:

- [ ] Column name (exact from BigQuery)
- [ ] Data type (STRING, INTEGER, ARRAY, JSON, etc.)
- [ ] Nullable indicator
- [ ] Null percentage (from sample data)
- [ ] Clear description (what is stored)
- [ ] Business context (why it matters)
- [ ] 2-3 example values (from real data)
- [ ] Data quality notes (if applicable)

---

## Common Patterns

### Location/Geographic columns
```json
{
  "column_name": "address",
  "description": "Physical address in standard format",
  "business_context": "Used for merchant location verification and delivery routing",
  "example_values": ["123 Main St, Jakarta, Indonesia"]
}
```

### Date/Timestamp columns
```json
{
  "column_name": "created_at",
  "description": "Date and time when record was created",
  "business_context": "Tracks record creation for audit trail and timeline analysis",
  "example_values": ["2025-04-23 10:30:45"]
}
```

### Status/Flag columns
```json
{
  "column_name": "is_active",
  "description": "Flag indicating if merchant is currently active",
  "business_context": "Used to filter operational merchants in reports and analysis",
  "example_values": [true, false]
}
```

### Amount/Numeric columns
```json
{
  "column_name": "transaction_amount",
  "description": "Amount of transaction in IDR",
  "business_context": "Used for revenue reporting and financial reconciliation",
  "example_values": [50000, 100000, 1500000]
}
```

---

## Troubleshooting

### Issue: "Table not found"
```
Error: NotFound: Table project-id:dataset.table_name was not found
```
**Solution**: Verify the exact table name and dataset. Use `bq ls dataset_name` to list available tables.

### Issue: "Permission denied"
```
Error: Access Denied: BigQuery BigQuery: User does not have permission
```
**Solution**: Check your BigQuery authentication. Run `gcloud auth application-default login`

### Issue: "Quota exceeded"
```
Error: Quota exceeded for quota metric 'Query scans'
```
**Solution**: Wait a few minutes or reduce the sample size (use LIMIT 1000 instead of 10000)

---

## Questions?

Refer to:
- BigQuery documentation: https://cloud.google.com/bigquery/docs
- Python client: https://cloud.google.com/python/docs/reference/bigquery/latest
- This project's README.md for examples

---

**Last Updated**: 2026-04-23  
**Created for**: AI Query Assistant Documentation System