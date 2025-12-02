-- Current Opportunity Stage Start Date View
-- Provides the start date of the current stage for each opportunity, keyed by unified funnel primary key.

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_opp_current_stage_start_date` AS

WITH History_Max_Date AS (
  SELECT
    OpportunityId,
    MAX(CreatedDate) AS max_history_date
  FROM `savvy-gtm-analytics.SavvyGTMData.OpportunityFieldHistory`
  WHERE Field = 'StageName'
  GROUP BY 1
)

SELECT
  COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key,
  COALESCE(h.max_history_date, o.CreatedDate) AS current_stage_start_date
FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` AS o
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Lead` AS l
  ON o.Full_Opportunity_ID__c = l.ConvertedOpportunityId
LEFT JOIN History_Max_Date AS h
  ON o.Full_Opportunity_ID__c = h.OpportunityId
WHERE o.recordtypeid = '012Dn000000mrO3IAI';

