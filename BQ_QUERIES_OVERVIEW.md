# BigQuery Query Analysis - Complete Setup

> SQL files for daily historical query extraction - committed and ready to schedule

---

## 📦 What's Included

### SQL Files (in `bq-queries/`)

**Recommended: Cloud Audit Logs** (Works on all BigQuery projects)

| File | Purpose | Runs Daily | Output Tables |
|------|---------|-----------|---|
| **00_setup_and_init.sql** | One-time setup | No | Creates `data_documentation` dataset |
| **01_create_table_relationships_audit.sql** | Find table joins | Yes ✅ | `table_relationships` |
| **02_create_column_usage_audit.sql** | Analyze query patterns | Yes ✅ | `query_patterns`, `filter_patterns` |

**Alternative: JOBS_BY_PROJECT** (If JOBS_BY_PROJECT is available in your project)

| File | Purpose | Status |
|------|---------|--------|
| 01_create_table_relationships.sql | Original version | Works if JOBS_BY_PROJECT accessible |
| 02_create_column_usage.sql | Original version | Works if JOBS_BY_PROJECT accessible |

### Documentation

| File | Purpose |
|------|---------|
| **SETUP_AUDIT_LOGS.md** | ⭐ Use this - Cloud Audit Logs setup (RECOMMENDED) |
| **SCHEDULING_GUIDE.md** | Original setup guide (backup option) |
| **This file** | Overview and quick reference |

---

## ⚡ Quick Start

### 1. Enable Cloud Audit Logs (5 minutes)
Follow **SETUP_AUDIT_LOGS.md**:
- Enable audit logs in Cloud Console
- Create BigQuery export sink
- Wait for logs to flow (5-10 min)

### 2. Run Setup Query (2 minutes)
Copy `00_setup_and_init.sql` to BigQuery Console and run

### 3. Schedule Daily Runs (5 minutes)

Open BigQuery Console → **Scheduled Queries** → **Create Scheduled Query**

**Query 1: Table Relationships**
- SQL: `01_create_table_relationships_audit.sql`
- Name: `daily-table-relationships`
- Time: 02:00 UTC daily

**Query 2: Query Patterns**
- SQL: `02_create_column_usage_audit.sql`
- Name: `daily-query-patterns`
- Time: 02:15 UTC daily

### 4. Done ✅
Tables update automatically every day (next day)

---

## 📊 What Gets Extracted

### Table Relationships
Shows which tables are joined together in queries

```
table_a                 | table_b              | join_count | last_joined
ledger-fcc1e.foo.table1 | ledger-fcc1e.foo.t2  | 87         | 2026-05-05
```

**Useful for**: Understanding data flow, documenting dependencies

### Column Usage
How frequently each table is queried and from where

```
table_id       | total_queries | select_queries | queries_per_day_avg | peak_query_hour
location_data  | 1,234         | 1,200          | 41.13               | 14
```

**Useful for**: Understanding critical columns, query patterns

### Column Usage Patterns
What types of filters are applied to which columns

```
table_name | queries_with_filters | pct_equality | pct_comparison | pct_range
location   | 456                  | 45.2         | 32.1           | 22.7
```

**Useful for**: Documenting common filters, optimization hints

---

## ✅ Cloud Audit Logs Approach

**Advantages**:
- ✅ Works on all BigQuery projects
- ✅ No region-specific issues
- ✅ Industry standard logging
- ✅ 5-10 minute data freshness

**Setup time**: ~15 minutes total
- Enable audit logs: 2 min
- Create BigQuery sink: 2 min
- Wait for logs to flow: 5-10 min
- Schedule queries: 5 min

See SETUP_AUDIT_LOGS.md for detailed steps

---

## 📈 Integration with Documentation

Once scheduled, use these insights to enhance your table documentation:

1. **Table Relationships** → Add to `description` field which tables are frequently joined
2. **Column Usage** → Note columns that appear in 80%+ of queries
3. **Filter Patterns** → Document common filters for each column

Example: If a column is used in 100% of WHERE clauses, document it as:
```json
"description": "Primary filter key - appears in 100% of WHERE clauses",
"business_context": "Essential for all query filters"
```

---

## 🚀 Next Steps

1. **Today**: Run setup query (`00_setup_and_init.sql`)
2. **Today**: Create scheduled queries in BigQuery
3. **Tomorrow**: Verify tables have data
4. **Next week**: Query the results and update documentation

See SCHEDULING_GUIDE.md for detailed instructions.

---

## 📞 Troubleshooting

| Issue | Solution |
|-------|----------|
| Table not found | Run `00_setup_and_init.sql` first |
| Permission denied | Need BigQuery Editor role |
| No data | Queries look back 30 days - might be empty initially |
| Different region | Edit SQL files, change region name |

Full troubleshooting guide in SCHEDULING_GUIDE.md

---

**Status**: Ready to deploy ✅  
**Files**: 4 SQL/Doc files committed  
**Setup time**: ~5 minutes  
**Next review**: After first daily run
