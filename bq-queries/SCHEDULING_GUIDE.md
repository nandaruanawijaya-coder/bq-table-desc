# BigQuery Daily Query Extraction Setup Guide

> Schedule historical query analysis to run automatically every day in BigQuery

---

## 📋 Overview

The SQL files extract:
- **Table Relationships** - Which tables are joined together
- **Column Usage** - How columns are queried and filtered

These run once per day and update daily with fresh data from the last 30 days of queries.

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Run Setup Query (One Time)

1. Open BigQuery Console: https://console.cloud.google.com/bigquery
2. Click **Create Query** → paste entire contents of `00_setup_and_init.sql`
3. Click **Run**

This creates:
- `ledger-fcc1e.data_documentation` dataset
- `extraction_metadata` table (tracks all runs)

### Step 2: Verify Tables Created

```sql
SELECT * FROM `ledger-fcc1e.data_documentation.extraction_metadata`;
```

Should return 1 row with status = "completed"

### Step 3: Schedule Automated Runs

Create two scheduled queries in BigQuery:

#### Scheduled Query #1: Table Relationships

1. BigQuery Console → **Scheduled Queries** → **Create Scheduled Query**
2. Copy entire `01_create_table_relationships.sql` to the query editor
3. **Name**: `daily-table-relationships`
4. **Schedule**: Daily
5. **Time**: 02:00 UTC (2 AM - avoids peak hours)
6. **Destination dataset**: `ledger-fcc1e.data_documentation`
7. Click **Create**

#### Scheduled Query #2: Column Usage

1. **Scheduled Queries** → **Create Scheduled Query**
2. Copy entire `02_create_column_usage.sql` to the query editor
3. **Name**: `daily-column-usage`
4. **Schedule**: Daily
5. **Time**: 02:15 UTC (runs after #1 completes)
6. **Destination dataset**: `ledger-fcc1e.data_documentation`
7. Click **Create**

---

## 📊 What Gets Created

After scheduling, you'll have these daily tables:

| Table | Purpose | Rows | Updates |
|-------|---------|------|---------|
| `table_relationships` | Which tables join together | 1 per unique pair | Daily |
| `column_usage` | Table query frequency | 1 per table | Daily |
| `column_usage_patterns` | WHERE clause patterns | 1 per table | Daily |
| `extraction_metadata` | Run history | 2+ per day | Each run |

---

## 🔍 Query the Results

### Find Most-Used Tables
```sql
SELECT 
  table_a, 
  table_b, 
  join_count,
  LAST_joined
FROM `ledger-fcc1e.data_documentation.table_relationships`
ORDER BY join_count DESC
LIMIT 10;
```

### Find Peak Query Hours
```sql
SELECT 
  table_id,
  peak_query_hour,
  queries_per_day_avg,
  total_queries
FROM `ledger-fcc1e.data_documentation.column_usage`
ORDER BY total_queries DESC;
```

### Find Filter Patterns
```sql
SELECT 
  full_table_name,
  pct_equality_filters,
  pct_comparison_filters,
  pct_range_filters
FROM `ledger-fcc1e.data_documentation.column_usage_patterns`
WHERE queries_with_filters > 0
ORDER BY queries_with_filters DESC;
```

---

## ⚙️ Configuration Options

### Change Query Time Window

Want to analyze 60 days instead of 30? Edit the SQL files:

**Before:**
```sql
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
```

**After:**
```sql
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 DAY)
```

Then **update the scheduled query** with the modified SQL.

### Change Schedule Time

1. BigQuery Console → **Scheduled Queries**
2. Click the scheduled query name
3. Click **Edit**
4. Change **Recurrence pattern** or **Time**
5. Click **Update**

### Pause or Delete

1. **Scheduled Queries** → select the query
2. **Delete** or toggle **Pause**

---

## 🔔 Monitor Execution

### View Past Runs

1. **Scheduled Queries** → click scheduled query name
2. **Execution details** → see all past runs
3. Filter by status: `DONE`, `FAILED`, `RUNNING`

### Set Up Alerts (Optional)

If you want email notifications on failure:

1. **Scheduled Queries** → **Notifications**
2. Add email addresses
3. Choose: "Notify on all runs" or "Notify on failure only"

### Check for Errors

```sql
-- View recent extraction runs
SELECT 
  extraction_name,
  extraction_timestamp,
  status,
  description
FROM `ledger-fcc1e.data_documentation.extraction_metadata`
ORDER BY extraction_timestamp DESC
LIMIT 20;
```

---

## 📈 Integration with Table Documentation

Once the daily extraction is running, you can:

1. **Enhance column descriptions** using actual filter patterns
   - If a column appears in 80% of WHERE clauses, note this is a key filter

2. **Document table relationships** in the documentation JSON
   - Add "related_tables" field showing which tables are frequently joined

3. **Track usage trends** over time
   - Peak query hour helps understand when queries are most critical

---

## ⚠️ Common Issues

### "Table not found in location X"
- Check `00_setup_and_init.sql` was run
- Verify region in SQL file matches your location
- Check dataset `data_documentation` exists: `LIST DATASETS`

### "Permission denied"
- Need `roles/bigquery.dataEditor` on the dataset
- Need `roles/bigquery.jobUser` to query JOBS_BY_PROJECT
- Contact your BigQuery admin

### "Scheduled query not running"
- Check **Execution details** for error messages
- View **Logs** in Cloud Logging
- Verify connection string (project.dataset.table format)

### "No data returned"
- Queries look back 30 days - might be empty if no queries ran
- Check table is in `ledger-fcc1e` project
- Verify `referenced_tables` is populated in your queries

---

## 📝 Maintenance

### Weekly
- Check **Scheduled Queries** execution details
- Look for any `FAILED` runs in metadata table

### Monthly
- Review `extraction_metadata` to confirm daily runs completed
- Analyze trends from the 30-day window
- Update documentation with insights

### Quarterly
- Evaluate if 30-day window is still appropriate
- Consider archiving old metadata rows if table grows large
- Review table relationships for any new patterns

---

## 🔄 Next: Using Results in Documentation

Once scheduled, you can use these queries to:

1. **Enhance CLAUDE_CODE_AUTOMATION.md** to include related tables in documentation
2. **Add usage frequency** to column descriptions
3. **Document query patterns** for business stakeholders

See README.md for integration steps.

---

**Status**: Ready to schedule ✅  
**Time to setup**: ~5 minutes  
**Daily runtime**: ~2 minutes per query  
**Cost**: Minimal (scans JOBS_BY_PROJECT - usually under $1/day)
