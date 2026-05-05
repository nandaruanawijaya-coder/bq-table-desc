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
INPUT: User asks Claude Code to document tables from table_list.md
  ↓
STEP 0: Read table_list.md and check table_column_description/
  ↓
STEP 1: Filter tables - only process those NOT already documented
  ↓
STEP 2: For each missing table:
  ├─ Validate table access in BigQuery
  ├─ Generate Python script
  ├─ Execute script (10,000 rows)
  ├─ Analyze columns
  ├─ Create JSON documentation
  ├─ Enhance descriptions
  ├─ Validate quality
  └─ Commit to git
  ↓
OUTPUT: All missing tables documented and committed
```

---

## 📋 STEP 0: Read table_list.md and Filter

Claude Code MUST start here before processing any tables.

### 0.1 Read table_list.md

```bash
cat table_list.md
```

**Expected format**:
```markdown
# Tables to Document

- ledger-fcc1e.dataset.table_name_1
- ledger-fcc1e.dataset.table_name_2
- ledger-fcc1e.dataset.table_name_3
```

### 0.2 Parse Table List

Claude Code MUST:
1. Extract all table IDs from file
2. Ignore comment lines (starting with #)
3. Ignore empty lines
4. Create list of tables to process

**Example extraction**:
```
Tables found:
  - ledger-fcc1e.dataset.table_name_1
  - ledger-fcc1e.dataset.table_name_2
  - ledger-fcc1e.dataset.table_name_3
```

### 0.3 Check Already Documented

Claude Code MUST check which tables are already documented:

```bash
# List all documented tables
ls -1 table_column_description/*_doc.json | sed 's/.*\///' | sed 's/_doc.json//'
```

**Example**:
```
location_gmaps_static_opentable
mapping_area_mse_opentable
ms_merchant_profiling_ssot_opentable
prod_edc_order
```

### 0.4 Filter to Missing Tables Only

Claude Code MUST:
1. Compare table_list.md with documented tables
2. Keep only tables that DON'T have documentation yet
3. Report which tables will be processed

**Example**:
```
Table list: [table1, table2, table3, table4, table5]
Already documented: [table1, table3, table5]
Will process: [table2, table4]
```

### 0.5 Report Status

Claude Code MUST report:
- Total tables in list
- Already documented
- Will process
- Estimated time (10 min per table)

---

## 🔍 STEP 1: Validate Each Table

For each table from the filtered list (STEP 0), Claude Code MUST:

### 1.1 Verify Table Format

Validate the table ID format:
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

### 1.2 Validate BigQuery Access

For each table, verify it exists:

```bash
# Check if table exists and accessible
bq query --format=csv --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`project.dataset.table\` LIMIT 1"

# Expected: A number (row count)
# If error: Skip this table, report error, continue with next
```

### 1.3 Error Handling for Access Issues

If table is not accessible:
- ✅ Log error: "Table [name] - Access denied or not found"
- ✅ Continue with next table
- ✅ Report all inaccessible tables at end
- ❌ Do NOT stop entire process

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

def infer_description(col_name, data_type, sample_values, null_pct):
    """Auto-generate column description from data analysis"""
    col_lower = col_name.lower()
    
    # ID/Key columns
    if 'id' in col_lower and data_type == 'STRING':
        entity = col_name.replace('_id', '').replace('ID', '')
        return f"Unique identifier for {entity}"
    if 'code' in col_lower:
        return f"{col_name.replace('_', ' ').title()} - code/classification. Examples: {', '.join(str(v)[:20] for v in sample_values[:2])}"
    
    # Timestamp/Date columns
    if 'date' in col_lower or 'time' in col_lower or 'timestamp' in col_lower:
        return f"Timestamp of {col_name.replace('_', ' ')}. Format: YYYY-MM-DD HH:MM:SS"
    
    # Boolean columns
    if data_type == 'BOOLEAN':
        return f"Flag indicating {col_name.replace('_', ' ')} state (true/false)"
    
    # Numeric columns
    if data_type in ['INTEGER', 'NUMERIC', 'FLOAT']:
        if sample_values:
            val_range = f"Range: {min(float(v) for v in sample_values if isinstance(v, (int, float))):.0f} to {max(float(v) for v in sample_values if isinstance(v, (int, float))):.0f}"
        else:
            val_range = ""
        return f"{col_name.replace('_', ' ').title()} - numeric value. {val_range}".strip()
    
    # String/Text columns
    if data_type in ['STRING', 'STRING (LONG)']:
        if sample_values:
            examples = ', '.join(f"'{v}'" if isinstance(v, str) else str(v) for v in sample_values[:2])
            return f"{col_name.replace('_', ' ').title()} - text value. Examples: {examples}"
        return f"{col_name.replace('_', ' ').title()} - text/string value"
    
    # Default
    return f"{col_name.replace('_', ' ').title()} - {data_type} value"

def infer_business_context(col_name, null_pct, table_metrics=None):
    """Auto-generate business context from data patterns"""
    col_lower = col_name.lower()
    context_parts = []
    
    # Nullability context
    if null_pct >= 80:
        context_parts.append("Optional field - rarely populated")
    elif null_pct == 0:
        context_parts.append("Required field - always populated")
    elif null_pct > 50:
        context_parts.append("Sparse field - populated in minority of records")
    else:
        context_parts.append(f"Populated in {100-null_pct:.0f}% of records")
    
    # ID/Key context
    if 'id' in col_lower or 'key' in col_lower:
        context_parts.append("Used for joins and lookups")
    
    # Date context
    if 'date' in col_lower or 'time' in col_lower:
        context_parts.append("Used for time-based analysis and filtering")
    
    # Status/Flag context
    if 'status' in col_lower or 'flag' in col_lower or 'is_' in col_lower:
        context_parts.append("Used for segmentation and status-based filtering")
    
    # Add table context if available
    if table_metrics and table_metrics.get('total_queries_30_days', 0) > 0:
        context_parts.append(f"Table is actively queried ({table_metrics['total_queries_30_days']} queries/month)")
    
    return '. '.join(context_parts) + '.'

for col in sorted(columns_info.keys()):
    info = columns_info[col]
    primary_type = max(info['types'].items(), key=lambda x: x[1])[0] if info['types'] else 'NULL'
    null_pct = (info['null_count'] / len(rows_list) * 100) if len(rows_list) > 0 else 0
    
    col_doc = {
        "column_name": col,
        "data_type": primary_type,
        "nullable": True if null_pct > 0 else False,
        "null_percentage": round(null_pct, 2),
        "description": infer_description(col, primary_type, info['sample_values'], null_pct),
        "business_context": infer_business_context(col, null_pct),
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

### 3.1 Execution Steps (No .py files in repo)
```bash
# 1. Generate Python script as string
# 2. Execute it directly (don't save .py file)
# 3. Delete any .py files created
# 4. Check for errors and report status
```

### 3.2 Important: Don't Commit .py Files
- ✅ Execute scripts in memory or as temporary files
- ❌ DO NOT commit document_[TABLE_NAME].py files to git
- ✅ Clean up any temporary files after execution
- Files to delete after run: `document_*.py`, `enrich_*.py`

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

## ✏️ STEP 4: Auto-Generate & Enhance Documentation

Claude Code MUST enhance the generated `_doc.json` file by filling in all descriptions:

### 4.1 Auto-Generate Column Descriptions

**For EVERY column**, generate description based on**:

1. **Column name** - Infer meaning from name
2. **Data type** - Use type to describe format
3. **Nullability** - Is it optional or required?
4. **Example values** - Use real data from samples
5. **Null percentage** - How often is it empty?

**Algorithm**:
```
IF column_name matches pattern (user_id, customer_id, etc)
  → description = "Unique identifier for [entity]"
ELSE IF data_type = STRING
  → description = "[Column name] - free text value. Examples: [sample_values]"
ELSE IF data_type = INTEGER
  → description = "[Column name] - numeric identifier/count. Range: [min-max]"
ELSE IF data_type = DATE/TIMESTAMP
  → description = "[Column name] - timestamp/date. Format: YYYY-MM-DD..."
ELSE IF data_type = BOOLEAN
  → description = "[Column name] - flag indicating [true_state] or [false_state]"
ELSE IF data_type = ARRAY/JSON
  → description = "[Column name] - structured data containing [description of contents]"
ELSE
  → description = "Data value for [inferred_purpose]. Type: [data_type]"
```

### 4.2 Auto-Generate Business Context

**For EVERY column**, generate context based on**:

1. **Usage frequency** - How often appears in WHERE clauses
2. **Filter types** - What kind of filtering is done
3. **Nullability** - If 80%+ null → "optional/sparse", if 0% null → "required"
4. **Table metrics** - Is table critical? Used daily?
5. **Data quality** - Distribution, uniqueness, value patterns

**Algorithm**:
```
IF appears_in_where_clause >= 80%
  → "Critical dimension/filter. Used in [80%+] of queries for filtering/segmentation"
ELSE IF appears_in_where_clause >= 50%
  → "Primary filter dimension. Frequently used in queries for data subsetting"
ELSE IF appears_in_where_clause >= 20%
  → "Secondary dimension. Used in [20-50%] of queries for analysis"
ELSE IF null_percentage >= 80%
  → "Optional field - rarely populated. Provides supplementary information when available"
ELSE IF null_percentage == 0%
  → "Required field. Always present, essential for all records in this table"
ELSE
  → "Supporting field. Used for [context from name/type]. Present in [100-null%] of records"

IF table has high query_frequency (daily usage)
  ADD → "Used in high-frequency queries"
IF column name suggests ID/KEY
  ADD → "Used for joins and lookups with related tables"
```

### 4.3 Description Guidelines

✅ **Good Descriptions** (Auto-Generated):
- "Customer ID - Unique identifier for customers. Used in 95% of WHERE clauses"
- "Order date - Transaction timestamp in YYYY-MM-DD format. Examples: 2024-01-15, 2024-02-20"
- "Country code - ISO 3166 country code. Examples: ID, SG, TH, PH"
- "Is active - Boolean flag indicating active (1) or inactive (0) status"

❌ **Bad Descriptions**:
- "[TODO] Add description"
- "data" or "information" or "value"
- "Database column for storing X" (too technical)

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

## 🔗 STEP 4.5: Enrich with Query Analysis Data

Claude Code MUST enrich the documentation with insights from query history analysis tables.

### 4.5.1 Add Table-Level Relationship Data

Query the `table_relationships` table to find related tables:

```sql
SELECT 
  table_a, 
  table_b, 
  join_count,
  last_joined
FROM `ledger-fcc1e.data_documentation.table_relationships`
WHERE table_a = '[FULL_TABLE_ID]' 
  OR table_b = '[FULL_TABLE_ID]'
ORDER BY join_count DESC
LIMIT 10
```

Add to documentation JSON as:
```json
{
  "table_relationships": [
    {
      "related_table": "ledger-fcc1e.dataset.other_table",
      "join_frequency": 87,
      "relationship_type": "frequently_joined_with",
      "last_joined": "2026-05-05T14:30:00Z"
    }
  ]
}
```

### 4.5.2 Add Query Usage Metrics

Query the `table_usage` table for metrics:

```sql
SELECT 
  total_queries,
  select_queries,
  insert_queries,
  update_queries,
  delete_queries,
  peak_query_hour,
  days_active,
  last_queried
FROM `ledger-fcc1e.data_documentation.table_usage`
WHERE full_table_name = '[FULL_TABLE_ID]'
```

Add to documentation JSON as:
```json
{
  "query_metrics": {
    "total_queries_30_days": 1234,
    "select_operations": 1200,
    "insert_operations": 20,
    "update_operations": 10,
    "delete_operations": 4,
    "days_active_in_30_days": 23,
    "peak_query_hour": 14,
    "last_queried": "2026-05-05T14:30:00Z"
  }
}
```

### 4.5.3 Add Filter Pattern Data for Columns

For frequently filtered columns, query `query_patterns`:

```sql
SELECT 
  pct_equality_filters,
  pct_comparison_filters,
  pct_range_filters,
  pct_null_filters
FROM `ledger-fcc1e.data_documentation.query_patterns`
WHERE full_table_name = '[FULL_TABLE_ID]'
```

For each column, if it appears in filter patterns:
```json
{
  "column_name": "user_id",
  "filter_patterns": {
    "equality_filter_percentage": 45.2,
    "comparison_filter_percentage": 32.1,
    "range_filter_percentage": 22.7,
    "appears_in_where_clause_percentage": 100.0,
    "analysis_note": "Critical filter column - appears in 100% of WHERE clauses"
  }
}
```

### 4.5.4 Enhanced Documentation Schema

**Complete enriched JSON structure**:

```json
{
  "table_name": "location_gmaps_static_opentable",
  "full_table_id": "ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable",
  "total_columns": 16,
  "sample_rows_analyzed": 10000,
  "documentation_generated": "2026-05-05T14:30:00Z",
  "documentation_enriched": "2026-05-05T14:35:00Z",
  "table_business_context": "Read-only dimension table, regularly queried for analysis and reporting, with peak usage during afternoon hours, frequently joined with mapping and merchant tables.",
  
  "query_metrics": {
    "total_queries_30_days": 1234,
    "select_operations": 1200,
    "insert_operations": 20,
    "update_operations": 10,
    "delete_operations": 4,
    "days_active_in_30_days": 23,
    "peak_query_hour": 14,
    "last_queried": "2026-05-05T14:30:00Z"
  },
  
  "table_relationships": [
    {
      "related_table": "ledger-fcc1e.datamart_opentable.mapping_area_mse_opentable",
      "join_frequency": 87,
      "relationship_type": "frequently_joined_with",
      "last_joined": "2026-05-05T14:25:00Z"
    }
  ],
  
  "columns": [
    {
      "column_name": "location_id",
      "data_type": "STRING",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Unique identifier for location record",
      "business_context": "Primary key for location lookups. Used in all queries. Essential for mapping merchants to geographic areas.",
      "example_values": ["LOC_12345", "LOC_67890", "LOC_11111"],
      "filter_patterns": {
        "equality_filter_percentage": 98.5,
        "comparison_filter_percentage": 0,
        "range_filter_percentage": 1.5,
        "appears_in_where_clause_percentage": 100.0,
        "analysis_note": "Critical filter column - appears in 100% of WHERE clauses with equality operators"
      }
    }
  ]
}
```

### 4.5.5 Auto-Generate Business Context from Query Data

Claude Code SHOULD use query metrics to suggest business context:

**Rules for business context generation**:

1. **If column appears in 100% of WHERE clauses**:
   - Context: "Critical business filter - essential for all queries on this table"

2. **If column appears in 80%+ of WHERE clauses**:
   - Context: "Primary dimension/filter - used in majority of queries for data segmentation"

3. **If table is frequently joined (join_frequency > 100)**:
   - Context: "Core fact table - frequently joined with [list related tables] for unified reporting"

4. **If peak_query_hour is 14-17 (afternoon)**:
   - Context: "Used for afternoon business review/reporting cycles"

5. **If days_active is 30 (every day)**:
   - Context: "Critical operational table - queried daily for monitoring/operations"

6. **If only SELECT operations (no INSERT/UPDATE)**:
   - Context: "Read-only dimension table - used for lookup and analysis"

7. **If high INSERT count**:
   - Context: "Transaction logging table - captures operational events"

8. **Combine insights**:
   - "User dimension - queried 1,200+ times daily (peak 2-3 PM) for customer analysis and segmentation"
   - "Order facts - frequently joined with user and product tables for revenue reporting"

### 4.5.6 Python Code for Enrichment with Auto Context

Add this section to your documentation generation script:

```python
import json
from google.cloud import bigquery
from datetime import datetime

def generate_business_context(table_id, metrics, relationships):
    """Generate business context from query metrics"""
    context_parts = []
    
    if not metrics:
        return "[TODO] Add business context"
    
    total_queries = metrics.get('total_queries_30_days', 0)
    peak_hour = metrics.get('peak_query_hour')
    days_active = metrics.get('days_active_in_30_days', 0)
    
    # Determine table type and usage pattern
    if metrics['select_operations'] == total_queries:
        context_parts.append("Read-only dimension table")
    elif metrics['insert_operations'] > metrics['select_operations']:
        context_parts.append("Transaction/event logging table")
    else:
        context_parts.append("Fact table")
    
    # Add frequency context
    if days_active == 30:
        context_parts.append("queried daily")
    elif days_active >= 20:
        context_parts.append("regularly queried")
    elif days_active >= 10:
        context_parts.append("occasionally queried")
    
    # Add operation context
    if metrics['select_operations'] > total_queries * 0.9:
        context_parts.append("for analysis and reporting")
    elif metrics['insert_operations'] > 0:
        context_parts.append("for transaction tracking")
    
    # Add time context
    if peak_hour:
        if 8 <= peak_hour <= 12:
            context_parts.append("with peak usage during morning hours")
        elif 13 <= peak_hour <= 17:
            context_parts.append("with peak usage during afternoon hours")
        elif 18 <= peak_hour <= 23:
            context_parts.append("with peak usage during evening hours")
    
    # Add relationship context
    if relationships:
        related_tables = [r['related_table'].split('.')[-1] for r in relationships[:2]]
        context_parts.append(f"frequently joined with {', '.join(related_tables)}")
    
    # Combine into natural sentence
    if len(context_parts) >= 2:
        return f"{context_parts[0]}, {' and '.join(context_parts[1:])}."
    elif context_parts:
        return f"{context_parts[0]}."
    else:
        return "[TODO] Add business context"

def generate_column_context(column_name, filter_patterns, table_metrics):
    """Generate business context for a column based on filter patterns"""
    
    if not filter_patterns:
        return "[TODO] Add business context"
    
    pct_where = filter_patterns.get('appears_in_where_clause_percentage', 0)
    
    context_parts = []
    
    # Column usage importance
    if pct_where >= 80:
        context_parts.append("Critical dimension column")
    elif pct_where >= 50:
        context_parts.append("Primary filter column")
    elif pct_where >= 20:
        context_parts.append("Secondary filter column")
    elif pct_where > 0:
        context_parts.append("Occasionally filtered")
    else:
        context_parts.append("Supporting column")
    
    # Filter type usage
    pct_eq = filter_patterns.get('equality_filter_percentage', 0)
    pct_range = filter_patterns.get('range_filter_percentage', 0)
    
    if pct_eq > 0:
        context_parts.append(f"used for equality matching ({pct_eq}% of filters)")
    if pct_range > pct_eq and pct_range > 0:
        context_parts.append(f"used for range queries ({pct_range}% of filters)")
    
    # Add usage frequency if available
    if table_metrics and table_metrics.get('total_queries_30_days', 0) > 0:
        context_parts.append(f"in {table_metrics['total_queries_30_days']}+ monthly queries")
    
    if len(context_parts) >= 2:
        return f"{context_parts[0]}, {' and '.join(context_parts[1:])}."
    elif context_parts:
        return f"{context_parts[0]}."
    else:
        return "[TODO] Add business context"

def enrich_documentation(table_id, doc_file):
    """Enrich documentation with query analysis data"""
    client = bigquery.Client(project='ledger-fcc1e')
    
    # Load existing documentation
    with open(doc_file, 'r') as f:
        doc = json.load(f)
    
    # 1. Get table relationships
    rel_query = f"""
    SELECT table_a, table_b, join_count, last_joined
    FROM `ledger-fcc1e.data_documentation.table_relationships`
    WHERE table_a = '{table_id}' OR table_b = '{table_id}'
    ORDER BY join_count DESC
    LIMIT 10
    """
    rel_results = list(client.query(rel_query).result())
    
    relationships = []
    for row in rel_results:
        related = row['table_b'] if row['table_a'] == table_id else row['table_a']
        relationships.append({
            "related_table": related,
            "join_frequency": row['join_count'],
            "relationship_type": "frequently_joined_with",
            "last_joined": row['last_joined'].isoformat() if row['last_joined'] else None
        })
    
    if relationships:
        doc['table_relationships'] = relationships
        doc['documentation_enriched'] = datetime.now().isoformat()
    
    # 2. Get query metrics
    metrics_query = f"""
    SELECT *
    FROM `ledger-fcc1e.data_documentation.table_usage`
    WHERE full_table_name = '{table_id}'
    LIMIT 1
    """
    metrics_result = list(client.query(metrics_query).result())
    
    if metrics_result:
        row = metrics_result[0]
        doc['query_metrics'] = {
            "total_queries_30_days": row['total_queries'],
            "select_operations": row['select_queries'],
            "insert_operations": row['insert_queries'],
            "update_operations": row['update_queries'],
            "delete_operations": row['delete_queries'],
            "days_active_in_30_days": row['days_active'],
            "peak_query_hour": row['peak_query_hour'],
            "last_queried": row['last_queried'].isoformat() if row['last_queried'] else None
        }
    
    # 3. Generate business context from metrics
    if 'query_metrics' in doc:
        # Update table-level business_context if empty
        table_context = generate_business_context(
            table_id, 
            doc['query_metrics'], 
            doc.get('table_relationships', [])
        )
        if '[TODO]' in doc.get('table_business_context', '[TODO]'):
            doc['table_business_context'] = table_context
        
        # Update column-level business_context if empty
        for col in doc['columns']:
            if '[TODO]' in col.get('business_context', '[TODO]'):
                col_context = generate_column_context(
                    col['column_name'],
                    col.get('filter_patterns'),
                    doc['query_metrics']
                )
                col['business_context'] = col_context
    
    # Save enriched documentation
    with open(doc_file, 'w') as f:
        json.dump(doc, f, indent=2, default=str)
    
    print(f"✅ Documentation enriched with query analysis data")
    if relationships:
        print(f"   - Found {len(relationships)} related tables")
    if 'query_metrics' in doc:
        print(f"   - Added query metrics ({doc['query_metrics']['total_queries_30_days']} queries in 30 days)")
        print(f"   - Auto-generated business context from query patterns")

# Call enrichment after creating documentation
enrich_documentation(TABLE_ID, doc_file)
```

### 4.5.6 Enrichment Checklist

Claude Code MUST verify:
- ✅ Table exists in `table_relationships` (may be 0 if no joins)
- ✅ Table exists in `table_usage` (should always exist if queried)
- ✅ Query metrics added if table has queries
- ✅ Related tables added if table is frequently joined
- ✅ Filter patterns added for filter columns
- ✅ New `documentation_enriched` timestamp added
- ✅ Enhanced JSON is valid

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
  ☑️ filter_patterns: If present, has valid percentages (0-100)

For document:
  ☑️ JSON is valid (no syntax errors)
  ☑️ All required fields present
  ☑️ table_name matches filename
  ☑️ total_columns > 0
  ☑️ sample_rows_analyzed > 0

For enrichment:
  ☑️ documentation_enriched: Timestamp if enriched
  ☑️ query_metrics: If table has query history
  ☑️ table_relationships: If table is frequently joined
  ☑️ All numeric metrics are valid (non-negative integers)

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
warnings = []

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

# Check enrichment data
if 'query_metrics' not in doc:
    warnings.append("No query metrics - table may not have query history")
if 'table_relationships' not in doc:
    warnings.append("No table relationships - table may not be frequently joined")
    
# Validate query metrics if present
if 'query_metrics' in doc:
    metrics = doc['query_metrics']
    if not isinstance(metrics.get('total_queries_30_days'), int):
        errors.append("query_metrics.total_queries_30_days must be integer")
    if metrics.get('total_queries_30_days', 0) > 0 and not metrics.get('peak_query_hour'):
        warnings.append("Table has queries but no peak_query_hour")

if errors:
    print("❌ Validation errors:")
    for error in errors:
        print(f"  - {error}")
else:
    print("✅ Documentation is complete and valid!")
    print(f"   Columns: {len(doc['columns'])}")
    print(f"   Sample rows: {doc['sample_rows_analyzed']:,}")
    
    if 'query_metrics' in doc:
        print(f"   Query usage: {doc['query_metrics']['total_queries_30_days']} queries in 30 days")
    if 'table_relationships' in doc:
        print(f"   Related tables: {len(doc['table_relationships'])}")

if warnings:
    print("\n⚠️  Warnings:")
    for warning in warnings:
        print(f"  - {warning}")
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