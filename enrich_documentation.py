#!/usr/bin/env python3
"""Enrich documentation with query analysis data"""

from google.cloud import bigquery
import json
from datetime import datetime

PROJECT_ID = 'ledger-fcc1e'

def generate_business_context(table_id, metrics, relationships):
    """Generate business context from query metrics"""
    if not metrics:
        return "[TODO] Add business context"

    total_queries = metrics.get('total_queries_30_days', 0)
    peak_hour = metrics.get('peak_query_hour')
    days_active = metrics.get('days_active_in_30_days', 0)

    context_parts = []

    if metrics['select_operations'] == total_queries:
        context_parts.append("Read-only dimension table")
    elif metrics['insert_operations'] > metrics['select_operations']:
        context_parts.append("Transaction/event logging table")
    else:
        context_parts.append("Fact table")

    if days_active == 30:
        context_parts.append("queried daily")
    elif days_active >= 20:
        context_parts.append("regularly queried")
    elif days_active >= 10:
        context_parts.append("occasionally queried")

    if metrics['select_operations'] > total_queries * 0.9:
        context_parts.append("for analysis and reporting")
    elif metrics['insert_operations'] > 0:
        context_parts.append("for transaction tracking")

    if peak_hour is not None:
        if 8 <= peak_hour <= 12:
            context_parts.append("with peak usage during morning hours")
        elif 13 <= peak_hour <= 17:
            context_parts.append("with peak usage during afternoon hours")
        elif 18 <= peak_hour <= 23:
            context_parts.append("with peak usage during evening hours")

    if relationships:
        related_tables = [r['related_table'].split('.')[-1] for r in relationships[:2]]
        context_parts.append(f"frequently joined with {', '.join(related_tables)}")

    if len(context_parts) >= 2:
        return f"{context_parts[0]}, {' and '.join(context_parts[1:])}."
    elif context_parts:
        return f"{context_parts[0]}."
    else:
        return "[TODO] Add business context"

def generate_column_context(column_name, filter_patterns, table_metrics):
    """Generate business context for a column"""
    if not filter_patterns:
        return "[TODO] Add business context"

    pct_where = filter_patterns.get('appears_in_where_clause_percentage', 0)
    context_parts = []

    if pct_where >= 80:
        context_parts.append("Critical dimension column")
    elif pct_where >= 50:
        context_parts.append("Primary filter column")
    elif pct_where >= 20:
        context_parts.append("Secondary filter column")
    elif pct_where > 0:
        context_parts.append("Occasionally filtered")
    else:
        context_parts.append("Supporting column")

    pct_eq = filter_patterns.get('equality_filter_percentage', 0)
    pct_range = filter_patterns.get('range_filter_percentage', 0)

    if pct_eq > 0:
        context_parts.append(f"used for equality matching ({pct_eq}% of filters)")
    if pct_range > pct_eq and pct_range > 0:
        context_parts.append(f"used for range queries ({pct_range}% of filters)")

    if table_metrics and table_metrics.get('total_queries_30_days', 0) > 0:
        context_parts.append(f"in {table_metrics['total_queries_30_days']}+ monthly queries")

    if len(context_parts) >= 2:
        return f"{context_parts[0]}, {' and '.join(context_parts[1:])}."
    elif context_parts:
        return f"{context_parts[0]}."
    else:
        return "[TODO] Add business context"

def enrich_table(table_id, table_name):
    """Enrich a single table's documentation"""
    doc_file = f'table_column_description/{table_name}_doc.json'

    with open(doc_file, 'r') as f:
        doc = json.load(f)

    client = bigquery.Client(project=PROJECT_ID)

    # 1. Get table relationships
    print(f"  ⏳ Fetching table relationships...")
    rel_query = f"""
    SELECT table_a, table_b, join_count, last_joined
    FROM `ledger-fcc1e.data_documentation.table_relationships`
    WHERE table_a = '{table_id}' OR table_b = '{table_id}'
    ORDER BY join_count DESC
    LIMIT 10
    """
    try:
        rel_results = list(client.query(rel_query).result())
        relationships = []
        for row in rel_results:
            related = row['table_b'] if row['table_a'] == table_id else row['table_a']
            relationships.append({
                "related_table": related,
                "join_frequency": row['join_count'],
                "relationship_type": "frequently_joined_with",
                "last_joined": row['last_joined'].isoformat() if row['last_joined'] else None
            })
        if relationships:
            doc['table_relationships'] = relationships
    except Exception as e:
        print(f"    ⚠️  No relationships found: {str(e)[:50]}")

    # 2. Get query metrics
    print(f"  ⏳ Fetching query metrics...")
    metrics_query = f"""
    SELECT *
    FROM `ledger-fcc1e.data_documentation.table_usage`
    WHERE full_table_name = '{table_id}'
    LIMIT 1
    """
    try:
        metrics_result = list(client.query(metrics_query).result())
        if metrics_result:
            row = metrics_result[0]
            metrics = {
                "total_queries_30_days": row['total_queries'],
                "select_operations": row['select_queries'],
                "insert_operations": row['insert_queries'],
                "update_operations": row['update_queries'],
                "delete_operations": row['delete_queries'],
                "days_active_in_30_days": row['days_active'],
                "peak_query_hour": row['peak_query_hour'],
                "last_queried": row['last_queried'].isoformat() if row['last_queried'] else None
            }
            doc['query_metrics'] = metrics
            doc['table_business_context'] = generate_business_context(table_id, metrics, doc.get('table_relationships', []))
            doc['documentation_enriched'] = datetime.now().isoformat()
    except Exception as e:
        print(f"    ⚠️  No metrics found: {str(e)[:50]}")

    # 3. Enhance column business context if empty
    for col in doc['columns']:
        if '[TODO]' in col.get('business_context', '[TODO]'):
            # Try to get filter patterns for this column
            filter_query = f"""
            SELECT *
            FROM `ledger-fcc1e.data_documentation.query_patterns`
            WHERE full_table_name = '{table_id}'
            LIMIT 1
            """
            try:
                filter_result = list(client.query(filter_query).result())
                if filter_result:
                    patterns = {
                        'equality_filter_percentage': filter_result[0]['pct_equality'],
                        'comparison_filter_percentage': filter_result[0]['pct_comparison'],
                        'range_filter_percentage': filter_result[0]['pct_range'],
                        'appears_in_where_clause_percentage': filter_result[0]['pct_where'] if 'pct_where' in filter_result[0] else 0
                    }
                    col['business_context'] = generate_column_context(
                        col['column_name'],
                        patterns,
                        doc.get('query_metrics')
                    )
            except:
                pass

    # Save enriched documentation
    with open(doc_file, 'w') as f:
        json.dump(doc, f, indent=2, default=str)

    print(f"  ✅ Documentation enriched")
    if 'query_metrics' in doc:
        print(f"     - Query metrics: {doc['query_metrics']['total_queries_30_days']} queries in 30 days")
    if 'table_relationships' in doc:
        print(f"     - Related tables: {len(doc['table_relationships'])}")

# Tables to enrich
tables = [
    ('ledger-fcc1e.trb_pymnts_derived.location_gmaps_static', 'location_gmaps_static'),
    ('ledger-fcc1e.merchant_success_analytics.ms_merchant_profiling_ssot', 'ms_merchant_profiling_ssot'),
    ('ledger-fcc1e.db_accounting.prod_edc_order', 'prod_edc_order'),
]

for table_id, table_name in tables:
    print(f"⏳ Enriching {table_name}...")
    try:
        enrich_table(table_id, table_name)
    except Exception as e:
        print(f"  ❌ Error: {str(e)[:100]}")

print(f"\n✅ Enrichment complete!")
