# Cloud Audit Logs Setup for Query Analysis

> Use Cloud Audit Logs instead of JOBS_BY_PROJECT to extract query history

---

## ⚠️ Why Audit Logs?

The original approach using `INFORMATION_SCHEMA.JOBS_BY_PROJECT` has limitations:
- Not available in all BigQuery projects
- Region-specific access issues
- Requires special permissions

**Cloud Audit Logs** is the standard way Google Cloud logs all API calls, including BigQuery queries.

---

## 📋 Prerequisites (One-Time Setup)

### 1. Enable Cloud Audit Logs

1. Go to **Cloud Console** → **Audit Logs**
2. Search for **BigQuery API** in the list
3. Ensure these are enabled:
   - ✅ Admin Write
   - ✅ Data Write
   - ✅ Data Read

### 2. Verify Logs Are Flowing

1. Go to **Cloud Console** → **Logs**
2. Search for `resource.type="bigquery_project"`
3. Should see recent query entries

### 3. Export Logs to BigQuery (Recommended)

To make queries easier, export audit logs to BigQuery:

1. **Cloud Console** → **Logging** → **Sinks**
2. Click **Create Sink**
3. **Sink name**: `bigquery-audit-logs`
4. **Sink service**: Select your BigQuery project
5. **Dataset name**: `cloudaudit_googleapis_com_activity`
6. Click **Create Sink**

⏳ **Wait 5-10 minutes** for logs to start flowing

### 4. Verify Table Was Created

```sql
SELECT * FROM `ledger-fcc1e.cloudaudit_googleapis_com_activity`
LIMIT 10
```

---

## 🚀 Now Run the Setup

Once audit logs are configured, run in BigQuery:

```sql
-- Create the documentation dataset and metadata table
-- (Run 00_setup_and_init.sql first if you haven't already)
```

Then schedule the audit log-based queries:

### Scheduled Query 1: Table Relationships
- **File**: `01_create_table_relationships_audit.sql`
- **Name**: `daily-table-relationships-audit`
- **Schedule**: Daily at 02:00 UTC

### Scheduled Query 2: Query Patterns
- **File**: `02_create_column_usage_audit.sql`
- **Name**: `daily-query-patterns`
- **Schedule**: Daily at 02:15 UTC

---

## 📊 What Gets Created

### table_relationships
Tables that are joined together in the same query

```
table_a                 | table_b              | join_count
ledger-fcc1e.foo.table1 | ledger-fcc1e.foo.t2  | 87
```

### query_patterns
How frequently each table is queried

```
table_name     | total_queries | avg_queries_per_day | peak_query_hour
location_data  | 1,234         | 41.13               | 14
```

### filter_patterns
What types of filters are used across all queries

```
filter_type    | count | percentage
equality_filter| 4,567 | 45.2
comparison     | 3,210 | 32.1
```

---

## ⚡ Key Differences from JOBS_BY_PROJECT

| Feature | JOBS_BY_PROJECT | Cloud Audit Logs |
|---------|----------------|------------------|
| Availability | Limited/Regional | Universal |
| Setup | None | Enable + Export to BQ |
| Data Detail | High | Medium |
| Cost | Free | Free (within quota) |
| Query Lag | Real-time | 5-10 min delay |
| History | Last 180 days | Configurable |

---

## 🔍 Example Queries

### Find Most-Joined Tables
```sql
SELECT 
  table_a, 
  table_b, 
  join_count
FROM `ledger-fcc1e.data_documentation.table_relationships`
ORDER BY join_count DESC
LIMIT 10;
```

### Find Peak Usage Times
```sql
SELECT 
  table_name,
  peak_query_hour,
  total_queries,
  avg_queries_per_day
FROM `ledger-fcc1e.data_documentation.query_patterns`
ORDER BY total_queries DESC;
```

### Analyze Filter Types
```sql
SELECT 
  filter_type,
  count,
  percentage
FROM `ledger-fcc1e.data_documentation.filter_patterns`
ORDER BY count DESC;
```

---

## ⚙️ Troubleshooting

### "Table cloudaudit_googleapis_com_activity not found"
- Audit logs export sink might not be created yet
- Wait 10-15 minutes after creating the sink
- Verify sink was created: Cloud Console → Logging → Sinks

### "No data in table"
- Check audit logs are enabled (Cloud Console → Audit Logs)
- Verify sink is active and flowing
- Run a query in BigQuery to trigger logs

### "Permission denied"
- Need `roles/logging.viewer` for Audit Logs
- Need `roles/bigquery.dataEditor` for writing to dataset
- Contact your project admin

### "Query is too slow"
- Audit logs table can be large
- Add WHERE clause to limit time range:
  ```sql
  WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  ```

---

## 📈 Timeline

1. **Now**: Enable audit logs (5 min)
2. **Now**: Create sink to BigQuery (2 min)
3. **5-10 min**: Wait for logs to flow
4. **10 min**: Test connection to audit logs table
5. **10 min**: Set up scheduled queries
6. **Next day**: First results ready to use

---

## 💡 Tips

- **Start small**: Test one query first before scheduling
- **Monitor costs**: Audit logs can generate large queries - use time filters
- **Export logs**: Exporting to BigQuery makes scheduled queries faster and cheaper
- **Archive old logs**: Clean up old metadata rows periodically

---

## 🔄 Next Steps

1. Enable Cloud Audit Logs (if not already done)
2. Create BigQuery sink to export logs
3. Wait 5-10 minutes for logs to flow
4. Run test query on `cloudaudit_googleapis_com_activity`
5. Set up scheduled queries using the SQL files
6. Monitor first run (check Execution Details)

**Status**: Ready to setup ✅
