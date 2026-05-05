-- ============================================================================
-- TABLE RELATIONSHIPS EXTRACTION
-- Extracts which tables are joined together in queries
-- Sources data from pre-populated query_history table
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.table_relationships` AS
WITH table_pairs AS (
  SELECT
    job_id,
    creation_time,
    query,
    UNNEST(referenced_tables) as table_ref_1
  FROM `ledger-fcc1e.data_documentation.query_history`
  WHERE statement_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
),
cross_table_pairs AS (
  SELECT
    a.job_id,
    a.creation_time,
    CONCAT(a.table_ref_1.project_id, '.', a.table_ref_1.dataset_id, '.', a.table_ref_1.table_id) as table_a,
    CONCAT(b.table_ref_1.project_id, '.', b.table_ref_1.dataset_id, '.', b.table_ref_1.table_id) as table_b,
    a.query
  FROM table_pairs a
  CROSS JOIN table_pairs b
  WHERE a.job_id = b.job_id
    AND CONCAT(a.table_ref_1.project_id, '.', a.table_ref_1.dataset_id, '.', a.table_ref_1.table_id) <
        CONCAT(b.table_ref_1.project_id, '.', b.table_ref_1.dataset_id, '.', b.table_ref_1.table_id)
)
SELECT
  table_a,
  table_b,
  COUNT(DISTINCT job_id) as join_count,
  MAX(creation_time) as last_joined,
  COUNT(DISTINCT DATE(creation_time)) as days_active,
  ROUND(COUNT(DISTINCT DATE(creation_time)) /
    (DATE_DIFF(CURRENT_DATE(), DATE(MIN(creation_time)), DAY) + 1), 2) as join_frequency_per_day,
  CURRENT_TIMESTAMP() as extraction_time
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
  'Extraction of table join patterns from query_history'
)
;
