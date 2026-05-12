# CLAUDE_CODE_AUTOMATION.md (Simplified)

> **For Claude Code** - Read this when asked to document BigQuery tables. All critical logic is here; read sequentially.

---

## How to Use This Document

When asked to document tables, Claude Code will:
1. Read `table_list.md` for list of tables and context
2. Check `table_column_description/` for existing documentation
3. Document missing tables using the workflow below
4. Commit to git with summary

---

## Superpowers Methodology Applied

This process follows the [obra superpowers](https://github.com/obra/superpowers) framework:

- **Design Phase**: Clarify what makes documentation useful for AI SQL assistants. Discovered: SQL definition is priority #1 (not column names).
- **Systematic Process**: 4-source extraction in priority order (SQL → format → context → data) with clear validation rules.
- **Data-Driven**: Extract patterns from actual sample data; cache and reuse across tables for efficiency.
- **Verification**: Automated quality checks for every column; no generic descriptions allowed; semantic_source attribution required.

---

## Workflow: 4-Source Semantic Logic

For EACH undocumented table:

1. **Extract CREATE Query** (mandatory) — Get SQL from BigQuery
2. **Analyze Column Formation** (Sources 1-4) — Explain how each column is formed
3. **Generate JSON** — Save to `table_column_description/[TABLE]_doc.json`
4. **Validate** — Check all columns meet success criteria
5. **Commit** — One commit per table or per 5 tables (batch)

---

## Step 1: Extract CREATE Query (MANDATORY - The Source of Truth)

**The CREATE TABLE or CREATE TABLE AS SELECT query is the authoritative source for understanding column formation.** This query answers all questions about transformation, filtering, aggregations, and source data.

```bash
# Step 1: For ALL tables, MUST extract the creation query

# For VIEWs - Extract SQL definition (always available)
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '.view.query' -r > /tmp/create_query.sql

# For TABLEs - Query INFORMATION_SCHEMA to find the ORIGINAL CREATE TABLE query
# This is the PRIMARY source - it shows exactly how the table was built
bq query --use_legacy_sql=false "
  SELECT 
    job_id,
    creation_time,
    query,
    statement_type,
    user_email
  FROM `ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
  WHERE statement_type IN ('CREATE_TABLE', 'CREATE_TABLE_AS_SELECT')
    AND destination_table.table_id = 'TABLE'
    AND destination_table.dataset_id = 'DATASET'
  ORDER BY creation_time ASC  -- Get ORIGINAL creation query
  LIMIT 1
"

# If ORIGINAL CREATE not found, look for RECENT transformation:
bq query --use_legacy_sql=false "
  SELECT 
    job_id,
    creation_time,
    query,
    statement_type
  FROM `ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
  WHERE referenced_tables LIKE '%DATASET.TABLE%'
    AND statement_type IN ('INSERT', 'UPDATE', 'CREATE_TABLE_AS_SELECT')
  ORDER BY creation_time DESC
  LIMIT 1
"

# Step 2: Analyze the creation query to understand:
# - Which columns are BASE/RAW (direct from source table)
# - Which columns are DERIVED (CASE, COUNT, SUM, JOIN, CAST, CONCAT, etc)
# - What source tables are used
# - What filters are applied
# - What transformations are performed
# - What deduplication or aggregation happens

# Step 3: If no query found, check metadata for hints:
bq show --format=json ledger-fcc1e:DATASET.TABLE | jq '{description, labels}' -r
```

**Why the CREATION QUERY is the SOURCE OF TRUTH:**
- **CREATE TABLE AS SELECT**: Shows exact SQL transformation logic, source tables, filters
- **CREATE TABLE with schema**: Combined with INSERT queries shows complete data lineage
- **Answers all semantic questions**:
  - Which columns are aggregations (COUNT, SUM, GROUP BY)?
  - Which are CASE derivations with thresholds?
  - Which are joins with other tables?
  - Which are raw columns passed through?
  - What filters reduce the row count?
  - What deduplication happens (DISTINCT, ROW_NUMBER)?

**Column descriptions MUST explain (from creation query):**
- **WHAT**: Column name and type
- **HOW**: Formation logic from SQL (raw, aggregated, derived, filtered, joined)
- **WHERE**: Source table or calculation (e.g., "SUM of order amounts", "Latest record per customer")
- **WHY**: Business purpose from context

**Example: credit_memo (VIEW — Real SQL)**

```sql
-- 3-source UNION: Feb data + India data + Sync data
WITH base AS (
  SELECT * EXCEPT (verification_date, final_recommendation, notes),
    -- Verification date logic: use actual if available, else submission, else updated_at
    CASE 
      WHEN verification_date IS NOT NULL THEN verification_date
      WHEN submission_date IS NOT NULL THEN submission_date
      ELSE DATE(updated_at)
    END AS verification_date,
    -- Loan approval: derive from score or use manual recommendation
    CASE 
      WHEN final_recommendation IS NULL AND final_score IS NULL THEN NULL 
      WHEN final_recommendation IS NULL AND final_score >= 0.75 THEN 'APPROVED'
      WHEN final_recommendation IS NULL AND final_score < 0.75 THEN 'REJECTED'
      ELSE final_recommendation
    END AS final_recommendation
  FROM cremo_cleaned_feb
  
  UNION ALL
  SELECT * ... FROM cremo_cleaned_indi
  UNION ALL
  SELECT * ... FROM cremo_cleaned_sync
)
SELECT * FROM base
QUALIFY ROW_NUMBER() OVER (PARTITION BY phone_number ORDER BY verification_date DESC) = 1
```

| Column | Formation Logic | Semantic Description |
|--------|-----------------|----------------------|
| `verification_date` | CASE with 3-level priority | Timestamp when loan verification occurred. Priority: actual verification_date → submission_date → updated_at |
| `final_recommendation` | CASE deriving from final_score threshold | Loan approval decision. Auto-set to APPROVED (score ≥0.75) or REJECTED (score <0.75). User can override with manual. NULL if both missing |
| Phone dedupe | ROW_NUMBER() window function | View deduplicates by phone_number, keeping latest verification date only |

---

## Step 2-5: Analyze Columns Using 4 Sources (Priority Order)

### TABLE vs VIEW Strategy (MANDATORY: Always Extract Creation Query)

For EVERY table, extraction priority is:
1. **PRIMARY: Extract the creation query** (CREATE TABLE AS SELECT or CREATE TABLE) — Source of truth
2. **SECONDARY: If creation query not found, check metadata** (description/labels) — Hints about pipeline
3. **FALLBACK: Use column names + business context** — Only if query not available

The creation query tells us exactly:
- Which columns are base/raw vs derived
- What transformations/aggregations were applied
- What source tables are used
- What filters/deduplication happens

| Type | Primary Source | How to Extract | Information Gained |
|------|---|---|-----------|
| **VIEW** | `.view.query` | `bq show --format=json` + `jq '.view.query'` | Complete SQL transformation logic |
| **TABLE** (created with SQL) | INFORMATION_SCHEMA job history | Query jobs_by_project for CREATE_TABLE_AS_SELECT | Original transformation: sources, joins, filters, aggregations |
| **TABLE** (loaded with inserts) | INFORMATION_SCHEMA job history | Query jobs_by_project for INSERT statements | Shows source system and data mapping |
| **TABLE** (no query available) | Description/labels then column semantics | `bq show` metadata + column analysis | Pipeline hints + format detection |

**Critical difference:**
- With creation query: Describe how column is formed (`COUNT of X where Y = Z`, `CASE when score > threshold`, `Latest per customer`)
- Without creation query: Describe what column represents (`Metric for tracking`, `Customer classification`, `Status indicator`)

**Investigation for this project (5 tables):**
1. `credit_memo` (VIEW) — ✅ Extract: `.view.query` → Full SQL with CASE/UNION/window logic
2. `ms_merchant_profiling_ssot` (TABLE) — 🔍 Check: INFORMATION_SCHEMA for CREATE AS SELECT
3. `mee_weekly_route_plan` (TABLE) — 🔍 Check: INFORMATION_SCHEMA for CREATE AS SELECT
4. `ms_form_hiring_and_active` (TABLE) — 🔍 Check: INFORMATION_SCHEMA for CREATE AS SELECT
5. `payments_ssot` (TABLE) — 🔍 Check: INFORMATION_SCHEMA for CREATE AS SELECT

---

For EACH column, apply these sources in order:

### Source 1 (Priority 1): SQL Definition (VIEWs + TABLEs with SQL)

If SQL is available (VIEW or dbt-generated TABLE), parse it and explain column formation:

#### Pattern 1: CASE Statements
Analyze all WHEN branches and explain the logic:

```sql
CASE 
  WHEN score >= 80 THEN 'High'
  WHEN score >= 50 THEN 'Medium'
  ELSE 'Low'
END
```

**Description:** "Risk category: High (score ≥80), Medium (score ≥50), Low (score <50). Used to segment merchants by loan risk level"

#### Pattern 2: Aggregations (COUNT/SUM/AVG)
Explain what's counted and which rows included:

```sql
COUNT(CASE WHEN product = 'PM1_EDC' THEN transaction_id END)
```

**Description:** "Weekly count of PM1_EDC product transactions only. Other payment products excluded. Calculated as COUNT(CASE WHEN product='PM1_EDC' THEN transaction_id END) per MEE per week"

#### Pattern 3: Priority Logic (Multi-level CASE)
For fields with priority-based fallback logic:

```sql
CASE 
  WHEN verification_date IS NOT NULL THEN verification_date
  WHEN submission_date IS NOT NULL THEN submission_date
  ELSE DATE(updated_at)
END
```

**Description:** "Timestamp when loan verification occurred. Priority order: actual verification_date (if available) → submission_date (if available) → updated_at. Used to track assessment timing"

#### Pattern 4: Threshold-based Derivation
For columns derived from score thresholds:

```sql
CASE 
  WHEN final_recommendation IS NULL AND final_score >= 0.75 THEN 'APPROVED'
  WHEN final_recommendation IS NULL AND final_score < 0.75 THEN 'REJECTED'
  ELSE final_recommendation
END
```

**Description:** "Loan approval decision automatically derived from final_score with 0.75 threshold. Score ≥0.75 → APPROVED, <0.75 → REJECTED. User can override with manual recommendation. NULL if score and manual recommendation both missing"

#### Pattern 5: Window Functions (Deduplication)
For columns used in QUALIFY/WHERE with window functions:

```sql
QUALIFY ROW_NUMBER() OVER (PARTITION BY phone_number ORDER BY verification_date DESC) = 1
```

**Description:** "View deduplicates records by phone_number, keeping the latest verification_date. Each merchant appears only once with most recent assessment"

#### Pattern 6: UNION ALL (Multi-source)
If column comes from UNION ALL sources, note data sources:

```sql
SELECT ... FROM cremo_cleaned_feb
UNION ALL
SELECT ... FROM cremo_cleaned_indi
UNION ALL
SELECT ... FROM cremo_cleaned_sync
```

**Description:** "Combines credit assessments from 3 regional sources: Feb data (Philippines) + India data (India) + Sync data (Indonesia). De-duplicated by latest verification date"

### Source 2 (Priority 2): Value Format Detection + Semantic Meaning

For all tables (both VIEW and TABLE), identify column semantics from value patterns and column names:

#### Pattern Detection (Sample Data Analysis)

| Format | Detection | Example | Description |
|--------|-----------|---------|-------------|
| _sdc_* | Starts with _sdc_ | _sdc_batched_at | "Singer data connector: timestamp when batch was processed in pipeline" |
| UUID | 36-char pattern | 85790576066 | "Unique [entity] identifier in UUID v4 format" |
| Phone | 8-13 digits, starts 8 | 85790576066 | "Phone number (10-11 digit Indonesian mobile). Primary identifier for merchant lookup" |
| Timestamp | ISO 8601 pattern | 2026-05-09 10:31:29 | "Timestamp when [action] occurred" |
| Coordinates | lat,long pattern | -6.2,106.8 | "Latitude,longitude coordinate pair for precise location" |
| Bank account | 8-16 digits | 1234567890 | "Bank account number for settlement and payout" |
| Boolean (0/1) | Only 0, 1 values | 0,1 | "Boolean flag indicating [state]" |
| Status/Enum | ≤20 unique | APPROVED, REJECTED | List all possible values in possible_values array |

#### Column Name Semantics (For TABLE Columns Without SQL)

When no SQL available (TABLE type), extract meaning from column names:

| Pattern | Examples | Template |
|---------|----------|----------|
| `has_*`, `is_*` | has_bri_edc, is_active | "Boolean indicating if [entity] [state]. Used for [business purpose]" |
| `*_name` | merchant_name, owner_name | "[Entity] name or registered identifier. Used for [business purpose]" |
| `*_at`, `created_*` | createdAt, updatedAt | "Timestamp when [action] occurred. Indicates [business meaning]" |
| `*_date`, `*_day` | submission_date, birth_date | "Date of [event]. Used for [business context]" |
| `*_count`, `*_total` | transaction_count, total_sales | "Count/total of [metric]. Key metric for [business purpose]" |
| `*_score`, `*_rank` | final_score, credit_rank | "[Type] score (0-1 scale). Used for [business purpose]" |
| `*_id`, `*_number` | phone_number, order_id | "Unique [entity] identifier. Primary key/lookup field" |
| `*_status`, `*_type` | order_status, business_type | "Classification of [entity]. Values: [list]" |
| `area_*`, `province_*` | area_code, province_name | "Geographic [level] for merchant location and segmentation" |

**Bad Template (Generic — DO NOT USE):**
```
"Text or string value. Merchant profile with product ownership"
"Integer numeric value. Merchant profile with product ownership"
"Name or text identifier. Weekly MEE route planning"
```

**Good Templates (Semantic — USE THESE):**
```
Column: businessName
Template: "Official business name or registered trading name. Primary merchant identifier for account and reconciliation"

Column: yearOfBirth
Template: "Year merchant owner was born. Used for KYC demographic verification and age validation"

Column: province
Template: "State or province level administrative division. Used for geographic segmentation and MEE territory assignment"

Column: createdAt
Template: "Timestamp when merchant account was created. Indicates onboarding date and initial KYC completion"
```

### Source 3 (Priority 3): Business Context

Add from `table_list.md` context and table purpose:
- Credit assessment → loan approval, risk analysis
- Sales/route → merchant outreach, targeting
- Visits → engagement tracking
- Merchant profile → KYC, product adoption
- Payments → settlement, revenue

### Source 4 (Priority 4): Sample Data

- **Null percentage** → Set `business_context`: Required/Core/Common/Optional
- **Enumeration** → If ≤20 unique, add `possible_values` array
- **Examples** → Extract 2-3 real values

---

## Output JSON Schema

```json
{
  "table_name": "mee_weekly_route_plan",
  "full_table_id": "ledger-fcc1e.fs_datamart.mee_weekly_route_plan",
  "total_columns": 10,
  "columns": [
    {
      "column_name": "pm1_edc_trx",
      "data_type": "INTEGER",
      "nullable": false,
      "null_percentage": 0.0,
      "description": "Weekly count of PM1_EDC product transactions only. Other payment products excluded. Calculated as COUNT(CASE WHEN product='PM1_EDC' THEN transaction_id END) per MEE per week.",
      "business_context": "Core field - >90% populated",
      "example_values": [45, 120, 67],
      "possible_values": null,
      "semantic_source": "sql_definition + sample_data"
    }
  ]
}
```

---

## Description Generation Rules (15 Semantic Categories)

Apply these patterns when generating descriptions:

**1. SDC Metadata** (_sdc_* columns)
- `_sdc_batched_at` → "Singer data connector: timestamp when batch was processed in pipeline"

**2. UUID** (Unique Identifiers)
- `order_id` → "Unique order identifier in UUID format. Primary key for EDC orders"

**3. Phone Numbers** (8-13 digits, starts 8)
- `phone_number` → "Phone number (10-11 digit Indonesian mobile). Primary identifier for merchant lookup"

**4. Bank Accounts** (8-16 digits)
- `settlement_account` → "Bank account number for merchant settlement and payout"

**5. Geographic** (Addresses, provinces, coordinates)
- `province` → "State or province level administrative division for geographic segmentation"
- `lat_long` → "Latitude,longitude coordinate pair for precise merchant location"

**6. Timestamps**
- `created_at` → "Timestamp when merchant account was created. Indicates onboarding date"
- `CURRENT_TIMESTAMP()` → "Timestamp when view was materialized. Generated at query execution, NOT historical"

**7. Business Metrics & Counts**
- `estimated_customers_per_day` → "Estimated daily customer count. Indicates business volume and sales potential"
- `transaction_count` → "Count of transactions completed. Key metric for EDC usage"

**8. Boolean Flags** (is_*, has_*, *_flag)
- `has_bri_edc` → "Boolean indicating merchant owns BRI EDC machine. Used for product penetration analysis"
- `is_active` → "Boolean indicating if sales executive is actively engaged"

**9. Status & Lifecycle**
- `status` → "Order processing stage: Draft, Unassigned, Active, Completed, Cancelled"
- `kyc_tier` → "KYC verification tier. Indicates compliance and verification level"

**10. Names & Identifiers**
- `mse_name` → "Name of Merchant Success Executive assigned to territory. Used for sales team accountability"

**11. Product Classification**
- `business_type` → "Business operation type: Retail, Food, Services, etc. Used for merchant segmentation"

**12. Loan & Financial**
- `loan_ownership` → "Indicates if merchant has active loan with BukuWarung"
- `final_score` → "Merchant credit score (0-1 scale). Determines loan approval eligibility"

**13. Metadata & Attachments**
- `metadata` → "Additional structured data for order. Contains supplementary information"

**14. Referral & Partnership**
- `referee_name` → "Name of referrer. Used for partnership tracking and attribution"

**15. Team Hierarchy**
- `current_mse_hoa` → "Head of Area assigned to merchant. Indicates area management hierarchy"
- `area` → "Geographic area region (Java 1-3, Sumatera 1-3). Used for MSE organization"

---

## Success Criteria (Per Column)

Every column MUST pass ALL checks:

| Criteria | ✅ Good | ❌ Bad |
|----------|---------|--------|
| **Explains WHAT** | "Counts ONLY PM1_EDC products, other products excluded" | "Count of transactions" |
| **Formation Logic** | Includes CASE/COUNT/SUM/FILTER details from SQL | Generic naming without logic |
| **Value Format** | "UUID v4 format" OR "Phone (10-11 digit)" OR "Timestamp when..." | "Some identifier" OR "A date" |
| **Business Context** | "Used for loan approval determination" | "Score field" |
| **Length** | ≥40 characters (meaningful) | <40 chars (too generic) |
| **Enum Values** | `possible_values: ["Active", "Completed", ...]` | Missing for status columns |
| **business_context** | "Required field" / "Core" / "Common" / "Optional" | Null or missing |
| **semantic_source** | "sql_definition + value_format + ..." | Null or missing |
| **No Generic Patterns** | Specific explanation | "[ColumnName] field" |
| **SDC Columns** | "Singer data connector: [purpose]" | Treated as regular field |

---

## Validation Commands

Run these after generating JSON (all should return EMPTY):

```bash
# Check 1: Empty descriptions
jq '.columns[] | select(.description == null or .description == "") | .column_name' FILE.json

# Check 2: Too short (<40 chars)
jq '.columns[] | select((.description | length) < 40) | .column_name' FILE.json

# Check 3: Generic "[Field]" patterns
jq '.columns[] | select(.description | test("field$|field for")) | .column_name' FILE.json

# Check 4: Missing business_context
jq '.columns[] | select(.business_context == null) | .column_name' FILE.json

# Check 5: Missing semantic_source
jq '.columns[] | select(.semantic_source == null) | .column_name' FILE.json

# Check 6: Enum columns without possible_values
jq '.columns[] | select((.description | test("status|categories")) and (.possible_values == null)) | .column_name' FILE.json

# Check 7: Generic data-type descriptions (NEW)
jq '.columns[] | select(.description | test("^(Text or string|Integer numeric|Numeric value|Name or text) value")) | .column_name' FILE.json
```

**All 7 checks should return EMPTY.** If check 7 finds columns, they need semantic descriptions (column name meaning + business context), not just data types.

---

## Instructions for Data Team

### Add Tables to table_list.md
```markdown
- ledger-fcc1e.dataset.table_name
One sentence describing what this table contains.
```

### Ask Claude Code
```
Document all tables in table_list.md that don't have documentation 
in table_column_description/ yet. Follow CLAUDE_CODE_AUTOMATION.md.
```

### Claude Code Will Do This
1. Read table_list.md (identify undocumented tables)
2. For each table:
   - Extract CREATE query (if VIEW)
   - Query 10,000 sample rows
   - Analyze each column using 4 sources
   - Generate JSON documentation
   - Validate all columns
   - Commit to git
3. Report completion

**Time: ~10 minutes per table**

---

## FAQ

**Q: What if the table is a VIEW?**
A: Extract the SQL using `bq show --format=json ... | jq '.view.query'`. Analyze how each column is formed in the SELECT clause. Use SQL definition as Source 1.

**Q: What if it's a TABLE?**
A: MUST query INFORMATION_SCHEMA to find the creation query. This is the authoritative source for understanding how columns were formed. The query will show: base columns, derived columns, transformations, source tables, filters, aggregations.

**Q: How do I find the creation query for a TABLE?**
A: Use INFORMATION_SCHEMA to find the ORIGINAL CREATE TABLE or CREATE TABLE AS SELECT:

```sql
SELECT creation_time, query, statement_type
FROM `ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE statement_type IN ('CREATE_TABLE', 'CREATE_TABLE_AS_SELECT')
  AND destination_table.table_id = 'TABLE_NAME'
  AND destination_table.dataset_id = 'DATASET_NAME'
ORDER BY creation_time ASC  -- Get ORIGINAL creation
LIMIT 1
```

This query reveals everything about column formation.

**Q: What if the ORIGINAL creation query is not available?**
A: The table may have been created long ago or loaded via a tool. Check the MOST RECENT transformation query:

```sql
SELECT creation_time, query, statement_type
FROM `ledger-fcc1e.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE referenced_tables LIKE '%DATASET.TABLE%'
  AND statement_type IN ('INSERT', 'UPDATE', 'CREATE_TABLE_AS_SELECT')
ORDER BY creation_time DESC
LIMIT 1
```

This shows how data is currently maintained/refreshed. Analyze this query instead.

**Q: What if NO query is found in INFORMATION_SCHEMA?**
A: This means the table was created before INFORMATION_SCHEMA history is available OR loaded via non-query methods. In this case:
1. Check table description for pipeline hints
2. Check labels for dbt/system tags
3. Use column names + business context to infer purpose
4. Document as "base table - no transformation SQL available"

**Q: How do I know if a description needs SQL context?**
A: Check `semantic_source`. If it contains `sql_definition`, the description MUST explain CASE/COUNT/SUM/FILTER logic from the SQL.

**Q: What if I document a table and later find it's actually a VIEW with SQL?**
A: Delete the JSON file and re-run documentation. Claude Code will extract the SQL and produce richer descriptions.

**Q: Can I document multiple tables at once?**
A: Yes. Add all to table_list.md and ask Claude Code once. It will process batches of 5 in parallel for 3x speedup.

**Q: How much faster is batch processing?**
A: Single table: 10 min. Five tables serial: 50 min. Five tables parallel: 12 min.

**Q: How do I regenerate documentation for tables I've already documented?**
A: Delete the JSON file from `table_column_description/` folder, keep the entry in `table_list.md`, and ask Claude Code to re-document. This is useful when: (1) you discover a table is actually a VIEW and need SQL analysis, (2) the methodology improves (like this guide), (3) the schema changes.

**Q: What if I find bad descriptions in existing documentation?**
A: You have 3 options: (1) Delete the JSON file and regenerate with updated Claude Code, (2) Manually edit specific descriptions in the JSON file, (3) Ask Claude Code to regenerate with notes about the patterns that need improvement.

---

## Data Sources

- **table_list.md** — List of tables to document (add new ones here)
- **table_column_description/*.json** — Generated documentation
- **.claude/pattern_cache.json** — Cached patterns for reuse (auto-managed)

---

## Reference

- Obra Superpowers: https://github.com/obra/superpowers
- BigQuery Documentation: https://cloud.google.com/bigquery/docs
