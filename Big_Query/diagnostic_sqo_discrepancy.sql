-- Diagnostic query to find the discrepancy between vw_funnel_lead_to_joined_v2 and vw_sga_funnel
-- for Eleni Stefanopoulos SQOs from Oct 1 - Nov 11, 2025

WITH Active_SGA_SGM_Users AS (
  SELECT DISTINCT
    Name
  FROM
    `savvy-gtm-analytics.SavvyGTMData.User`
  WHERE
    (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE
),

-- Get all SQOs from vw_funnel_lead_to_joined_v2 logic (no active filter)
All_SQOs AS (
  SELECT
    COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key,
    CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      ELSE l.SGA_Owner_Name__c
    END AS SGA_Owner_Name__c,
    o.Full_Opportunity_ID__c,
    o.Date_Became_SQO__c,
    o.SQO_raw,
    CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    l.Full_prospect_id__c,
    o.sga_name_from_opp,
    l.SGA_Owner_Name__c AS lead_sga_name,
    CASE 
      WHEN CASE
        WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
        WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
        ELSE l.SGA_Owner_Name__c
      END IN (SELECT Name FROM Active_SGA_SGM_Users) THEN 'Active SGA/SGM'
      ELSE 'NOT in Active SGA/SGM list'
    END AS active_status,
    CASE 
      WHEN CASE
        WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
        WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
        ELSE l.SGA_Owner_Name__c
      END = 'Eleni Stefanopoulos' THEN 1
      ELSE 0
    END AS is_eleni
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
  FULL OUTER JOIN (
    SELECT
      o.Full_Opportunity_ID__c,
      o.CreatedDate AS Opp_CreatedDate,
      sga_user.Name AS sga_name_from_opp,
      o.SQL__c AS SQO_raw,
      o.Date_Became_SQO__c
    FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
      ON o.SGA__c = sga_user.Id
    WHERE o.recordtypeid = '012Dn000000mrO3IAI'
  ) o
    ON l.ConvertedOpportunityId = o.Full_Opportunity_ID__c
  WHERE 
    CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1
    AND o.Date_Became_SQO__c >= '2025-10-01'
    AND o.Date_Became_SQO__c < '2025-11-12'
    AND CASE 
      WHEN CASE
        WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
        WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
        ELSE l.SGA_Owner_Name__c
      END = 'Eleni Stefanopoulos' THEN 1
      ELSE 0
    END = 1
)

SELECT
  primary_key,
  SGA_Owner_Name__c,
  Full_Opportunity_ID__c,
  Date_Became_SQO__c,
  SQO_raw,
  lead_sga_name,
  sga_name_from_opp,
  active_status,
  CASE 
    WHEN active_status = 'NOT in Active SGA/SGM list' THEN 'EXCLUDED in vw_sga_funnel'
    ELSE 'INCLUDED in vw_sga_funnel'
  END AS inclusion_status
FROM All_SQOs
ORDER BY Date_Became_SQO__c;

