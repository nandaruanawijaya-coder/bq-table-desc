# BigQuery Query Analysis - Complete Setup

> SQL files for daily query analysis using your pre-populated query_history table

---

## 📦 What's Included

### SQL Files (in `bq-queries/`)

| File | Purpose | Output Tables |
|------|---------|---|
| **00_setup_and_init.sql** | One-time setup | Creates metadata table |
| **01_create_table_relationships.sql** | Extract table joins | `table_relationships` |
| **02_create_column_usage.sql** | Analyze query patterns | `table_usage`, `query_patterns` |
| **SCHEDULING_GUIDE.md** | Setup instructions | — |

All queries source from: `ledger-fcc1e.data_documentation.query_history`

---

## ⚡ Quick Start (5 minutes)

### 1. Run Setup (One Time)
Copy `00_setup_and_init.sql` to BigQuery Console and run.

```sql
-- Verify query_history exists and has data
SELECT COUNT(*) FROM `ledger-fcc1e.data_documentation.query_history`;
```

### 2. Schedule Daily Runs

Open **BigQuery Console** → **Scheduled Queries** → **Create Scheduled Query**

**Query 1: Table Relationships**
- Copy: `01_create_table_relationships.sql`
- Name: `daily-table-relationships`
- Schedule: Daily at 02:00 UTC

**Query 2: Table Usage & Patterns**
- Copy: `02_create_column_usage.sql`
- Name: `daily-table-usage`
- Schedule: Daily at 02:15 UTC

### 3. Done ✅
Tables update automatically every day.

---

## 📊 Output Tables

### table_relationships
Which tables are joined together

```
table_a                 | table_b              | join_count | days_active | last_joined
ledger-fcc1e.foo.users  | ledger-fcc1e.foo.orders | 87      | 23          | 2026-05-05
```

### table_usage
Query frequency and patterns for each table

```
full_table_name         | total_queries | select_queries | peak_query_hour | days_active
ledger-fcc1e.foo.users  | 1,234         | 1,200          | 14              | 23
```

### query_patterns
WHERE clause patterns and filter types

```
full_table_name | queries_with_where | pct_equality | pct_comparison | aggregation_queries
ledger-fcc1e... | 456                | 45.2         | 32.1           | 78
```

---

## 📈 Integration with Documentation

Use extracted insights to enhance your table documentation:

1. **Table Relationships** → Document which tables are frequently joined
2. **Table Usage** → Note peak query hours and most-accessed tables
3. **Query Patterns** → Document common WHERE clause patterns

Example:
```json
"description": "User ID - primary key, appears in 100% of WHERE clauses",
"business_context": "Essential filter for all user-level queries, peak usage 2-4 PM"
```

---

## 🚀 Next Steps

1. Run `00_setup_and_init.sql`
2. Create two scheduled queries
3. Next day: View results in output tables
4. Update table documentation with insights

See **SCHEDULING_GUIDE.md** for detailed instructions.

---

## 🔍 Quick Queries

### Most-Joined Table Pairs
```sql
SELECT table_a, table_b, join_count
FROM `ledger-fcc1e.data_documentation.table_relationships`
ORDER BY join_count DESC LIMIT 10;
```

### Most-Queried Tables
```sql
SELECT full_table_name, total_queries, peak_query_hour
FROM `ledger-fcc1e.data_documentation.table_usage`
ORDER BY total_queries DESC LIMIT 10;
```

---

**Status**: Ready to schedule ✅  
**Setup time**: ~5 minutes  
**Data source**: query_history table (pre-populated)  
**Execution time**: ~30-60 seconds per query
