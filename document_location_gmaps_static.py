#!/usr/bin/env python3
"""Document ledger-fcc1e.trb_pymnts_derived.location_gmaps_static table"""

from google.cloud import bigquery
import json
from collections import defaultdict
from datetime import datetime

# Configuration
PROJECT_ID = 'ledger-fcc1e'
TABLE_ID = 'ledger-fcc1e.trb_pymnts_derived.location_gmaps_static'
TABLE_NAME = 'location_gmaps_static'

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
