#!/usr/bin/env python3
"""
Schema Discovery Agent

Extracts and documents BigQuery table structures, column lineage, and relationships.
Output: schema_knowledge/*.json files for consumption by other agents.

Usage:
    python schema_discovery_agent.py --tables all
    python schema_discovery_agent.py --tables mee_weekly_route_plan
"""

import json
import re
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from google.cloud import bigquery
from pathlib import Path


class SchemaDiscoveryAgent:
    """Discovers and documents BigQuery table schemas, lineage, and relationships."""

    def __init__(self, project_id: str = "ledger-fcc1e"):
        """Initialize BigQuery client and storage paths."""
        self.client = bigquery.Client(project=project_id)
        self.project_id = project_id
        self.output_dir = Path("schema_knowledge")
        self.output_dir.mkdir(exist_ok=True)
        self.table_list_path = Path("table_list.md")
        self.column_doc_dir = Path("table_column_description")

    def get_tables_from_list(self) -> Dict[str, Tuple[str, str, str]]:
        """Parse table_list.md to get all documented tables."""
        tables = {}
        if not self.table_list_path.exists():
            print(f"⚠️  {self.table_list_path} not found")
            return tables

        with open(self.table_list_path) as f:
            for line in f:
                if line.startswith("- "):
                    full_table_id = line.strip("- \n").strip()
                    if "." in full_table_id:
                        parts = full_table_id.split(".")
                        if len(parts) == 3:
                            project, dataset, table = parts
                            tables[table] = (project, dataset, table)

        return tables

    def get_table_schema(self, dataset_id: str, table_id: str) -> Dict:
        """Query INFORMATION_SCHEMA for table columns."""
        query = f"""
            SELECT
                column_name,
                data_type,
                is_nullable,
                ordinal_position
            FROM `{self.project_id}.{dataset_id}.INFORMATION_SCHEMA.COLUMNS`
            WHERE table_name = '{table_id}'
            ORDER BY ordinal_position
        """

        try:
            results = self.client.query(query).result()
            columns = []
            for row in results:
                columns.append({
                    "column_name": row["column_name"],
                    "data_type": row["data_type"],
                    "is_nullable": row["is_nullable"],
                    "ordinal_position": row["ordinal_position"]
                })
            return columns
        except Exception as e:
            print(f"❌ Failed to get schema for {dataset_id}.{table_id}: {e}")
            return []

    def get_create_query(self, dataset_id: str, table_id: str) -> Optional[str]:
        """Extract CREATE TABLE/VIEW query from query_history."""
        query = f"""
            SELECT
                creation_time,
                query,
                statement_type
            FROM `{self.project_id}.data_documentation.query_history`
            WHERE query LIKE '%{table_id}%'
              AND statement_type IN ('CREATE_TABLE', 'CREATE_TABLE_AS_SELECT', 'CREATE_VIEW')
            ORDER BY creation_time DESC
            LIMIT 1
        """

        try:
            results = self.client.query(query).result()
            for row in results:
                return {
                    "creation_time": str(row["creation_time"]),
                    "statement_type": row["statement_type"],
                    "query": row["query"][:1000]  # First 1000 chars
                }
        except Exception as e:
            print(f"⚠️  Could not find CREATE query for {table_id}: {e}")

        return None

    def detect_column_transformation(self, table_id: str, create_query: Optional[str]) -> Dict:
        """Analyze if columns are base or derived from transformations."""
        if not create_query or "query" not in create_query:
            return {
                "type": "unknown",
                "transformation": None,
                "source_tables": []
            }

        query_text = create_query["query"].upper()
        transformations = []
        source_tables = []

        # Detect source tables
        from_match = re.search(r'FROM\s+`?([^`\s;]+)`?', query_text)
        if from_match:
            source_tables = [from_match.group(1)]

        # Detect transformations
        if "CASE WHEN" in query_text:
            transformations.append("case_statement")
        if any(agg in query_text for agg in ["COUNT(", "SUM(", "AVG(", "MAX(", "MIN("]):
            transformations.append("aggregation")
        if "CAST(" in query_text or "SAFE_CAST(" in query_text:
            transformations.append("type_cast")
        if any(func in query_text for func in ["CONCAT(", "STRING(", "EXTRACT("]):
            transformations.append("string_manipulation")
        if any(func in query_text for func in ["DATE(", "TIMESTAMP(", "DATETIME("]):
            transformations.append("date_transformation")

        is_derived = "SELECT" in query_text and "FROM" in query_text
        col_type = "derived" if is_derived else "base"

        return {
            "type": col_type,
            "transformation": transformations if transformations else None,
            "source_tables": source_tables
        }

    def get_table_metadata(self, dataset_id: str, table_id: str) -> Dict:
        """Get table metadata using BigQuery API."""
        try:
            table = self.client.get_table(f"{self.project_id}.{dataset_id}.{table_id}")
            return {
                "table_name": table.table_id,
                "table_type": table.table_type,
                "creation_time": str(table.created),
                "modified_time": str(table.modified),
                "description": table.description or "",
                "column_count": len(table.schema) if table.schema else 0
            }
        except Exception as e:
            print(f"⚠️  Could not get metadata for {table_id}: {e}")
            return {}

    def load_column_descriptions(self, table_id: str) -> Optional[Dict]:
        """Load existing column descriptions from table_column_description."""
        doc_file = self.column_doc_dir / f"{table_id}_doc.json"
        if not doc_file.exists():
            return None

        try:
            with open(doc_file) as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️  Could not load column descriptions for {table_id}: {e}")
            return None

    def merge_column_descriptions(self, columns: List[Dict], col_docs: Optional[Dict]) -> List[Dict]:
        """Merge semantic descriptions into schema columns."""
        if not col_docs or "columns" not in col_docs:
            return columns

        # Create lookup map for descriptions
        desc_map = {col["column_name"]: col for col in col_docs["columns"]}

        # Merge descriptions into columns
        enriched = []
        for col in columns:
            col_name = col["column_name"]
            if col_name in desc_map:
                desc_col = desc_map[col_name]
                col.update({
                    "description": desc_col.get("description"),
                    "business_context": desc_col.get("business_context"),
                    "semantic_source": desc_col.get("semantic_source"),
                    "example_values": desc_col.get("example_values"),
                    "possible_values": desc_col.get("possible_values"),
                    "null_percentage": desc_col.get("null_percentage")
                })
            enriched.append(col)

        return enriched

    def discover_table(self, dataset_id: str, table_id: str, full_table_id: str) -> Dict:
        """Discover complete schema and metadata for a single table."""
        print(f"📊 Discovering: {full_table_id}")

        # Get metadata
        metadata = self.get_table_metadata(dataset_id, table_id)

        # Get columns
        columns = self.get_table_schema(dataset_id, table_id)

        # Load and merge column descriptions (semantic documentation)
        col_docs = self.load_column_descriptions(table_id)
        columns = self.merge_column_descriptions(columns, col_docs)

        # Get CREATE query
        create_query = self.get_create_query(dataset_id, table_id)

        # Detect transformations
        transformation = self.detect_column_transformation(table_id, create_query)

        return {
            "full_table_id": full_table_id,
            "dataset": dataset_id,
            "table_name": table_id,
            "discovered_at": datetime.now().isoformat(),
            "metadata": metadata,
            "table_type": metadata.get("table_type", "UNKNOWN"),
            "is_derived": transformation["type"] == "derived",
            "creation_query": create_query,
            "transformation_type": transformation,
            "column_count": len(columns),
            "columns": columns,
            "has_semantic_docs": col_docs is not None
        }

    def discover_all(self) -> Dict[str, Dict]:
        """Discover all tables from table_list.md."""
        tables = self.get_tables_from_list()
        print(f"📋 Found {len(tables)} tables in table_list.md\n")

        discovered = {}
        for table_name, (project, dataset, table) in tables.items():
            full_id = f"{project}.{dataset}.{table}"
            try:
                schema = self.discover_table(dataset, table, full_id)
                discovered[full_id] = schema
            except Exception as e:
                print(f"❌ Error discovering {full_id}: {e}")

        return discovered

    def save_table_schemas(self, discovered: Dict[str, Dict]) -> None:
        """Save individual table schema files."""
        for full_id, schema in discovered.items():
            table_name = schema["table_name"]
            output_file = self.output_dir / f"{table_name}_schema.json"

            with open(output_file, "w") as f:
                json.dump(schema, f, indent=2)

            print(f"✅ Saved: {output_file}")

    def build_column_lineage(self, discovered: Dict[str, Dict]) -> Dict:
        """Build column lineage map."""
        lineage = {
            "tables": {},
            "lineage_map": {}
        }

        for full_id, schema in discovered.items():
            lineage["tables"][full_id] = {
                "columns": [col["column_name"] for col in schema["columns"]],
                "is_derived": schema["is_derived"],
                "source_tables": schema["transformation_type"]["source_tables"]
            }

        return lineage

    def build_relationship_graph(self, discovered: Dict[str, Dict]) -> Dict:
        """Build table dependency relationship graph."""
        relationships = {
            "tables": {},
            "dependencies": []
        }

        for full_id, schema in discovered.items():
            sources = schema["transformation_type"]["source_tables"]

            relationships["tables"][full_id] = {
                "type": schema["table_type"],
                "is_derived": schema["is_derived"],
                "depends_on": sources
            }

            for source in sources:
                relationships["dependencies"].append({
                    "from": source,
                    "to": full_id,
                    "type": "data_source"
                })

        return relationships

    def save_aggregated_knowledge(self, discovered: Dict[str, Dict]) -> None:
        """Save aggregated schema knowledge files."""

        # Column lineage
        lineage = self.build_column_lineage(discovered)
        with open(self.output_dir / "column_lineage.json", "w") as f:
            json.dump(lineage, f, indent=2)
        print(f"✅ Saved: schema_knowledge/column_lineage.json")

        # Relationship graph
        relationships = self.build_relationship_graph(discovered)
        with open(self.output_dir / "relationships.json", "w") as f:
            json.dump(relationships, f, indent=2)
        print(f"✅ Saved: schema_knowledge/relationships.json")

        # Aggregated metadata
        aggregated = {
            "discovered_at": datetime.now().isoformat(),
            "total_tables": len(discovered),
            "base_tables": len([s for s in discovered.values() if not s["is_derived"]]),
            "derived_tables": len([s for s in discovered.values() if s["is_derived"]]),
            "tables": {
                full_id: {
                    "name": schema["table_name"],
                    "type": schema["table_type"],
                    "columns": schema["column_count"],
                    "is_derived": schema["is_derived"]
                }
                for full_id, schema in discovered.items()
            }
        }

        with open(self.output_dir / "table_schemas.json", "w") as f:
            json.dump(aggregated, f, indent=2)
        print(f"✅ Saved: schema_knowledge/table_schemas.json")

    def run(self, specific_table: Optional[str] = None):
        """Run schema discovery."""
        print("\n" + "="*80)
        print("SCHEMA DISCOVERY AGENT")
        print("="*80 + "\n")

        if specific_table:
            tables = self.get_tables_from_list()
            if specific_table in tables:
                project, dataset_id, table_id = tables[specific_table]
                discovered = {
                    f"{project}.{dataset_id}.{table_id}":
                    self.discover_table(dataset_id, table_id, f"{project}.{dataset_id}.{table_id}")
                }
            else:
                print(f"❌ Table '{specific_table}' not found in table_list.md")
                return
        else:
            discovered = self.discover_all()

        if not discovered:
            print("❌ No tables discovered")
            return

        print(f"\n✅ Discovered {len(discovered)} tables\n")

        # Save schemas
        self.save_table_schemas(discovered)

        # Save aggregated
        print("")
        self.save_aggregated_knowledge(discovered)

        print("\n" + "="*80)
        print(f"✅ Schema discovery complete!")
        print(f"   Output: schema_knowledge/")
        print(f"   Generated files:")
        print(f"     - {len(discovered)} individual table schemas")
        print(f"     - table_schemas.json (aggregated metadata)")
        print(f"     - column_lineage.json (source → derived mappings)")
        print(f"     - relationships.json (table dependencies)")
        print("="*80 + "\n")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Discover BigQuery table schemas")
    parser.add_argument("--tables", default="all", help="Specific table or 'all'")
    parser.add_argument("--project", default="ledger-fcc1e", help="BigQuery project ID")
    args = parser.parse_args()

    agent = SchemaDiscoveryAgent(project_id=args.project)

    if args.tables == "all":
        agent.run()
    else:
        agent.run(specific_table=args.tables)


if __name__ == "__main__":
    main()
