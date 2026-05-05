-- ============================================================================
-- QUERY PATTERN ANALYSIS (Using Cloud Audit Logs)
-- Analyzes query patterns and filter types
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.query_patterns` AS
WITH query_logs AS (
  SELECT
    timestamp as creation_time,
    COALESCE(
      protoPayload.request.query,
      protoPayload.response.jobStatistics.query
    ) as query,
    EXTRACT(HOUR FROM timestamp) as query_hour,
    protoPayload.authenticationInfo.principalEmail as user_email
  FROM `ledger-fcc1e.cloudaudit_googleapis_com_activity`
  WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND protoPayload.methodName = 'jobservice.insert'
    AND COALESCE(
      protoPayload.request.query,
      protoPayload.response.jobStatistics.query
    ) IS NOT NULL
),
extracted_tables AS (
  SELECT
    creation_time,
    query,
    query_hour,
    REGEXP_EXTRACT_ALL(
      UPPER(query),
      r'(?:FROM|JOIN)\s+`?([a-zA-Z0-9\-_.]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)`?'
    ) as tables_in_query
  FROM query_logs
),
table_query_details AS (
  SELECT
    creation_time,
    query,
    query_hour,
    table_name
  FROM extracted_tables,
  UNNEST(tables_in_query) as table_name
)
SELECT
  table_name,
  COUNT(*) as total_queries,
  COUNT(DISTINCT DATE(creation_time)) as days_active,
  ROUND(COUNT(*) / 30, 2) as avg_queries_per_day,
  COUNTIF(query LIKE '%WHERE%') as queries_with_where,
  COUNTIF(query LIKE '%GROUP BY%') as aggregation_queries,
  COUNTIF(query LIKE '%JOIN%') as join_queries,
  COUNTIF(query LIKE '%ORDER BY%') as ordering_queries,
  COUNTIF(query LIKE '%LIMIT%') as limit_queries,
  MODE(query_hour) as peak_query_hour,
  CURRENT_TIMESTAMP() as extraction_time
FROM table_query_details
GROUP BY table_name
ORDER BY total_queries DESC
;

-- ============================================================================
-- FILTER PATTERN ANALYSIS
-- ============================================================================

CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.filter_patterns` AS
WITH query_logs AS (
  SELECT
    COALESCE(
      protoPayload.request.query,
      protoPayload.response.jobStatistics.query
    ) as query
  FROM `ledger-fcc1e.cloudaudit_googleapis_com_activity`
  WHERE TIMESTAMP_TRUNC(timestamp, DAY) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND protoPayload.methodName = 'jobservice.insert'
    AND COALESCE(
      protoPayload.request.query,
      protoPayload.response.jobStatistics.query
    ) IS NOT NULL
)
SELECT
  'equality_filter' as filter_type,
  COUNTIF(query LIKE '%=%') as count,
  ROUND(100.0 * COUNTIF(query LIKE '%=%') / COUNT(*), 2) as percentage
FROM query_logs
UNION ALL
SELECT
  'comparison_filter',
  COUNTIF(query LIKE '%>%' OR query LIKE '%<%'),
  ROUND(100.0 * COUNTIF(query LIKE '%>%' OR query LIKE '%<%') / COUNT(*), 2)
FROM query_logs
UNION ALL
SELECT
  'between_filter',
  COUNTIF(query LIKE '%BETWEEN%'),
  ROUND(100.0 * COUNTIF(query LIKE '%BETWEEN%') / COUNT(*), 2)
FROM query_logs
UNION ALL
SELECT
  'in_filter',
  COUNTIF(query LIKE '%IN (%'),
  ROUND(100.0 * COUNTIF(query LIKE '%IN (%') / COUNT(*), 2)
FROM query_logs
UNION ALL
SELECT
  'like_filter',
  COUNTIF(query LIKE '%LIKE%'),
  ROUND(100.0 * COUNTIF(query LIKE '%LIKE%') / COUNT(*), 2)
FROM query_logs
UNION ALL
SELECT
  'null_filter',
  COUNTIF(query LIKE '%IS NULL%' OR query LIKE '%IS NOT NULL%'),
  ROUND(100.0 * COUNTIF(query LIKE '%IS NULL%' OR query LIKE '%IS NOT NULL%') / COUNT(*), 2)
FROM query_logs
ORDER BY count DESC
;

-- ============================================================================
-- Add metadata
-- ============================================================================
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES
  ('query_patterns', CURRENT_TIMESTAMP(), 'Daily extraction of query patterns from Cloud Audit Logs'),
  ('filter_patterns', CURRENT_TIMESTAMP(), 'Daily extraction of filter pattern statistics')
;
