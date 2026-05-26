# Tables to Document

- ledger-fcc1e.trb_pymnts_derived.location_gmaps_static
phone_number as user_id identifier. This table was the results of Geocoding API from merchant KYB lat/lng and already being mapped to BukuWarung MSE Mapping. 

- ledger-fcc1e.datamart_opentable.mapping_area_mse_opentable
Table explaining MSE (Merchant Success Executive) starts from MSE Name, Mapping area, province, city, and also their reporting leaders, hoa, and hor

- ledger-fcc1e.merchant_success_analytics.ms_merchant_profiling_ssot
PhoneNumber as user_id identifier. Table explaining BukuWarung Merchant Profile. Columns start with "has" or "is" explaining ownership of  EDC, loan, or other Products beside BukuWarung

- ledger-fcc1e.db_accounting.prod_edc_order
Table explaining Historical EDC Order from Merchants, each row represents unique order fromm merchants

- ledger-fcc1e.fs_datamart.mee_weekly_route_plan
Table explaining weekly route plan assigned to each MEE for helping them reach out their targeted merchant for loan offering in each week

- ledger-fcc1e.fs_datamart.credit_memo
Table explaining credit memo that was results from merchant submitted loan interview with BukuWarung Lending Ops Team. Containing several column related to merchant profile, pefindo status and historical loans, business information, and their final score

- ledger-fcc1e.merchant_success_analytics.ms_form_hiring_and_active
Table explaining merchant sales executive (MSE) and retail sales executive (RSE) hiring process and steps. Containing several information such as all hiring steps complete with the timestamp for each, is sales active currently or not, sales start active date and end date, CV analysis results and score from AI assessment

- ledger-fcc1e.payment_reports.payments_ssot
Table explaining payment product in bukuwarung such as Core Payment (CP) and Bill Payment (PPOB). Also showing money in and money out. Contains several value like money in and out, fee, revenue in gross and net, etc.

- ledger-fcc1e.merchant_success_analytics.retail_ph_visit_ssot
Table explaining retail sales executive (RSE) visit in philipine country. Contains both offline and online visit activity. Also contains several column, such as merchant information, merchant identifier by phone_number, area visit, visit coordinates and other visit informations

- ledger-fcc1e.datamart_opentable.fs_credit_memo
Table containing credit memo information for loan assessment. Financial snapshot of merchant creditworthiness and loan eligibility.

- ledger-fcc1e.datamart_opentable.fs_loan_users
Table mapping users to their loan relationships. Tracks which merchants have taken loans and their loan lifecycle status.

- ledger-fcc1e.datamart_opentable.fs_loans
Table containing loan transaction records. Each row represents a unique loan with terms, amounts, status, and repayment information.

- ledger-fcc1e.datamart_opentable.fs_submissions
Table containing merchant loan application submissions. Tracks initial application data, status, and submission timeline.