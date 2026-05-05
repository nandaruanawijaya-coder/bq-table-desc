# Auto-Generated Business Context Guide

> Use query metrics to automatically generate business context descriptions

---

## 🎯 What's New

Instead of [TODO] placeholders, documentation now gets **auto-generated business context** based on actual query usage patterns:

### Before
```json
{
  "column_name": "user_id",
  "business_context": "[TODO] Add context"
}
```

### After
```json
{
  "column_name": "user_id",
  "business_context": "Critical dimension column, used for equality matching in 95% of filters, in 4500+ monthly queries"
}
```

---

## 📊 How It Works

### Table-Level Context Generation

Analyzes these metrics to generate context:
- **Total queries** → Usage frequency (daily, regular, occasional)
- **Operation types** → Purpose (read-only, transaction logging, fact table)
- **Peak query hour** → Business timing (morning/afternoon/evening)
- **Related tables** → Data relationships

**Examples generated**:
- "Read-only dimension table, queried daily for customer analysis, peak usage 2-3 PM"
- "Transaction logging table, 500+ inserts daily, frequently joined with orders"
- "Fact table, regularly queried for revenue reporting and forecasting"

### Column-Level Context Generation

Analyzes these patterns for each column:
- **Filter appearance %** → Column importance (critical/primary/secondary)
- **Filter types** → How it's used (equality, range, null checks)
- **Query volume** → How often referenced

**Examples generated**:
- "Critical dimension column, used for equality matching in 95% of filters, appears in 1,200+ queries"
- "Primary grouping column, used for aggregation in 60% of queries"
- "Supporting column, occasional filter in 15% of queries"

---

## 🔧 Context Generation Rules

### Table-Level Rules

```python
# Rule 1: Table Type
IF select_operations == 100% of operations
  → "Read-only dimension table"
ELSE IF insert_operations > select_operations
  → "Transaction/event logging table"
ELSE
  → "Fact table"

# Rule 2: Query Frequency
IF days_active == 30 (all 30 days)
  → "queried daily"
ELSE IF days_active >= 20
  → "regularly queried"
ELSE IF days_active >= 10
  → "occasionally queried"

# Rule 3: Usage Purpose
IF select > 90%
  → "for analysis and reporting"
ELSE IF insert > 0
  → "for transaction tracking"

# Rule 4: Peak Time
IF peak_hour 8-12
  → "with peak usage during morning hours"
ELSE IF peak_hour 13-17
  → "with peak usage during afternoon hours"
ELSE
  → "with peak usage during evening hours"

# Rule 5: Relationships
IF has_related_tables
  → "frequently joined with [table_names]"
```

### Column-Level Rules

```python
# Rule 1: Filter Importance
IF appears_in_where >= 80%
  → "Critical dimension column"
ELSE IF appears_in_where >= 50%
  → "Primary filter column"
ELSE IF appears_in_where >= 20%
  → "Secondary filter column"
ELSE IF appears_in_where > 0%
  → "Occasionally filtered"
ELSE
  → "Supporting column"

# Rule 2: Filter Type
IF equality_filter > 0%
  → "used for equality matching"
IF range_filter > equality_filter
  → "used for range queries"

# Rule 3: Usage Scale
IF table has_metrics
  → "in X+ monthly queries"
```

---

## 📝 Generated Context Examples

### Dimension Table
```
"Read-only dimension table, queried 1,200+ times daily for customer 
analysis, peak usage 2-3 PM, frequently joined with orders and transactions."
```

### Transaction Log Table
```
"Transaction event log, 10,000+ inserts daily, regularly queried for 
audit and monitoring, peak activity during business hours (9-5)."
```

### Fact Table
```
"Sales fact table, regularly queried for revenue reporting and forecasting, 
frequently joined with product and date dimensions, peak usage afternoon hours."
```

### Column: ID/Key
```
"Critical dimension column, used for equality matching in 98% of filters, 
appears in 4,500+ monthly queries, essential for all lookups."
```

### Column: Date
```
"Primary grouping column, used for time-based analysis in 85% of queries, 
frequently used in range filters for date range selection."
```

### Column: Status Flag
```
"Secondary filter column, used for status filtering in 30% of WHERE clauses, 
helps segment queries by operational state."
```

---

## ✅ When Auto-Context Is Used

Claude Code will:

1. **Check if business_context is empty or contains [TODO]**
2. **If yes**: Generate context from query metrics
3. **If no**: Keep existing context (don't overwrite)

### Examples

**Case 1: Empty context → Generate**
```json
{
  "column_name": "user_id",
  "business_context": "[TODO] Add context"  // Will be replaced
}
```
↓ After enrichment:
```json
{
  "column_name": "user_id",
  "business_context": "Critical dimension column, used for equality matching in 98% of filters"
}
```

**Case 2: Has content → Keep**
```json
{
  "column_name": "user_id",
  "business_context": "Unique identifier for customers in the system"  // Already filled
}
```
↓ After enrichment:
```json
{
  "column_name": "user_id",
  "business_context": "Unique identifier for customers in the system"  // Unchanged
}
```

---

## 🎯 Quality Notes

### Auto-Generated Context is:
✅ **Factual** - Based on actual query metrics, not guessing
✅ **Specific** - Includes numbers: "1,200+ queries", "95% of filters"
✅ **Business-Focused** - Explains usage and importance
✅ **Complete** - Combines multiple insights into one sentence

### What You Can Do:
- **Review** auto-generated context during documentation review
- **Refine** context by adding domain knowledge
- **Preserve** context by not using [TODO] markers if you manually fill it

### Example Refinement:
Auto-generated:
```
"Critical dimension column, used for equality matching in 98% of filters"
```

After manual refinement:
```
"Customer ID - Critical dimension, used in 98% of queries for user segmentation 
and personalization. Links customers to their order history and preferences."
```

---

## 🚀 How to Use

### When Re-Generating Documentation

1. **Delete old documentation** (including old business context)
2. **Run Claude Code** to re-document tables
3. **Claude Code will**:
   - Generate descriptions from schema analysis
   - Query the metrics tables
   - Auto-generate business context from patterns
   - Validate and enrich everything
4. **Review** the auto-generated context
5. **Refine** any context that needs domain knowledge

### Example Workflow

```bash
# 1. Delete old docs
rm table_column_description/*_doc.json

# 2. Ask Claude Code to document
# → Claude Code reads table_list.md
# → Generates base documentation  
# → Enriches with query metrics
# → Auto-generates business context
# → Commits everything

# 3. Review what was generated
# → Check auto-generated context
# → Note any that need refinement

# 4. (Optional) Refine manually
# → Edit specific columns/tables
# → Commit refinements
```

---

## 📊 Real Examples from Your Data

If you had 3 tables with this query data:

### Table: `users`
- Queries: 4,500 in 30 days
- Select operations: 100%
- Days active: 30
- Peak hour: 14
- Related: orders (2,000 joins), sessions (1,500 joins)

**Generated context**:
```
"Read-only dimension table, queried daily for user analysis and reporting,
peak usage 2-3 PM, frequently joined with orders and sessions tables"
```

### Table: `transactions`
- Queries: 1,200 in 30 days
- Insert operations: 800, Select: 400
- Days active: 30
- Peak hour: 15
- Related: users (800 joins), products (600 joins)

**Generated context**:
```
"Transaction logging table, regularly queried for audit and event tracking,
800+ inserts daily, peak activity 3-4 PM, frequently joined with users and products"
```

### Column: `user_id` (in transactions table)
- Appears in 95% of WHERE clauses
- Equality filters: 98%
- In 1,200+ queries

**Generated context**:
```
"Critical dimension column, used for user filtering in 95% of WHERE clauses,
equality-matched in 98% of filters, referenced in 1,200+ queries"
```

---

## 💡 Why This Matters

### For Stakeholders
"User table is queried 4,500+ times per month, peak usage 2-3 PM for reporting"
→ Understands data importance and timing

### For Analysts
"User ID appears in 95% of filters with equality matching"
→ Knows to index it, knows how it's used

### For Data Team
"Frequently joined with orders and sessions"
→ Understands data flow and dependencies

---

## ✨ Next Steps

1. **Understand** how context is auto-generated from metrics
2. **Re-run** documentation generation with auto-context enabled
3. **Review** generated context for accuracy
4. **Refine** any context needing domain expertise
5. **Commit** enriched documentation with context

The combination of:
- ✅ Schema analysis (columns, types, nulls)
- ✅ Query metrics (frequency, timing, relationships)
- ✅ Auto-generated context (business usage patterns)
= **Complete, production-ready documentation**

---

**Status**: Ready to use ✅  
**Feature**: Auto-generated business context  
**Trigger**: [TODO] markers in business_context fields  
**Time to enrich**: +1-2 minutes per table