-- Super-Segment Aggregation View
-- Maps leads into 3-5 high-level "Super-Segments" for V3 model training
-- This aggregates the 430+ segment combinations (LeadSource × Owner × Status) 
-- into manageable Super-Segments (Outbound, Inbound_Marketing, Partnerships_Referrals, Other)
--
-- Purpose: Fix data sparsity issue by aggregating to a higher level before forecasting

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_sga_funnel_super_segments` AS

WITH leads_with_definitions AS (
  SELECT
    DATE(CreatedDate) AS created_date,
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    CASE WHEN IsConverted = TRUE THEN 1 ELSE 0 END AS is_sql,
    LeadSource
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(CreatedDate) >= '2024-01-01'
    AND DATE(CreatedDate) <= CURRENT_DATE()
    -- EXCLUDE: Impossible dates (from Phase 0 validation - prevents data leakage)
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(CreatedDate))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
)

SELECT
  created_date,
  is_mql,
  is_sql,
  
  -- *** Super-Segment Logic ***
  -- Aggregates 20+ LeadSource values into 3-5 high-level segments
  CASE
    -- Outbound: Sales-driven, outbound prospecting sources
    WHEN COALESCE(LeadSource, 'Unknown') IN (
      'Provided Lead List', 
      'Dover', 
      'LinkedIn (Self Sourced)', 
      'Lead List (Acquired)', 
      'Outbound',
      'Purchased List',
      'Other',
      'Reddit'
    ) THEN 'Outbound'
    
    -- Inbound_Marketing: Marketing-driven, inbound sources
    WHEN LeadSource IN (
      'Event', 
      'Website', 
      'Webinar', 
      'Blog', 
      'Content', 
      'Contact Us',
      'LinkedIn (Content)',
      'LinkedIn (Automation)',
      'LinkedIn Lead Gen Form',
      'Re-Engagement',
      'RB2B',
      'Manatal',
      'Apollo'
    ) THEN 'Inbound_Marketing'
    
    -- Partnerships_Referrals: Ecosystem and referral sources
    WHEN LeadSource IN (
      'Advisor Referral', 
      'Recruitment Firm', 
      'Ashby', 
      'Advisor Waitlist', 
      'Partnership',
      'Partner',
      'Employee Referral'
    ) THEN 'Partnerships_Referrals'
    
    -- Other: Catch-all for unmapped sources (including NULL)
    ELSE 'Other'
  END AS super_segment,
  
  LeadSource  -- Keep original for analysis and debugging
  
FROM leads_with_definitions;

