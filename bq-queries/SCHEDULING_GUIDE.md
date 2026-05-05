# BigQuery Query Analysis - Scheduling Guide

> Schedule the analysis queries to run daily from your pre-populated query_history table

---

## 🚀 Quick Setup (5 minutes)

### 1. Run Setup Query (One Time)

Copy and run `00_setup_and_init.sql` in BigQuery Console. This creates the metadata tracking table.

```sql
-- Verify query_history exists
SELECT COUNT(*) FROM `ledger-fcc1e.data_documentation.query_history`;
```

Should return a row count showing your query history.

### 2. Create Scheduled Queries

Open **BigQuery Console** → **Scheduled Queries** → **Create Scheduled Query**

#### Query 1: Table Relationships

- **Query code**: Copy entire `01_create_table_relationships.sql`
- **Name**: `daily-table-relationships`
- **Destination project**: `ledger-fcc1e`
- **Destination dataset**: `data_documentation`
- **Schedule**: `Every day`
- **Time**: `02:00` UTC
- Click **Create**

#### Query 2: Table Usage & Patterns

- **Query code**: Copy entire `02_create_column_usage.sql`
- **Name**: `daily-table-usage`
- **Destination project**: `ledger-fcc1e`
- **Destination dataset**: `data_documentation`
- **Schedule**: `Every day`
- **Time**: `02:15` UTC (runs 15 minutes after Query 1)
- Click **Create**

### 3. Done ✅

Queries will run automatically every day at the scheduled times.

---

## 📊 Output Tables

### table_relationships
Which tables are joined together in queries

```
table_a                 | table_b              | join_count | days_active
ledger-fcc1e.foo.table1 | ledger-fcc1e.foo.t2  | 87         | 23
```

### table_usage
How frequently each table is queried

```
full_table_name        | total_queries | select_queries | peak_query_hour
ledger-fcc1e.foo.users | 1,234         | 1,200          | 14
```

### query_patterns
What types of filters and operations are used

```
full_table_name | queries_with_where | pct_equality | pct_comparison | aggregation_queries
ledger-fcc1e... | 456                | 45.2         | 32.1           | 78
```

---

## 🔍 Query the Results

### Find Most Joined Table Pairs
```sql
SELECT 
  table_a, 
  table_b, 
  join_count,
  last_joined
FROM `ledger-fcc1e.data_documentation.table_relationships`
ORDER BY join_count DESC
LIMIT 10;
```

### Find Most Queried Tables
```sql
SELECT 
  full_table_name,
  total_queries,
  select_queries,
  peak_query_hour,
  days_active
FROM `ledger-fcc1e.data_documentation.table_usage`
ORDER BY total_queries DESC
LIMIT 20;
```

### Analyze Filter Patterns for a Table
```sql
SELECT 
  full_table_name,
  queries_with_where,
  pct_equality_filters,
  pct_comparison_filters,
  pct_range_filters,
  aggregation_queries
FROM `ledger-fcc1e.data_documentation.query_patterns`
WHERE full_table_name LIKE '%your_table_name%'
ORDER BY queries_with_where DESC;
```

---

## ⏱️ Monitor Execution

1. **BigQuery Console** → **Scheduled Queries**
2. Click the scheduled query name
3. **Execution history** → View past runs
4. Check for any `FAILED` status

To view error details:
```sql
SELECT 
  extraction_name,
  extraction_timestamp,
  description,
  status
FROM `ledger-fcc1e.data_documentation.extraction_metadata`
ORDER BY extraction_timestamp DESC
LIMIT 20;
```

---

## 📈 Integration with Table Documentation

Use the extracted insights to enhance your table documentation:

1. **From table_relationships**: Document which tables are frequently joined
2. **From table_usage**: Note most-accessed tables and peak query hours
3. **From query_patterns**: Highlight common WHERE clause patterns and filters

Example: If a table appears in 100% of WHERE clauses with equality filters, document it as:
```json
"description": "Primary filter column - present in 100% of WHERE clauses",
"business_context": "Used to segment all queries, critical for filtering"
```

---

## ⚙️ Customization

### Change Schedule Time

1. **Scheduled Queries** → Select the query
2. Click **Edit**
3. Modify **Recurrence pattern** or **Time**
4. Click **Update**

### Change Query Frequency

Want to run more often? Change the schedule to:
- Hourly: `Every 1 hour`
- Every 6 hours: `Every 6 hours`
- Custom: Set specific times

---

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| "Table query_history not found" | Verify query_history was created and populated |
| "Permission denied" | Need `roles/bigquery.dataEditor` on data_documentation dataset |
| "Scheduled query not running" | Check **Execution history** for error messages |
| "No data in output tables" | Check query_history has data; might be initial delay |

---

## 📝 Maintenance

### Weekly
- Check scheduled query execution history for failures
- Monitor extraction_metadata table for any errors

### Monthly
- Review table relationships for new patterns
- Analyze query patterns for optimization opportunities
- Update documentation with new insights

---

**Status**: Ready to schedule ✅  
**Time to setup**: ~5 minutes  
**Data source**: `query_history` table  
**Execution time**: ~30-60 seconds per query
