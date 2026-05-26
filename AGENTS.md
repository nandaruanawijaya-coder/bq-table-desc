# BigQuery Documentation Agents

Agent-based system for discovering, documenting, and validating BigQuery table metadata.

---

## Overview

```
Schema Discovery Agent
    ↓ (extracts: table structure, column types, lineage)
Column Description Agent (existing)
    ↓ (produces: semantic column documentation)
Table Documentation Agent (planned)
    ↓ (generates: table-level docs, business context)
Knowledge Graph Agent (planned)
    ↓ (builds: AI-consumable metadata graph)
Validation Agent (existing)
    ↓ (scores: documentation quality)
Output: AI-ready table knowledge for SQL generation, data catalog, etc.
```

---

## Agent #1: Schema Discovery Agent

**Purpose**: Extract and document table structure, column definitions, and data lineage.

**Status**: ✅ Implemented & Tested

**Responsibilities**:
- Query INFORMATION_SCHEMA for all table columns
- Extract CREATE TABLE/VIEW queries from query_history
- Detect column transformations (base vs derived)
- Identify table relationships and dependencies
- Generate column lineage mappings

**Location**: `agents/schema_discovery_agent.py`

**Output Files**:
- `schema_knowledge/{TABLE}_schema.json` — Individual table schema
  - Full metadata: table type, creation time, column count
  - Column definitions: name, data type, nullability, position
  - Transformation analysis: base/derived, source tables
  - Creation query: DDL extracted from query_history

- `schema_knowledge/table_schemas.json` — Aggregated metadata
  - Summary: total, base, and derived tables
  - Table registry with column counts

- `schema_knowledge/column_lineage.json` — Source → derived mappings
  - Table dependencies
  - Column source tracking for derived columns

- `schema_knowledge/relationships.json` — Table dependency graph
  - Table relationships
  - Data flow dependencies

**Usage**:

```bash
# Discover all tables from table_list.md
python agents/schema_discovery_agent.py --tables all

# Discover specific table
python agents/schema_discovery_agent.py --tables mee_weekly_route_plan

# Use custom project
python agents/schema_discovery_agent.py --tables all --project my-project
```

**Example Output**:

```json
{
  "full_table_id": "ledger-fcc1e.fs_datamart.mee_weekly_route_plan",
  "table_name": "mee_weekly_route_plan",
  "table_type": "TABLE",
  "is_derived": false,
  "column_count": 40,
  "metadata": {
    "creation_time": "2026-03-03 06:50:33.921000+00:00",
    "modified_time": "2026-05-23 01:55:30.715000+00:00"
  },
  "columns": [
    {
      "column_name": "user_id",
      "data_type": "STRING",
      "is_nullable": "YES",
      "ordinal_position": 1
    }
  ],
  "creation_query": {
    "statement_type": "CREATE_TABLE",
    "query": "CREATE OR REPLACE TABLE ..."
  }
}
```

**Dependencies**:
- `table_list.md` — Lists all tables to discover
- BigQuery project with INFORMATION_SCHEMA and query_history access

**Next**: Use output with Column Description Agent & Table Documentation Agent

---

## Agent #2: Column Description Agent (Existing)

**Purpose**: Generate semantic column documentation.

**Status**: ✅ Implemented & Validated

**Location**: `CLAUDE_CODE_AUTOMATION.md` workflow

**Responsibilities**:
- Analyze column values from sample data (10k rows)
- Generate descriptions explaining column meanings
- Detect enumerable columns and extract possible values
- Ensure ≥40% key term coverage (column name → description)
- Apply 4-source semantic logic (SQL + format + context + data)

**Output**: `table_column_description/{TABLE}_doc.json`
- Column-level semantic documentation
- Descriptions, business context, semantic_source
- Example values, possible_values for enums
- 539 columns across 9 tables, 100% validation pass

---

## Agent #3: Table Documentation Agent (Planned)

**Purpose**: Create high-level table documentation.

**Planned Responsibilities**:
- Document table purpose and business owner
- Describe use cases and typical queries
- Extract business metrics (freshness, completeness, latency)
- Generate relationship descriptions (how tables join)
- Create data dictionary

**Planned Output**: `table_documentation/{TABLE}_overview.json`

---

## Agent #4: Knowledge Graph Agent (Planned)

**Purpose**: Build unified, AI-consumable knowledge base.

**Planned Responsibilities**:
- Integrate schema + column docs + table docs
- Create business concept mappings
- Generate table relationship graph
- Build semantic index for AI assistants
- Produce embedding-friendly summaries

**Planned Output**: `knowledge_graph/ai_context.json`

---

## Agent #5: Validation Agent (Existing)

**Purpose**: Enforce documentation quality standards.

**Status**: ✅ Implemented

**Location**: `CLAUDE_CODE_AUTOMATION.md` "Validation Commands" section

**8 Validation Checks**:
1. No empty descriptions
2. All descriptions ≥40 chars
3. No generic "[Field]" patterns
4. All have business_context
5. All have semantic_source
6. Enum columns have possible_values
7. No generic data-type descriptions
8. Descriptions explain column names (≥40% key term coverage)

**Output**: `validation_reports/{TABLE}_validation_report.json`

---

## Agent #6: Query Optimization Agent (Planned)

**Purpose**: Document optimal query patterns.

**Planned Responsibilities**:
- Identify partition and clustering keys
- Recommend efficient joins
- Document common query patterns
- Track query performance baselines

**Planned Output**: `optimization_guides/{TABLE}_query_best_practices.json`

---

## Running All Agents (Orchestrator - Planned)

```bash
# Run all agents in sequence
python agents/orchestrator.py --all

# Run specific agents
python agents/orchestrator.py --agents schema_discovery,column_description,validation

# Generate AI context
python agents/orchestrator.py --generate-ai-context

# Run on new tables only
python agents/orchestrator.py --new-tables-only
```

---

## Agent Architecture Benefits

| Benefit | Description |
|---------|-------------|
| **Modularity** | Each agent has single responsibility |
| **Reusability** | Agents work independently or together |
| **Extensibility** | Easy to add new agents (cost, quality, etc) |
| **Orchestration** | CLI to run in sequence or parallel |
| **AI-Friendly** | Structured output for LLM consumption |
| **Testability** | Each agent can be tested independently |
| **Documentation** | Self-documenting agent system |

---

## Current Implementation Status

| Agent | Status | Location | Output |
|-------|--------|----------|--------|
| Schema Discovery | ✅ Done | `agents/schema_discovery_agent.py` | `schema_knowledge/*.json` |
| Column Description | ✅ Done | `CLAUDE_CODE_AUTOMATION.md` | `table_column_description/*.json` |
| Validation | ✅ Done | `CLAUDE_CODE_AUTOMATION.md` | Pass/fail checks |
| Table Documentation | 📋 Planned | — | — |
| Knowledge Graph | 📋 Planned | — | `knowledge_graph/ai_context.json` |
| Query Optimization | 📋 Planned | — | `optimization_guides/*.json` |
| Orchestrator | 📋 Planned | `agents/orchestrator.py` | CLI + workflow |

---

## Next Steps

1. ✅ Build Schema Discovery Agent ← **YOU ARE HERE**
2. Build Table Documentation Agent
3. Build Knowledge Graph Agent
4. Create Agent Orchestrator CLI
5. Integrate with AI SQL assistants
6. Add embedding-friendly summaries
7. Build Query Optimization Agent

---

## File Structure

```
agents/
├── schema_discovery_agent.py          ← Schema extraction & lineage
├── column_description_agent.py        ← (planned refactor)
├── table_documentation_agent.py       ← (planned)
├── knowledge_graph_agent.py           ← (planned)
├── validation_agent.py                ← (planned refactor)
├── query_optimization_agent.py        ← (planned)
└── orchestrator.py                    ← (planned)

schema_knowledge/
├── {table}_schema.json                ← Individual table schemas
├── table_schemas.json                 ← Aggregated metadata
├── column_lineage.json                ← Source → derived mappings
└── relationships.json                 ← Table dependencies

table_column_description/              ← Column-level docs (existing)
knowledge_graph/                       ← AI context (planned)
table_documentation/                   ← Table-level docs (planned)
optimization_guides/                   ← Query best practices (planned)
```

---

## Usage Example: Schema Discovery → AI Context

```bash
# Step 1: Discover table schemas
python agents/schema_discovery_agent.py --tables all

# Step 2: Generate column descriptions (existing workflow)
# Uses CLAUDE_CODE_AUTOMATION.md

# Step 3: Build AI-consumable knowledge (when ready)
python agents/knowledge_graph_agent.py --all

# Step 4: Use in AI SQL assistant
# knowledge_graph/ai_context.json fed into LLM context for query generation
```

Result: AI can write accurate queries understanding:
- Table structure and relationships
- Column semantics and business meaning
- Partition keys and optimization hints
- Example queries and join patterns
