-- ============================================================================
-- TABLE RELATIONSHIPS EXTRACTION (Using Cloud Audit Logs)
-- Extracts which tables are joined together in queries
-- Run daily to keep relationship data fresh
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.table_relationships` AS
WITH query_logs AS (
  SELECT
    timestamp as creation_time,
    protoPayload.request.query as query,
    protoPayload.request.projectId as project_id,
    COALESCE(
      protoPayload.request.query,
      protoPayload.response.jobStatistics.query
    ) as full_query
  FROM `ledger-fcc1e.cloudaudit_googleapis_com_activity`
  WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND protoPayload.methodName = 'jobservice.insert'
    AND protoPayload.request.query IS NOT NULL
),
table_references AS (
  SELECT
    creation_time,
    full_query as query,
    REGEXP_EXTRACT_ALL(
      UPPER(full_query),
      r'(?:FROM|JOIN)\s+`?([a-zA-Z0-9\-_.]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)`?'
    ) as table_list
  FROM query_logs
),
table_pairs AS (
  SELECT
    creation_time,
    query,
    t1,
    t2
  FROM table_references,
  UNNEST(table_list) as t1
  CROSS JOIN UNNEST(table_list) as t2
  WHERE t1 < t2
)
SELECT
  t1 as table_a,
  t2 as table_b,
  COUNT(*) as join_count,
  MAX(creation_time) as last_joined,
  CURRENT_TIMESTAMP() as extraction_time
FROM table_pairs
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
  'Daily extraction of table join patterns from Cloud Audit Logs (last 30 days)'
)
;
