-- Query to find Leads/Opportunities with Fidelity as a custodian
-- Matches on CRD to staging_discovery tables (t1, t2, t3)
-- Excludes specific dispositions and DoNotCall records

WITH 
  -- Combine all staging discovery tables
  staging_discovery AS (
    SELECT 
      RepCRD,
      Custodian1,
      Custodian2,
      Custodian3,
      Custodian4,
      Custodian5,
      CustodianAUM_Fidelity_NationalFinancial,
      TotalAssetsInMillions,
      SocialMedia_LinkedIn,
      Email_BusinessType,
      DirectDial_Phone,
      Branch_Phone,
      HQ_Phone
    FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t1`
    
    UNION ALL
    
    SELECT 
      RepCRD,
      Custodian1,
      Custodian2,
      Custodian3,
      Custodian4,
      Custodian5,
      CustodianAUM_Fidelity_NationalFinancial,
      TotalAssetsInMillions,
      SocialMedia_LinkedIn,
      Email_BusinessType,
      DirectDial_Phone,
      Branch_Phone,
      HQ_Phone
    FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t2`
    
    UNION ALL
    
    SELECT 
      RepCRD,
      Custodian1,
      Custodian2,
      Custodian3,
      Custodian4,
      Custodian5,
      CustodianAUM_Fidelity_NationalFinancial,
      TotalAssetsInMillions,
      SocialMedia_LinkedIn,
      Email_BusinessType,
      DirectDial_Phone,
      Branch_Phone,
      HQ_Phone
    FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
  ),
  
  -- Get Opportunities first (primary source)
  opportunities AS (
    SELECT 
      o.Id AS OpportunityId,
      CAST(NULL AS STRING) AS LeadId,
      CAST(NULL AS STRING) AS ProspectID,
      o.Name,
      o.FA_CRD__c,
      CAST(NULL AS STRING) AS Disposition__c,  -- Not available in Opportunity table, but needed for UNION
      o.Primary_Phone_Number__c AS Phone,
      o.Personal_Email__c AS Email,
      'Opportunity' AS SourceType
    FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    WHERE o.IsDeleted = FALSE
      AND o.FA_CRD__c IS NOT NULL
      AND o.FA_CRD__c != ''
  ),
  
  -- Get Leads that are NOT in Opportunities (fallback)
  leads_only AS (
    SELECT 
      CAST(NULL AS STRING) AS OpportunityId,
      l.Id AS LeadId,
      l.Full_Prospect_ID__c AS ProspectID,
      l.Name,
      l.FA_CRD__c,
      l.Disposition__c,
      COALESCE(l.MobilePhone, l.Phone) AS Phone,
      COALESCE(l.Personal_Email__c, l.Email) AS Email,
      'Lead' AS SourceType
    FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
    WHERE l.IsDeleted = FALSE
      AND l.FA_CRD__c IS NOT NULL
      AND l.FA_CRD__c != ''
      AND (l.DoNotCall IS NULL OR l.DoNotCall = FALSE)
      AND (l.Disposition__c IS NULL 
           OR l.Disposition__c NOT IN ('Book Not Transferable', 'Insufficient Revenue'))
      -- Exclude leads that are already in opportunities
      AND NOT EXISTS (
        SELECT 1 
        FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
        WHERE o.FA_CRD__c = l.FA_CRD__c
          AND o.IsDeleted = FALSE
      )
  ),
  
  -- Combine Opportunities and Leads
  sfdc_records AS (
    SELECT * FROM opportunities
    UNION ALL
    SELECT * FROM leads_only
  ),
  
  -- Filter staging discovery for Fidelity custodians
  -- Includes: Fidelity, National Financial Services (NFS), Fidelity Brokerage Services (FBS), etc.
  fidelity_staging_filtered AS (
    SELECT *
    FROM staging_discovery
    WHERE RepCRD IS NOT NULL
      AND (
        -- Check each custodian field for Fidelity variations (case-insensitive)
        -- Primary: National Financial Services LLC (NFS) - the actual custodian entity
        -- Secondary: Fidelity Brokerage Services LLC (FBS)
        -- Also catches: Fidelity, Fidelity Management Trust Company (FMTC)
        REGEXP_CONTAINS(UPPER(COALESCE(Custodian1, '')), r'FIDELITY|NATIONAL FINANCIAL SERVICES|NFS|FIDELITY BROKERAGE SERVICES|FBS|FIDELITY MANAGEMENT TRUST|FMTC')
        OR REGEXP_CONTAINS(UPPER(COALESCE(Custodian2, '')), r'FIDELITY|NATIONAL FINANCIAL SERVICES|NFS|FIDELITY BROKERAGE SERVICES|FBS|FIDELITY MANAGEMENT TRUST|FMTC')
        OR REGEXP_CONTAINS(UPPER(COALESCE(Custodian3, '')), r'FIDELITY|NATIONAL FINANCIAL SERVICES|NFS|FIDELITY BROKERAGE SERVICES|FBS|FIDELITY MANAGEMENT TRUST|FMTC')
        OR REGEXP_CONTAINS(UPPER(COALESCE(Custodian4, '')), r'FIDELITY|NATIONAL FINANCIAL SERVICES|NFS|FIDELITY BROKERAGE SERVICES|FBS|FIDELITY MANAGEMENT TRUST|FMTC')
        OR REGEXP_CONTAINS(UPPER(COALESCE(Custodian5, '')), r'FIDELITY|NATIONAL FINANCIAL SERVICES|NFS|FIDELITY BROKERAGE SERVICES|FBS|FIDELITY MANAGEMENT TRUST|FMTC')
      )
  ),
  
  -- Deduplicate staging records by RepCRD - keep record with highest Fidelity AUM (most current)
  fidelity_staging AS (
    SELECT 
      RepCRD,
      Custodian1,
      Custodian2,
      Custodian3,
      Custodian4,
      Custodian5,
      CustodianAUM_Fidelity_NationalFinancial,
      TotalAssetsInMillions,
      SocialMedia_LinkedIn,
      Email_BusinessType,
      DirectDial_Phone,
      Branch_Phone,
      HQ_Phone
    FROM (
      SELECT *,
        ROW_NUMBER() OVER (
          PARTITION BY RepCRD 
          ORDER BY 
            COALESCE(CustodianAUM_Fidelity_NationalFinancial, 0) DESC,  -- Prefer highest AUM
            COALESCE(SAFE_CAST(TotalAssetsInMillions AS FLOAT64), 0) DESC  -- Secondary sort by total assets
        ) AS rn
      FROM fidelity_staging_filtered
    )
    WHERE rn = 1
  ),
  
  -- Deduplicate Salesforce records by CRD - prefer Opportunity, then most recent/alphabetical
  sfdc_records_deduped AS (
    SELECT 
      OpportunityId,
      LeadId,
      ProspectID,
      Name,
      FA_CRD__c,
      Disposition__c,
      Phone,
      Email,
      SourceType
    FROM (
      SELECT *,
        ROW_NUMBER() OVER (
          PARTITION BY REGEXP_REPLACE(FA_CRD__c, r'[^0-9]', '')
          ORDER BY 
            CASE SourceType WHEN 'Opportunity' THEN 1 ELSE 2 END,  -- Prefer Opportunity over Lead
            OpportunityId,  -- If multiple Opportunities, use alphabetical
            LeadId  -- If multiple Leads, use alphabetical
        ) AS rn
      FROM sfdc_records
      WHERE REGEXP_REPLACE(FA_CRD__c, r'[^0-9]', '') != ''
    )
    WHERE rn = 1
  )

-- Final join and select (DISTINCT not needed since we've deduplicated)
SELECT
  COALESCE(sfdc.OpportunityId, sfdc.LeadId) AS RecordId,
  sfdc.SourceType,
  sfdc.Name,
  -- Phone numbers: prioritize staging table, then Salesforce
  COALESCE(
    fs.DirectDial_Phone,
    fs.Branch_Phone,
    fs.HQ_Phone,
    sfdc.Phone
  ) AS Phone,
  -- Email: prioritize Salesforce, then staging
  COALESCE(
    sfdc.Email,
    fs.Email_BusinessType
  ) AS Email,
  fs.SocialMedia_LinkedIn,
  fs.CustodianAUM_Fidelity_NationalFinancial,
  fs.TotalAssetsInMillions,
  -- Opportunity ID or Prospect ID depending on source
  CASE 
    WHEN sfdc.SourceType = 'Opportunity' THEN sfdc.OpportunityId
    WHEN sfdc.SourceType = 'Lead' THEN sfdc.ProspectID
    ELSE NULL
  END AS OpportunityOrProspectID,
  sfdc.FA_CRD__c AS CRD,
  fs.RepCRD

FROM sfdc_records_deduped sfdc
INNER JOIN fidelity_staging fs
  ON SAFE_CAST(REGEXP_REPLACE(sfdc.FA_CRD__c, r'[^0-9]', '') AS INT64) = fs.RepCRD

WHERE 
  -- Filter for minimum Fidelity custodian AUM threshold
  fs.CustodianAUM_Fidelity_NationalFinancial IS NOT NULL 
  AND fs.CustodianAUM_Fidelity_NationalFinancial >= 200

ORDER BY sfdc.Name;

