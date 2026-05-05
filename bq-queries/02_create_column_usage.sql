-- ============================================================================
-- TABLE USAGE METRICS
-- Analyzes how tables are queried and used
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.table_usage` AS
WITH table_queries AS (
  SELECT
    job_id,
    creation_time,
    query,
    statement_type,
    EXTRACT(HOUR FROM creation_time) as query_hour,
    table_ref
  FROM `ledger-fcc1e.data_documentation.query_history`
  CROSS JOIN UNNEST(referenced_tables) as table_ref
  WHERE statement_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
)
SELECT
  CONCAT(table_ref.project_id, '.', table_ref.dataset_id, '.', table_ref.table_id) as full_table_name,
  table_ref.project_id,
  table_ref.dataset_id,
  table_ref.table_id,
  COUNT(DISTINCT job_id) as total_queries,
  COUNTIF(query LIKE CONCAT('%FROM%', table_ref.table_id, '%') OR
          query LIKE CONCAT('%FROM%', table_ref.dataset_id, '.', table_ref.table_id, '%')) as select_queries,
  COUNTIF(query LIKE CONCAT('%INSERT%', table_ref.table_id, '%') OR
          query LIKE CONCAT('%INSERT%', table_ref.dataset_id, '.', table_ref.table_id, '%')) as insert_queries,
  COUNTIF(query LIKE CONCAT('%UPDATE%', table_ref.table_id, '%') OR
          query LIKE CONCAT('%UPDATE%', table_ref.dataset_id, '.', table_ref.table_id, '%')) as update_queries,
  COUNTIF(query LIKE CONCAT('%DELETE%', table_ref.table_id, '%') OR
          query LIKE CONCAT('%DELETE%', table_ref.dataset_id, '.', table_ref.table_id, '%')) as delete_queries,
  MAX(creation_time) as last_queried,
  MIN(creation_time) as first_queried,
  COUNT(DISTINCT DATE(creation_time)) as days_active,
  APPROX_TOP_COUNT(query_hour, 1)[OFFSET(0)].value as peak_query_hour,
  CURRENT_TIMESTAMP() as extraction_time
FROM table_queries
GROUP BY full_table_name, table_ref.project_id, table_ref.dataset_id, table_ref.table_id
ORDER BY total_queries DESC
;

-- ============================================================================
-- QUERY PATTERN ANALYSIS
-- Analyzes WHERE clause patterns and filter types
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.query_patterns` AS
WITH table_queries AS (
  SELECT
    query,
    table_ref
  FROM `ledger-fcc1e.data_documentation.query_history`
  CROSS JOIN UNNEST(referenced_tables) as table_ref
  WHERE statement_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
),
where_patterns AS (
  SELECT
    CONCAT(table_ref.project_id, '.', table_ref.dataset_id, '.', table_ref.table_id) as full_table_name,
    COUNTIF(query LIKE '%WHERE%') as queries_with_where,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s*=')) as equality_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s*>|<|>=|<=')) as comparison_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s+(BETWEEN|LIKE|IN)')) as range_filters,
    COUNTIF(REGEXP_CONTAINS(query, r'WHERE\s+\w+\s+IS\s+(NULL|NOT NULL)')) as null_filters,
    COUNTIF(query LIKE '%COUNT%' OR query LIKE '%SUM%' OR query LIKE '%AVG%' OR query LIKE '%GROUP BY%') as aggregation_queries,
    COUNTIF(query LIKE '%JOIN%' OR query LIKE '%CROSS JOIN%' OR query LIKE '%LEFT JOIN%') as join_queries,
    COUNT(DISTINCT CASE WHEN query LIKE '%ORDER BY%' THEN query ELSE NULL END) as ordering_queries,
    COUNT(*) as total_queries_for_table
  FROM table_queries
  GROUP BY full_table_name
)
SELECT
  full_table_name,
  queries_with_where,
  ROUND(100.0 * equality_filters / NULLIF(queries_with_where, 0), 2) as pct_equality_filters,
  ROUND(100.0 * comparison_filters / NULLIF(queries_with_where, 0), 2) as pct_comparison_filters,
  ROUND(100.0 * range_filters / NULLIF(queries_with_where, 0), 2) as pct_range_filters,
  ROUND(100.0 * null_filters / NULLIF(queries_with_where, 0), 2) as pct_null_filters,
  aggregation_queries,
  join_queries,
  ordering_queries,
  ROUND(100.0 * aggregation_queries / NULLIF(total_queries_for_table, 0), 2) as pct_aggregation_queries,
  CURRENT_TIMESTAMP() as extraction_time
FROM where_patterns
WHERE total_queries_for_table > 0
ORDER BY queries_with_where DESC
;

-- ============================================================================
-- Add metadata
-- ============================================================================
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES
  ('table_usage', CURRENT_TIMESTAMP(), 'Table usage metrics from query_history'),
  ('query_patterns', CURRENT_TIMESTAMP(), 'Query pattern analysis from query_history')
;
