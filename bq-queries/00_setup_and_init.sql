-- ============================================================================
-- SETUP: Create Documentation Dataset and Metadata Tables
-- Run this ONCE before scheduling the extraction queries
-- ============================================================================

-- Verify query_history table exists
-- SELECT COUNT(*) FROM `ledger-fcc1e.data_documentation.query_history`;

-- Create metadata table to track all extractions
CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.extraction_metadata` (
  extraction_name STRING NOT NULL,
  extraction_timestamp TIMESTAMP NOT NULL,
  description STRING,
  status STRING DEFAULT "completed"
);

-- Add initial metadata row
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES (
  'setup_complete',
  CURRENT_TIMESTAMP(),
  'Initial setup - documentation tables created',
  'completed'
);

-- ============================================================================
-- QUERIES POWERED BY query_history TABLE
-- ============================================================================
--
-- These SQL files extract from: `ledger-fcc1e.data_documentation.query_history`
--
-- 01_create_table_relationships.sql
--   → Outputs: table_relationships
--   → Shows which tables are joined together
--
-- 02_create_column_usage.sql
--   → Outputs: table_usage, query_patterns
--   → Shows how tables are queried and filter patterns
--
-- Schedule both to run daily at 02:00 UTC after query_history is updated
--
-- ============================================================================
