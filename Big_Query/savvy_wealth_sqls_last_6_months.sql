-- Query to pull CRDs (FA_CRD__c) for all SQLs from the last 6 months
-- SQLs are defined as Leads that have been converted to Opportunities (IsConverted = TRUE)
-- Gets CRD from Opportunity first, then falls back to Lead if not available

SELECT DISTINCT
  -- Get CRD from Opportunity first, then fall back to Lead
  COALESCE(o.FA_CRD__c, l.FA_CRD__c) AS FA_CRD__c

FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  ON l.ConvertedOpportunityId = o.Id

WHERE 
  -- SQL filter: Lead must be converted
  l.IsConverted = TRUE
  
  -- Date filter: Last 6 months from SQL conversion date
  AND DATE(l.ConvertedDate) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
  
  -- Only include records where CRD exists (from either Lead or Opportunity)
  AND COALESCE(o.FA_CRD__c, l.FA_CRD__c) IS NOT NULL
  AND COALESCE(o.FA_CRD__c, l.FA_CRD__c) != ''
  
  -- Exclude deleted records
  AND (l.IsDeleted IS NULL OR l.IsDeleted = FALSE)
  AND (o.IsDeleted IS NULL OR o.IsDeleted = FALSE)

ORDER BY 
  FA_CRD__c

