-- Check what Channel_Grouping_Name "website" has in the source view
SELECT 
  Original_source,
  Channel_Grouping_Name,
  COUNT(*) as record_count
FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
WHERE LOWER(Original_source) = 'website'
GROUP BY 1, 2
ORDER BY 3 DESC;

