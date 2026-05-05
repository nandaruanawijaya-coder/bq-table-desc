# Enriched Table Documentation Guide

> Documentation now includes query history insights - relationships, usage patterns, and filter analysis

---

## 📈 What's New

Your table documentation is now enriched with actual query usage data:

### Query Metrics
- Total queries in last 30 days
- Breakdown: SELECT, INSERT, UPDATE, DELETE operations
- Peak query hour
- Days table was actively queried
- Last query timestamp

### Table Relationships
- Which tables are frequently joined with this table
- Join frequency (number of times joined)
- When tables were last joined together

### Filter Patterns
- For key columns: percentage appearing in WHERE clauses
- Filter types: equality, comparison, range, null checks
- Identifies which columns are critical filters

---

## 🆕 Enhanced JSON Schema

### Complete Structure

```json
{
  "table_name": "table_name_only",
  "full_table_id": "project.dataset.table",
  "total_columns": 16,
  "sample_rows_analyzed": 10000,
  "documentation_generated": "2026-05-05T14:30:00Z",
  "documentation_enriched": "2026-05-05T14:35:00Z",
  
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
      "related_table": "project.dataset.other_table",
      "join_frequency": 87,
      "relationship_type": "frequently_joined_with",
      "last_joined": "2026-05-05T14:25:00Z"
    }
  ],
  
  "columns": [
    {
      "column_name": "user_id",
      "data_type": "STRING",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Unique identifier for user",
      "business_context": "Primary key used for user identification",
      "example_values": ["USR_001", "USR_002", "USR_003"],
      "filter_patterns": {
        "equality_filter_percentage": 98.5,
        "comparison_filter_percentage": 0.0,
        "range_filter_percentage": 1.5,
        "appears_in_where_clause_percentage": 100.0,
        "analysis_note": "Critical filter column"
      }
    }
  ]
}
```

### Field Explanations

#### query_metrics
- `total_queries_30_days`: Total SQL queries referencing this table
- `select_operations`: Queries using SELECT (reads)
- `insert_operations`: Queries using INSERT (writes)
- `update_operations`: Queries using UPDATE (modifications)
- `delete_operations`: Queries using DELETE (removals)
- `days_active_in_30_days`: Number of distinct days table was queried
- `peak_query_hour`: Hour of day with most queries (0-23)
- `last_queried`: Most recent query timestamp

#### table_relationships
Array of tables frequently joined with this table
- `related_table`: Full table ID (project.dataset.table)
- `join_frequency`: Number of queries joining these tables
- `relationship_type`: Always "frequently_joined_with"
- `last_joined`: Most recent join query timestamp

#### filter_patterns (per column)
Shown for columns frequently used in WHERE clauses
- `equality_filter_percentage`: % of WHERE clauses using = or !=
- `comparison_filter_percentage`: % using >, <, >=, <=
- `range_filter_percentage`: % using BETWEEN, IN, LIKE
- `appears_in_where_clause_percentage`: % of WHERE clauses mentioning column
- `analysis_note`: Human-readable summary (e.g., "Critical filter column")

---

## 🚀 How to Re-Generate Documentation

### Step 1: Delete Existing Documentation

```bash
# Remove old documentation files
rm table_column_description/*_doc.json
rm table_list/*.json
rm document_*.py
```

### Step 2: Ask Claude Code to Re-Document

Use Claude Code with this prompt:

```
Document all tables in table_list.md that don't have 
documentation in table_column_description/ yet.

Follow CLAUDE_CODE_AUTOMATION.md for the complete workflow.
The workflow now includes enrichment with query analysis data from:
- table_relationships
- table_usage
- query_patterns

Replace any placeholder variables with actual values.
```

### Step 3: What Claude Code Will Do

1. **Read** table_list.md
2. **Filter** to tables without documentation
3. **For each table**:
   - Validate table access
   - Generate Python script
   - Execute script (fetch 10,000 rows)
   - Analyze all columns
   - Generate JSON documentation
   - **Enrich with query metrics** ← NEW
   - **Add related tables** ← NEW
   - **Add filter patterns** ← NEW
   - Enhance descriptions
   - Validate quality
   - Commit to git
4. **Report** completion with metrics

---

## 📊 Using the Enriched Data

### For Data Analysts
- **Peak Hours**: Know when to query (off-peak = better performance)
- **Usage Patterns**: Understand which tables are heavily used
- **Relationships**: See data dependencies clearly documented

### For Stakeholders
- **Query Frequency**: "This table is queried 1,200+ times per month"
- **Filter Usage**: "This column is used in 100% of queries"
- **Related Data**: "Always joined with these other tables"

### For Optimization
- **Peak Hour Analysis**: Schedule heavy processing off-peak
- **Join Patterns**: Optimize queries based on actual join patterns
- **Filter Columns**: Index the columns that appear in 100% of WHERE clauses

---

## 📝 Example Documentation Output

### Before (Basic)
```json
{
  "column_name": "merchant_id",
  "data_type": "STRING",
  "nullable": false,
  "description": "Merchant identifier",
  "business_context": "Used for merchant identification"
}
```

### After (Enriched)
```json
{
  "column_name": "merchant_id",
  "data_type": "STRING",
  "nullable": false,
  "description": "Unique merchant identifier",
  "business_context": "Primary key for all merchant-level analysis and reporting",
  "filter_patterns": {
    "equality_filter_percentage": 95.3,
    "appears_in_where_clause_percentage": 100.0,
    "analysis_note": "Critical filter - appears in all queries on this table"
  }
}
```

With table metrics:
```json
{
  "query_metrics": {
    "total_queries_30_days": 4567,
    "select_operations": 4500,
    "peak_query_hour": 14,
    "days_active_in_30_days": 30
  },
  "table_relationships": [
    {
      "related_table": "ledger-fcc1e.db_sales.orders",
      "join_frequency": 3456
    },
    {
      "related_table": "ledger-fcc1e.db_sales.transactions",
      "join_frequency": 1200
    }
  ]
}
```

---

## ✅ Enrichment Quality Checklist

After re-generation, verify:

- ✅ All tables have `query_metrics` (if they have query history)
- ✅ `table_relationships` populated for frequently-joined tables
- ✅ Filter columns have `filter_patterns` section
- ✅ Peak query hours make sense (usually 8-17 for business hours)
- ✅ Total queries matches expected usage pattern
- ✅ Related tables are actually related (manual spot check)

---

## 🎯 Next Steps

1. **Delete** existing documentation files (see Step 1 above)
2. **Ask Claude Code** to re-document all tables
3. **Wait** ~10-15 minutes (10 minutes per table)
4. **Review** the enriched documentation
5. **Commit** to repository

---

## 📞 Common Questions

**Q: Will enrichment slow down documentation generation?**  
A: Enrichment adds ~2-3 minutes per table (3-4 SQL queries). Total time: ~12-13 min per table instead of 10.

**Q: What if a table has no query history?**  
A: Claude Code will skip the enrichment step and note it in validation warnings.

**Q: Can I update enrichment without re-generating documentation?**  
A: Not yet - current process regenerates everything. Future versions may support incremental enrichment.

**Q: How often should I re-generate?**  
A: When: new tables added, or monthly to refresh query metrics. How: same process (delete + regenerate).

---

**Status**: Ready to regenerate ✅  
**New feature**: Query analysis enrichment  
**Backward compatible**: Yes (old docs still work, just without enrichment)  
**Time to completion**: ~10-15 minutes per table
