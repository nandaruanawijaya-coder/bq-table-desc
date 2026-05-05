-- ============================================================================
-- SETUP: Create Documentation Dataset and Metadata Tables
-- Run this ONCE before running other extraction queries
-- ============================================================================

-- Create dataset for documentation (if it doesn't exist)
CREATE SCHEMA IF NOT EXISTS `ledger-fcc1e.data_documentation`
OPTIONS(
  description="Storage for BigQuery table documentation and query analysis",
  location="asia-southeast1"  -- CHANGE THIS to your region if different
);

-- Create metadata table to track all extractions
CREATE OR REPLACE TABLE `ledger-fcc1e.data_documentation.extraction_metadata` (
  extraction_name STRING NOT NULL,
  extraction_timestamp TIMESTAMP NOT NULL,
  description STRING,
  record_count INT64,
  status STRING DEFAULT "completed"
);

-- Add initial metadata row
INSERT INTO `ledger-fcc1e.data_documentation.extraction_metadata`
VALUES (
  'setup_complete',
  CURRENT_TIMESTAMP(),
  'Initial setup - documentation tables created',
  0,
  'completed'
);

-- ============================================================================
-- NOTES FOR YOUR ENVIRONMENT
-- ============================================================================
--
-- 1. REGION CONFIGURATION:
--    The SQL files reference INFORMATION_SCHEMA.JOBS_BY_PROJECT
--    Update in 01_create_table_relationships.sql and 02_create_column_usage.sql:
--
--    Change FROM clause from: `ledger-fcc1e.region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
--    To your region: `ledger-fcc1e.asia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
--
-- 2. PROJECT_ID:
--    All files use 'ledger-fcc1e' as the project
--    If different, search and replace 'ledger-fcc1e' with your project ID
--
-- 3. DAILY SCHEDULING:
--    After verifying the queries work, schedule in BigQuery:
--    - Create scheduled query for 01_create_table_relationships.sql (daily)
--    - Create scheduled query for 02_create_column_usage.sql (daily)
--    - Set schedule time: 02:00 UTC (avoid peak hours)
--
-- 4. PERMISSIONS NEEDED:
--    - roles/bigquery.dataEditor (for writing to data_documentation dataset)
--    - roles/bigquery.jobUser (for running queries against JOBS_BY_PROJECT)
--
-- ============================================================================
