-- ============================================================================
-- COLUMN USAGE EXTRACTION
-- Extracts which columns are used most frequently in queries
-- Shows column popularity and query patterns
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.column_usage` AS
WITH query_jobs AS (
  SELECT
    job_id,
    creation_time,
    query,
    referenced_tables,
    statement_type
  FROM `ledger-fcc1e.asia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND query IS NOT NULL
    AND statement_type IN ('SELECT', 'INSERT', 'UPDATE')
),
table_queries AS (
  SELECT
    job_id,
    creation_time,
    query,
    CONCAT(t.project_id, '.', t.dataset_id, '.', t.table_id) as full_table_name,
    t.project_id,
    t.dataset_id,
    t.table_id
  FROM query_jobs,
  UNNEST(referenced_tables) as t
  WHERE t.project_id = 'ledger-fcc1e'
)
SELECT
  full_table_name,
  project_id,
  dataset_id,
  table_id,

  -- Count queries that use this table
  COUNT(DISTINCT job_id) as total_queries,

  -- Count queries that SELECT from this table
  COUNTIF(query LIKE CONCAT('%FROM%', table_id, '%') OR
          query LIKE CONCAT('%FROM%', dataset_id, '.', table_id, '%')) as select_queries,

  -- Count queries that INSERT into this table
  COUNTIF(query LIKE CONCAT('%INSERT%', table_id, '%') OR
          query LIKE CONCAT('%INSERT%', dataset_id, '.', table_id, '%')) as insert_queries,

  -- Count queries that UPDATE this table
  COUNTIF(query LIKE CONCAT('%UPDATE%', table_id, '%') OR
          query LIKE CONCAT('%UPDATE%', dataset_id, '.', table_id, '%')) as update_queries,

  -- Recent activity
  MAX(creation_time) as last_queried,
  MIN(creation_time) as first_queried,

  -- Query frequency
  ROUND(COUNT(DISTINCT DATE(creation_time)) / 30, 2) as queries_per_day_avg,

  -- Most active time
  MODE(EXTRACT(HOUR FROM creation_time)) as peak_query_hour

FROM table_queries
GROUP BY full_table_name, project_id, dataset_id, table_id
ORDER BY total_queries DESC
;

-- ============================================================================
-- COLUMN-LEVEL USAGE (uses pattern matching to extract column references)
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.column_usage_patterns` AS
WITH query_jobs AS (
  SELECT
    job_id,
    creation_time,
    query,
    referenced_tables
  FROM `ledger-fcc1e.asia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND query IS NOT NULL
),
table_in_queries AS (
  SELECT
    CONCAT(t.project_id, '.', t.dataset_id, '.', t.table_id) as full_table_name,
    query,
    t.table_id
  FROM query_jobs,
  UNNEST(referenced_tables) as t
  WHERE t.project_id = 'ledger-fcc1e'
),
-- Extract WHERE clause patterns to understand column usage
where_patterns AS (
  SELECT
    full_table_name,

    -- Count of queries with WHERE clauses
    COUNTIF(query LIKE '%WHERE%') as queries_with_filters,

    -- Common filter patterns (basic pattern matching)
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s*=')) as equality_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s*>|<|>=|<=')) as comparison_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s+(BETWEEN|LIKE|IN)')) as range_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s+IS\s+(NULL|NOT NULL)')) as null_filters,

    -- Aggregation patterns
    COUNTIF(query LIKE '%COUNT%' OR query LIKE '%SUM%' OR query LIKE '%AVG%' OR query LIKE '%GROUP BY%') as aggregation_queries,

    -- JOIN patterns
    COUNTIF(query LIKE '%JOIN%' OR query LIKE '%CROSS JOIN%' OR query LIKE '%LEFT JOIN%') as join_queries,

    COUNT(DISTINCT CASE WHEN query LIKE '%ORDER BY%' THEN query ELSE NULL END) as ordering_queries
  FROM table_in_queries
  GROUP BY full_table_name
)
SELECT
  full_table_name,
  queries_with_filters,
  ROUND(100.0 * equality_filters / NULLIF(queries_with_filters, 0), 2) as pct_equality_filters,
  ROUND(100.0 * comparison_filters / NULLIF(queries_with_filters, 0), 2) as pct_comparison_filters,
  ROUND(100.0 * range_filters / NULLIF(queries_with_filters, 0), 2) as pct_range_filters,
  ROUND(100.0 * null_filters / NULLIF(queries_with_filters, 0), 2) as pct_null_filters,
  aggregation_queries,
  join_queries,
  ordering_queries,
  CURRENT_TIMESTAMP() as extraction_time
FROM where_patterns
ORDER BY queries_with_filters DESC
;

-- ============================================================================
-- Add metadata
-- ============================================================================
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES
  ('column_usage', CURRENT_TIMESTAMP(), 'Daily extraction of table usage patterns'),
  ('column_usage_patterns', CURRENT_TIMESTAMP(), 'Daily extraction of WHERE clause and filter patterns')
;
