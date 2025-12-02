-- Diagnostic query to find where "website" is getting Channel_Grouping_Name = 'Ecosystem'
-- Run this to understand the data flow

-- 1. Check if "website" exists in Channel_Group_Mapping
SELECT 
  'Channel_Group_Mapping Table' AS source,
  Original_Source_Salesforce,
  Channel_Grouping_Name
FROM `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping`
WHERE LOWER(Original_Source_Salesforce) = 'website'

UNION ALL

-- 2. Check what Channel_Grouping_Name "website" has in the source view
SELECT 
  'vw_funnel_lead_to_joined_v2' AS source,
  Original_source AS Original_Source_Salesforce,
  Channel_Grouping_Name
FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
WHERE LOWER(Original_source) = 'website'
  AND Channel_Grouping_Name = 'Ecosystem'
GROUP BY 1, 2, 3
LIMIT 10

UNION ALL

-- 3. Check the actual vs forecast view
SELECT 
  'vw_actual_vs_forecast_by_source' AS source,
  Original_source AS Original_Source_Salesforce,
  Channel_Grouping_Name
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE LOWER(Original_source) = 'website'
  AND Channel_Grouping_Name = 'Ecosystem'
GROUP BY 1, 2, 3
LIMIT 10;

