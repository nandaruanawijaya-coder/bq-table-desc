# Table Documentation for AI Query Assistant

This folder contains comprehensive column-level documentation for BigQuery tables. Each table has been documented with column descriptions, data types, business context, and example values to help business stakeholders understand and query the data.

## 📋 Documentation Files

### 1. **location_gmaps_static_opentable_doc.json**
   - **Table**: `ledger-fcc1e.datamart_opentable.location_gmaps_static_opentable`
   - **Purpose**: Location data enriched with Google Maps geocoding information
   - **Key Columns**: formatted_address, latitude, longitude, area, province, kabupaten, kecamatan
   - **Sample Data**: `table_list/location_data.json` (1000 rows)

### 2. **mapping_area_mse_opentable_doc.json**
   - **Table**: `ledger-fcc1e.datamart_opentable.mapping_area_mse_opentable`
   - **Purpose**: Merchant Sales Executive (MSE) to geographic area mapping and organizational hierarchy
   - **Key Columns**: area, region, mse_lead, head_of_area, head_of_region, province
   - **Sample Data**: `table_list/mse_data.json` (1000 rows)
   - **Note**: Data appears sparse in current sample

### 3. **ms_merchant_profiling_ssot_opentable_doc.json**
   - **Table**: `ledger-fcc1e.datamart_opentable.ms_merchant_profiling_ssot_opentable`
   - **Purpose**: Single Source of Truth (SSOT) for comprehensive merchant master data
   - **Key Columns**: businessName, address, area, businessTypes, createdDate, current_mse_lead, EDC capabilities, loan info
   - **Sample Data**: `table_list/merchant_data.json` (1000 rows)
   - **Note**: Primary merchant reference table - use for all merchant-level analysis

### 4. **prod_edc_order_doc.json**
   - **Table**: `ledger-fcc1e.db_accounting.prod_edc_order`
   - **Purpose**: EDC transaction order records from accounting system
   - **Key Columns**: janus_account_id, business_type, created_at, kyc_tier, bank_name, delivery_status
   - **Sample Data**: `table_list/edc_data.json` (1000 rows)
   - **Note**: Authoritative order transaction data from production

## 🚀 How to Use

1. **For a specific table**: Open the corresponding `*_doc.json` file
2. **To understand columns**: Check the `columns` array in each JSON file
3. **For business context**: Review the `business_context` field for each column
4. **To see data samples**: Check the sample data file referenced for each table
5. **For data quality**: Review the `tips_for_stakeholders` section in each documentation file

## 📊 Documentation Structure

Each documentation file contains:

```json
{
  "table_name": "...",
  "project_dataset": "...",
  "description": "...",
  "columns": [
    {
      "column_name": "...",
      "data_type": "...",
      "nullable": true/false,
      "description": "...",
      "business_context": "...",
      "example_values": [...]
    }
  ],
  "key_metrics": {...},
  "tips_for_stakeholders": [...]
}
```

## 🔗 Table Relationships

- **Location Table** → **Merchant Table**: Link via address, area, province
- **Merchant Table** → **MSE Mapping**: Link via area, region, province
- **EDC Order Table** → **Merchant Table**: Link via janus_account_id, business_type

## ⚡ Quick Tips for Stakeholders

✅ **DO:**
- Use the SSOT merchant table (ms_merchant_profiling_ssot_opentable) as your primary merchant reference
- Filter location data by `parsing_status = 'COMPLETE_HIGH_CONFIDENCE'` for reliable coordinates
- Check the documentation file for each table before building queries
- Use `current_mse_lead` to understand Merchant Sales Executive assignments

❌ **DON'T:**
- Use deprecated columns marked with "old_*_dont_use" prefix
- Assume sparse tables have complete data coverage - verify sample data first
- Include system metadata columns (starting with "_sdc_") in business reports

## 📞 Need Help?

Refer to the "tips_for_stakeholders" section at the end of each documentation file for specific guidance on how to use that table's data.

---

**Last Updated**: 2025-12-20  
**Documentation Version**: 1.0
