-- ============================================================================
-- TABLE RELATIONSHIPS EXTRACTION
-- Extracts which tables are joined together in queries
-- Run daily to keep relationship data fresh
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.table_relationships` AS
WITH query_jobs AS (
  SELECT
    job_id,
    creation_time,
    query,
    referenced_tables,
    statement_type,
    CAST(total_bytes_processed AS FLOAT64) / POW(10, 9) as query_size_gb
  FROM `ledger-fcc1e.asia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND query IS NOT NULL
    AND statement_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
),
table_pairs AS (
  SELECT
    job_id,
    creation_time,
    query,
    UNNEST(referenced_tables) as table_ref_1,
    query_size_gb
  FROM query_jobs
),
cross_table_pairs AS (
  SELECT
    a.job_id,
    a.creation_time,
    a.table_ref_1.project_id as project_1,
    a.table_ref_1.dataset_id as dataset_1,
    a.table_ref_1.table_id as table_1,
    b.table_ref_1.project_id as project_2,
    b.table_ref_1.dataset_id as dataset_2,
    b.table_ref_1.table_id as table_2,
    a.query,
    a.query_size_gb
  FROM table_pairs a
  CROSS JOIN table_pairs b
  WHERE a.job_id = b.job_id
    AND a.table_ref_1.table_id != b.table_ref_1.table_id
    AND CONCAT(a.table_ref_1.project_id, '.', a.table_ref_1.dataset_id, '.', a.table_ref_1.table_id) <
        CONCAT(b.table_ref_1.project_id, '.', b.table_ref_1.dataset_id, '.', b.table_ref_1.table_id)
)
SELECT
  CONCAT(project_1, '.', dataset_1, '.', table_1) as table_a,
  CONCAT(project_2, '.', dataset_2, '.', table_2) as table_b,
  COUNT(DISTINCT job_id) as join_count,
  MAX(creation_time) as last_joined,
  ROUND(AVG(query_size_gb), 2) as avg_query_size_gb,
  STRING_AGG(DISTINCT LEFT(query, 200), ' | ' LIMIT 5) as sample_queries
FROM cross_table_pairs
GROUP BY table_a, table_b
ORDER BY join_count DESC
;

-- ============================================================================
-- Add metadata
-- ============================================================================
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES (
  'table_relationships',
  CURRENT_TIMESTAMP(),
  'Daily extraction of table join patterns from last 30 days of queries'
)
;
