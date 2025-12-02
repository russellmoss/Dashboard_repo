/*
 * AdvizorPro and MarketPro Discovery Data Comparison Query
 * 
 * IMPORTANT: This query produces a ONE-TO-MANY result set.
 * 
 * One AdvizorPro record (identified by CRD) can match multiple MarketPro records
 * because representatives can be associated with multiple RIA firms. The three
 * MarketPro tables (t1, t2, t3) represent different RIA firm associations for
 * the same representatives, not different time periods.
 * 
 * Result Set Characteristics:
 * - One AdvizorPro advisor may appear multiple times (once per RIA association)
 * - Each row represents a comparison between one AdvizorPro record and one
 *   MarketPro RIA association
 * - Match confidence indicators help identify the best matches
 * 
 * Based on: advizor_pro_and_discover_data_comparision_plan.md, Section 4.4
 * 
 * Refactored into 3-step CTE structure:
 * 1. data_cleaning - Normalization and data preparation
 * 2. match_calculations - Calculate all match status columns
 * 3. final_output - Select results and calculate match_confidence
 * 
 * Enhanced with:
 * - Nickname lookup for common name variations
 * - Enhanced name normalization (removes all non-letters)
 * - Firm name normalization (strips common suffixes)
 */

WITH nickname_map AS (
  -- Common nickname to formal name mappings
  SELECT 'BILL' as nickname, 'WILLIAM' as formal_name
  UNION ALL SELECT 'BOB', 'ROBERT'
  UNION ALL SELECT 'JIM', 'JAMES'
  UNION ALL SELECT 'CHRIS', 'CHRISTOPHER'
  UNION ALL SELECT 'MIKE', 'MICHAEL'
  UNION ALL SELECT 'DAN', 'DANIEL'
  UNION ALL SELECT 'TOM', 'THOMAS'
  UNION ALL SELECT 'KEN', 'KENNETH'
  UNION ALL SELECT 'JACK', 'JOHN'
  UNION ALL SELECT 'JIM', 'JAMES'
  UNION ALL SELECT 'JOE', 'JOSEPH'
  UNION ALL SELECT 'FRANK', 'FRANCIS'
  UNION ALL SELECT 'HANK', 'HENRY'
  UNION ALL SELECT 'HARRY', 'HENRY'
  UNION ALL SELECT 'DICK', 'RICHARD'
  UNION ALL SELECT 'RICK', 'RICHARD'
  UNION ALL SELECT 'ED', 'EDWARD'
  UNION ALL SELECT 'EDDIE', 'EDWARD'
  UNION ALL SELECT 'AL', 'ALBERT'
  UNION ALL SELECT 'ALEX', 'ALEXANDER'
  UNION ALL SELECT 'ANDY', 'ANDREW'
  UNION ALL SELECT 'TONY', 'ANTHONY'
  UNION ALL SELECT 'BEN', 'BENJAMIN'
  UNION ALL SELECT 'CHARLIE', 'CHARLES'
  UNION ALL SELECT 'CHUCK', 'CHARLES'
  UNION ALL SELECT 'DAVE', 'DAVID'
  UNION ALL SELECT 'GREG', 'GREGORY'
  UNION ALL SELECT 'JEFF', 'JEFFREY'
  UNION ALL SELECT 'MATT', 'MATTHEW'
  UNION ALL SELECT 'NICK', 'NICHOLAS'
  UNION ALL SELECT 'PAT', 'PATRICK'
  UNION ALL SELECT 'PETE', 'PETER'
  UNION ALL SELECT 'PHIL', 'PHILIP'
  UNION ALL SELECT 'SAM', 'SAMUEL'
  UNION ALL SELECT 'STEVE', 'STEVEN'
  UNION ALL SELECT 'TIM', 'TIMOTHY'
  UNION ALL SELECT 'VINCE', 'VINCENT'
),
data_cleaning AS (
  -- Step 1: Combine and normalize data from both sources
  SELECT 
    -- AdvizorPro fields
    a.CRD,
    a.First_Name_Normalized,
    a.Last_Name_Normalized,
    a.First_Name_Strict,
    a.First_Name_Clean,
    a.Last_Name_Strict,
    a.Last_Name_Clean,
    a.Middle_Name_Normalized,
    a.RIA_Normalized,
    a.RIA_Clean,
    a.RIA_CRD_Int,
    a.Broker_Dealer_Normalized,
    a.Broker_Dealer_Clean,
    a.Broker_Dealer_CRD_Int,
    a.Email_1_Normalized,
    a.Phone_Normalized as Advizor_Phone_Normalized,
    a.Firm_Phone_Normalized as Advizor_Firm_Phone_Normalized,
    a.Team_Phone_Normalized as Advizor_Team_Phone_Normalized,
    a.City_Normalized,
    a.State_Normalized,
    a.Zip_Normalized,
    a.Firm_AUM,
    a.Firm_Total_Accounts,
    a.Years_of_Experience,
    a.Years_with_Current_BD,
    -- MarketPro fields
    m.RepCRD,
    m.FirstName,
    m.LastName,
    m.FirstName_Strict,
    m.FirstName_Clean,
    m.LastName_Strict,
    m.LastName_Clean,
    m.MiddleName,
    m.RIAFirmName,
    m.RIAFirmName_Clean,
    m.RIAFirmCRD,
    m.BDNameCurrent,
    m.BDNameCurrent_Clean,
    m.PrimaryBDFirmCRD,
    m.Email_BusinessType_Normalized,
    m.Direct_Phone_Normalized,
    m.Branch_Phone_Normalized,
    m.HQ_Phone_Normalized as MarketPro_HQ_Phone_Normalized,
    m.Home_Phone_Normalized as MarketPro_Home_Phone_Normalized,
    m.Branch_City_Normalized,
    m.Branch_State_Normalized,
    m.Branch_ZipCode_Normalized,
    m.TotalAssetsInMillions_Numeric,
    m.TotalAccounts_Numeric,
    m.DateBecameRep_NumberOfYears,
    m.DateOfHireAtCurrentFirm_NumberOfYears,
    m.source_table
  FROM (
    -- AdvizorPro normalization
    SELECT 
      CRD,
      UPPER(TRIM(First_Name)) as First_Name_Normalized,
      UPPER(TRIM(Last_Name)) as Last_Name_Normalized,
      REGEXP_REPLACE(UPPER(TRIM(First_Name)), r'[^A-Z]', '') as First_Name_Strict,
      REGEXP_REPLACE(UPPER(TRIM(First_Name)), r'[^A-Z]', '') as First_Name_Clean,
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(TRIM(Last_Name)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
        r'[^A-Z]', ''
      ) as Last_Name_Strict,
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(TRIM(Last_Name)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
        r'[^A-Z]', ''
      ) as Last_Name_Clean,
      UPPER(TRIM(Middle_Name)) as Middle_Name_Normalized,
      UPPER(TRIM(RIA)) as RIA_Normalized,
      -- Firm name normalization: strip common suffixes
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(UPPER(TRIM(RIA)), r' LLC\.?$', ''),
                      r' INC\.?$', ''
                    ), r' CORP\.?$', ''
                  ), r' LTD\.?$', ''
                ), r' ADVISORS?\.?$', ''
              ), r' MANAGEMENT\.?$', ''
            ), r' GROUP\.?$', ''
          ), r' PARTNERS?\.?$', ''
        ), r' (WEALTH|FINANCIAL)\.?$', ''
      ) as RIA_Clean,
      SAFE_CAST(
        REGEXP_EXTRACT(
          COALESCE(CAST(RIA_CRD AS STRING), ''), 
          r'^(\d+)'
        ) AS INT64
      ) as RIA_CRD_Int,
      UPPER(TRIM(Broker_Dealer)) as Broker_Dealer_Normalized,
      -- Firm name normalization: strip common suffixes
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(UPPER(TRIM(Broker_Dealer)), r' LLC\.?$', ''),
                      r' INC\.?$', ''
                    ), r' CORP\.?$', ''
                  ), r' LTD\.?$', ''
                ), r' ADVISORS?\.?$', ''
              ), r' MANAGEMENT\.?$', ''
            ), r' GROUP\.?$', ''
          ), r' PARTNERS?\.?$', ''
        ), r' (WEALTH|FINANCIAL)\.?$', ''
      ) as Broker_Dealer_Clean,
      SAFE_CAST(
        REGEXP_EXTRACT(
          COALESCE(CAST(Broker_Dealer_CRD AS STRING), ''), 
          r'^(\d+)'
        ) AS INT64
      ) as Broker_Dealer_CRD_Int,
      LOWER(TRIM(Email_1)) as Email_1_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(Phone, ''), r'[^0-9]', ''), 10) as Phone_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(Firm_Phone, ''), r'[^0-9]', ''), 10) as Firm_Phone_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(Named_Team_Phone, ''), r'[^0-9]', ''), 10) as Team_Phone_Normalized,
      UPPER(TRIM(City)) as City_Normalized,
      UPPER(TRIM(State)) as State_Normalized,
      Zip as Zip_Normalized,
      Firm_AUM,
      Firm_Total_Accounts,
      Years_of_Experience,
      Years_with_Current_BD
    FROM `savvy-gtm-analytics.SavvyGTMData.last-6-month-advizorpro`
    WHERE CRD IS NOT NULL
  ) a
  INNER JOIN (
    -- MarketPro normalization (unified from t1, t2, t3)
    SELECT 
      RepCRD,
      FirstName,
      LastName,
      REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Strict,
      REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
        r'[^A-Z]', ''
      ) as LastName_Strict,
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
        r'[^A-Z]', ''
      ) as LastName_Clean,
      MiddleName,
      RIAFirmName,
      -- Firm name normalization: strip common suffixes
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(UPPER(TRIM(RIAFirmName)), r' LLC\.?$', ''),
                      r' INC\.?$', ''
                    ), r' CORP\.?$', ''
                  ), r' LTD\.?$', ''
                ), r' ADVISORS?\.?$', ''
              ), r' MANAGEMENT\.?$', ''
            ), r' GROUP\.?$', ''
          ), r' PARTNERS?\.?$', ''
        ), r' (WEALTH|FINANCIAL)\.?$', ''
      ) as RIAFirmName_Clean,
      RIAFirmCRD,
      BDNameCurrent,
      -- Firm name normalization: strip common suffixes
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(UPPER(TRIM(BDNameCurrent)), r' LLC\.?$', ''),
                      r' INC\.?$', ''
                    ), r' CORP\.?$', ''
                  ), r' LTD\.?$', ''
                ), r' ADVISORS?\.?$', ''
              ), r' MANAGEMENT\.?$', ''
            ), r' GROUP\.?$', ''
          ), r' PARTNERS?\.?$', ''
        ), r' (WEALTH|FINANCIAL)\.?$', ''
      ) as BDNameCurrent_Clean,
      SAFE_CAST(
        REGEXP_EXTRACT(
          COALESCE(PrimaryBDFirmCRD, ''), 
          r'^(\d+)'
        ) AS INT64
      ) as PrimaryBDFirmCRD,
      LOWER(TRIM(Email_BusinessType)) as Email_BusinessType_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(DirectDial_Phone, ''), r'[^0-9]', ''), 10) as Direct_Phone_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(Branch_Phone, ''), r'[^0-9]', ''), 10) as Branch_Phone_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(HQ_Phone, ''), r'[^0-9]', ''), 10) as HQ_Phone_Normalized,
      RIGHT(REGEXP_REPLACE(COALESCE(Home_Phone, ''), r'[^0-9]', ''), 10) as Home_Phone_Normalized,
      UPPER(TRIM(Branch_City)) as Branch_City_Normalized,
      UPPER(TRIM(Branch_State)) as Branch_State_Normalized,
      SAFE_CAST(Branch_ZipCode AS INT64) as Branch_ZipCode_Normalized,
      CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
      CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as TotalAccounts_Numeric,
      DateBecameRep_NumberOfYears,
      DateOfHireAtCurrentFirm_NumberOfYears,
      source_table
    FROM (
      SELECT 
        RepCRD,
        FirstName,
        LastName,
        MiddleName,
        RIAFirmName,
        RIAFirmCRD,
        BDNameCurrent,
        CAST(PrimaryBDFirmCRD AS STRING) as PrimaryBDFirmCRD,
        Email_BusinessType,
        DirectDial_Phone,
        Branch_Phone,
        HQ_Phone,
        Home_Phone,
        Branch_City,
        Branch_State,
        SAFE_CAST(Branch_ZipCode AS FLOAT64) as Branch_ZipCode,
        TotalAssetsInMillions,
        TotalAccounts,
        DateBecameRep_NumberOfYears,
        DateOfHireAtCurrentFirm_NumberOfYears,
        't1' as source_table
      FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t1`
      WHERE RepCRD IS NOT NULL
      
      UNION ALL
      
      SELECT 
        RepCRD,
        FirstName,
        LastName,
        MiddleName,
        RIAFirmName,
        RIAFirmCRD,
        BDNameCurrent,
        CAST(PrimaryBDFirmCRD AS STRING) as PrimaryBDFirmCRD,
        Email_BusinessType,
        DirectDial_Phone,
        Branch_Phone,
        HQ_Phone,
        Home_Phone,
        Branch_City,
        Branch_State,
        SAFE_CAST(Branch_ZipCode AS FLOAT64) as Branch_ZipCode,
        TotalAssetsInMillions,
        TotalAccounts,
        DateBecameRep_NumberOfYears,
        DateOfHireAtCurrentFirm_NumberOfYears,
        't2' as source_table
      FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t2`
      WHERE RepCRD IS NOT NULL
      
      UNION ALL
      
      SELECT 
        RepCRD,
        FirstName,
        LastName,
        MiddleName,
        RIAFirmName,
        RIAFirmCRD,
        BDNameCurrent,
        CAST(PrimaryBDFirmCRD AS STRING) as PrimaryBDFirmCRD,
        Email_BusinessType,
        DirectDial_Phone,
        Branch_Phone,
        HQ_Phone,
        Home_Phone,
        Branch_City,
        Branch_State,
        SAFE_CAST(Branch_ZipCode AS FLOAT64) as Branch_ZipCode,
        TotalAssetsInMillions,
        TotalAccounts,
        DateBecameRep_NumberOfYears,
        DateOfHireAtCurrentFirm_NumberOfYears,
        't3' as source_table
      FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
      WHERE RepCRD IS NOT NULL
    )
  ) m
  ON a.CRD = m.RepCRD
),
match_calculations AS (
  -- Step 2: Calculate all match status columns with nickname lookup
  SELECT 
    dc.*,
    
    -- Name matching with advanced cleaning, nickname lookup, and fuzzy logic
    CASE 
      -- Strict Match (Exact) - using Clean columns for consistency
      WHEN dc.First_Name_Clean = dc.FirstName_Clean
       AND dc.Last_Name_Clean = dc.LastName_Clean
      THEN 'MATCH' 
      
      -- Suffix/Punctuation Agnostic Match (Fixes "LAWTON III" and "R.PHILIP")
      WHEN dc.First_Name_Strict = dc.FirstName_Strict
       AND dc.Last_Name_Strict = dc.LastName_Strict
      THEN 'MATCH_CLEANED'
      
      -- Nickname Match: Check if one is nickname and other is formal name
      WHEN dc.Last_Name_Clean = dc.LastName_Clean
       AND (
         -- Advizor nickname matches MarketPro formal name
         (nm_adv.formal_name IS NOT NULL AND nm_adv.formal_name = dc.FirstName_Clean)
         OR
         -- MarketPro nickname matches Advizor formal name
         (nm_mkt.formal_name IS NOT NULL AND nm_mkt.formal_name = dc.First_Name_Clean)
       )
      THEN 'MATCH_NICKNAME'
      
      -- First Initial Match (Last name matches, first initial matches)
      WHEN dc.Last_Name_Clean = dc.LastName_Clean
       AND SUBSTR(dc.First_Name_Clean, 1, 1) = SUBSTR(dc.FirstName_Clean, 1, 1)
       AND LENGTH(dc.First_Name_Clean) > 0
       AND LENGTH(dc.FirstName_Clean) > 0
      THEN 'MATCH_INITIAL'
      
      -- Hyphenation/Containment Match (Fixes "SIMON-WALLACE" vs "Wallace")
      WHEN dc.First_Name_Normalized = UPPER(TRIM(dc.FirstName))
       AND (STRPOS(dc.Last_Name_Normalized, UPPER(TRIM(dc.LastName))) > 0 
            OR STRPOS(UPPER(TRIM(dc.LastName)), dc.Last_Name_Normalized) > 0)
      THEN 'MATCH_CONTAINED'
      
      -- Typo Tolerance (Soundex) - For "Parthiu" vs "Parthiv" type variations
      WHEN SOUNDEX(dc.First_Name_Normalized) = SOUNDEX(UPPER(TRIM(dc.FirstName)))
       AND SOUNDEX(dc.Last_Name_Normalized) = SOUNDEX(UPPER(TRIM(dc.LastName)))
      THEN 'MATCH_FUZZY'
      
      -- Levenshtein Distance for Last Name Typos
      -- If last name has a typo (edit distance <= 2 for names > 3 chars, <= 1 for shorter) and first name matches exactly
      WHEN dc.First_Name_Clean = dc.FirstName_Clean
       AND dc.Last_Name_Clean != '' 
       AND dc.LastName_Clean != ''
       AND (
         (LENGTH(dc.Last_Name_Clean) > 3 AND EDIT_DISTANCE(dc.Last_Name_Clean, dc.LastName_Clean) <= 2)
         OR (LENGTH(dc.Last_Name_Clean) <= 3 AND EDIT_DISTANCE(dc.Last_Name_Clean, dc.LastName_Clean) <= 1)
       )
      THEN 'MATCH_TYPO'
      
      -- First 3 Character Fallback for Unusual Nicknames (e.g., "Rukayat" vs "Kaya")
      -- If last name matches and first name starts with the other or first 3 chars match
      WHEN dc.Last_Name_Clean = dc.LastName_Clean
       AND dc.Last_Name_Clean != ''
       AND dc.LastName_Clean != ''
       AND (
         STARTS_WITH(dc.First_Name_Clean, dc.FirstName_Clean)
         OR STARTS_WITH(dc.FirstName_Clean, dc.First_Name_Clean)
         OR (LENGTH(dc.First_Name_Clean) >= 3 AND LENGTH(dc.FirstName_Clean) >= 3 
             AND SUBSTR(dc.First_Name_Clean, 1, 3) = SUBSTR(dc.FirstName_Clean, 1, 3))
       )
      THEN 'MATCH_NICKNAME_FUZZY'
      
      ELSE 'MISMATCH' 
    END as name_match_status,
    
    -- RIA matching with substring support, firm name normalization, and NULL handling
    CASE 
      -- Both NULL or empty - match (both missing)
      WHEN (dc.RIA_Normalized IS NULL OR dc.RIA_Normalized = '') 
       AND (dc.RIAFirmName IS NULL OR TRIM(dc.RIAFirmName) = '')
       AND dc.RIA_CRD_Int IS NULL
       AND dc.RIAFirmCRD IS NULL
      THEN 'MATCH_BOTH_MISSING'
      -- Exact match
      WHEN dc.RIA_Normalized = UPPER(TRIM(dc.RIAFirmName))
       AND dc.RIA_CRD_Int = dc.RIAFirmCRD
      THEN 'MATCH' 
      -- Firm name fuzzy match (normalized names match)
      WHEN dc.RIA_Clean = dc.RIAFirmName_Clean
       AND dc.RIA_Clean != ''
       AND dc.RIAFirmName_Clean != ''
      THEN 'MATCH_FIRM_FUZZY'
      -- CRD match with substring name
      WHEN dc.RIA_CRD_Int = dc.RIAFirmCRD
       AND STRPOS(dc.RIA_Normalized, UPPER(TRIM(dc.RIAFirmName))) > 0
      THEN 'MATCH_SUBSTRING'
      -- CRD match only
      WHEN dc.RIA_CRD_Int = dc.RIAFirmCRD
      THEN 'CRD_MATCH_NAME_DIFF'
      -- Substring name match without CRD
      WHEN STRPOS(dc.RIA_Normalized, UPPER(TRIM(dc.RIAFirmName))) > 0
      THEN 'MATCH_SUBSTRING_NO_CRD'
      ELSE 'MISMATCH' 
    END as ria_match_status,
    
    -- BD matching with firm name normalization and NULL handling
    CASE 
      -- Both NULL or empty - match (both missing)
      WHEN (dc.Broker_Dealer_Normalized IS NULL OR dc.Broker_Dealer_Normalized = '') 
       AND (dc.BDNameCurrent IS NULL OR TRIM(dc.BDNameCurrent) = '')
       AND dc.Broker_Dealer_CRD_Int IS NULL
       AND dc.PrimaryBDFirmCRD IS NULL
      THEN 'MATCH_BOTH_MISSING'
      -- Exact match
      WHEN dc.Broker_Dealer_Normalized = UPPER(TRIM(dc.BDNameCurrent))
       AND dc.Broker_Dealer_CRD_Int = dc.PrimaryBDFirmCRD
      THEN 'MATCH' 
      -- Firm name fuzzy match (normalized names match)
      WHEN dc.Broker_Dealer_Clean = dc.BDNameCurrent_Clean
       AND dc.Broker_Dealer_Clean != ''
       AND dc.BDNameCurrent_Clean != ''
      THEN 'MATCH_FIRM_FUZZY'
      -- CRD match only
      WHEN dc.Broker_Dealer_CRD_Int = dc.PrimaryBDFirmCRD
      THEN 'CRD_MATCH_NAME_DIFF'
      ELSE 'MISMATCH' 
    END as bd_match_status,
    
    -- Email matching with fuzzy logic, alias handling, and NULL handling
    CASE 
      -- Both NULL or empty - match (both missing)
      WHEN (dc.Email_1_Normalized IS NULL OR dc.Email_1_Normalized = '') 
       AND (dc.Email_BusinessType_Normalized IS NULL OR dc.Email_BusinessType_Normalized = '')
      THEN 'MATCH_BOTH_MISSING'
      -- Exact match
      WHEN dc.Email_1_Normalized = dc.Email_BusinessType_Normalized
      THEN 'MATCH' 
      -- Combined Alias AND Fuzzy User Match (check this before individual checks)
      WHEN dc.Email_1_Normalized IS NOT NULL 
       AND dc.Email_BusinessType_Normalized IS NOT NULL
       AND dc.Email_1_Normalized LIKE '%@%'
       AND dc.Email_BusinessType_Normalized LIKE '%@%'
       AND REGEXP_REPLACE(
             REGEXP_REPLACE(dc.Email_1_Normalized, '@commonwealth.com', '@cfnmail.com'),
             r'[._]', ''
           ) = 
           REGEXP_REPLACE(dc.Email_BusinessType_Normalized, r'[._]', '')
      THEN 'MATCH_ALIAS_AND_FUZZY'
      -- Handle Commonwealth alias: @commonwealth.com -> @cfnmail.com (exact username match)
      WHEN REGEXP_REPLACE(dc.Email_1_Normalized, '@commonwealth.com', '@cfnmail.com') = dc.Email_BusinessType_Normalized
       OR REGEXP_REPLACE(dc.Email_BusinessType_Normalized, '@commonwealth.com', '@cfnmail.com') = dc.Email_1_Normalized
      THEN 'MATCH_ALIAS'
      -- Fuzzy username matching: ignore dots/underscores in username part (same domain)
      WHEN dc.Email_1_Normalized IS NOT NULL 
       AND dc.Email_BusinessType_Normalized IS NOT NULL
       AND dc.Email_1_Normalized LIKE '%@%'
       AND dc.Email_BusinessType_Normalized LIKE '%@%'
       AND REGEXP_REPLACE(SPLIT(dc.Email_1_Normalized, '@')[OFFSET(0)], r'[._]', '') = 
           REGEXP_REPLACE(SPLIT(dc.Email_BusinessType_Normalized, '@')[OFFSET(0)], r'[._]', '')
       AND SPLIT(dc.Email_1_Normalized, '@')[OFFSET(1)] = 
           SPLIT(dc.Email_BusinessType_Normalized, '@')[OFFSET(1)]
      THEN 'MATCH_FUZZY_USER'
      -- Data gaps
      WHEN dc.Email_1_Normalized IS NULL OR dc.Email_1_Normalized = ''
      THEN 'MISSING_IN_ADVIZOR'
      WHEN dc.Email_BusinessType_Normalized IS NULL OR dc.Email_BusinessType_Normalized = ''
      THEN 'MISSING_IN_MARKETPRO'
      ELSE 'MISMATCH' 
    END as email_match_status,
    
    -- Phone matching with "Any-to-Any" strategy across all phone columns
    CASE 
      -- 1. Primary Match: Advizor_Phone matches Direct OR Branch
      WHEN dc.Advizor_Phone_Normalized IS NOT NULL 
       AND dc.Advizor_Phone_Normalized != '' 
       AND LENGTH(dc.Advizor_Phone_Normalized) >= 10
       AND (
         (dc.Direct_Phone_Normalized IS NOT NULL AND dc.Direct_Phone_Normalized != '' AND dc.Advizor_Phone_Normalized = dc.Direct_Phone_Normalized)
         OR (dc.Branch_Phone_Normalized IS NOT NULL AND dc.Branch_Phone_Normalized != '' AND dc.Advizor_Phone_Normalized = dc.Branch_Phone_Normalized)
       )
      THEN 'MATCH_PRIMARY'
      
      -- 2. Secondary Match: Advizor_Phone matches HQ OR Home
      WHEN dc.Advizor_Phone_Normalized IS NOT NULL 
       AND dc.Advizor_Phone_Normalized != '' 
       AND LENGTH(dc.Advizor_Phone_Normalized) >= 10
       AND (
         (dc.MarketPro_HQ_Phone_Normalized IS NOT NULL AND dc.MarketPro_HQ_Phone_Normalized != '' AND dc.Advizor_Phone_Normalized = dc.MarketPro_HQ_Phone_Normalized)
         OR (dc.MarketPro_Home_Phone_Normalized IS NOT NULL AND dc.MarketPro_Home_Phone_Normalized != '' AND dc.Advizor_Phone_Normalized = dc.MarketPro_Home_Phone_Normalized)
       )
      THEN 'MATCH_SECONDARY'
      
      -- 3. Cross Match: Firm_Phone OR Team_Phone matches ANY MarketPro phone (Direct, Branch, HQ, Home)
      WHEN (
        (dc.Advizor_Firm_Phone_Normalized IS NOT NULL AND dc.Advizor_Firm_Phone_Normalized != '' AND LENGTH(dc.Advizor_Firm_Phone_Normalized) >= 10
         AND (
           (dc.Direct_Phone_Normalized IS NOT NULL AND dc.Direct_Phone_Normalized != '' AND dc.Advizor_Firm_Phone_Normalized = dc.Direct_Phone_Normalized)
           OR (dc.Branch_Phone_Normalized IS NOT NULL AND dc.Branch_Phone_Normalized != '' AND dc.Advizor_Firm_Phone_Normalized = dc.Branch_Phone_Normalized)
           OR (dc.MarketPro_HQ_Phone_Normalized IS NOT NULL AND dc.MarketPro_HQ_Phone_Normalized != '' AND dc.Advizor_Firm_Phone_Normalized = dc.MarketPro_HQ_Phone_Normalized)
           OR (dc.MarketPro_Home_Phone_Normalized IS NOT NULL AND dc.MarketPro_Home_Phone_Normalized != '' AND dc.Advizor_Firm_Phone_Normalized = dc.MarketPro_Home_Phone_Normalized)
         ))
        OR (dc.Advizor_Team_Phone_Normalized IS NOT NULL AND dc.Advizor_Team_Phone_Normalized != '' AND LENGTH(dc.Advizor_Team_Phone_Normalized) >= 10
         AND (
           (dc.Direct_Phone_Normalized IS NOT NULL AND dc.Direct_Phone_Normalized != '' AND dc.Advizor_Team_Phone_Normalized = dc.Direct_Phone_Normalized)
           OR (dc.Branch_Phone_Normalized IS NOT NULL AND dc.Branch_Phone_Normalized != '' AND dc.Advizor_Team_Phone_Normalized = dc.Branch_Phone_Normalized)
           OR (dc.MarketPro_HQ_Phone_Normalized IS NOT NULL AND dc.MarketPro_HQ_Phone_Normalized != '' AND dc.Advizor_Team_Phone_Normalized = dc.MarketPro_HQ_Phone_Normalized)
           OR (dc.MarketPro_Home_Phone_Normalized IS NOT NULL AND dc.MarketPro_Home_Phone_Normalized != '' AND dc.Advizor_Team_Phone_Normalized = dc.MarketPro_Home_Phone_Normalized)
         ))
      )
      THEN 'MATCH_CROSS_REF'
      
      -- 4. Contained Match: Advizor_Phone is contained within (or contains) ANY of the 4 MarketPro phones
      WHEN dc.Advizor_Phone_Normalized IS NOT NULL 
       AND dc.Advizor_Phone_Normalized != ''
       AND LENGTH(dc.Advizor_Phone_Normalized) >= 10
       AND (
         (dc.Direct_Phone_Normalized IS NOT NULL AND dc.Direct_Phone_Normalized != '' AND LENGTH(dc.Direct_Phone_Normalized) >= 10
          AND (STRPOS(dc.Advizor_Phone_Normalized, dc.Direct_Phone_Normalized) > 0 OR STRPOS(dc.Direct_Phone_Normalized, dc.Advizor_Phone_Normalized) > 0))
         OR (dc.Branch_Phone_Normalized IS NOT NULL AND dc.Branch_Phone_Normalized != '' AND LENGTH(dc.Branch_Phone_Normalized) >= 10
          AND (STRPOS(dc.Advizor_Phone_Normalized, dc.Branch_Phone_Normalized) > 0 OR STRPOS(dc.Branch_Phone_Normalized, dc.Advizor_Phone_Normalized) > 0))
         OR (dc.MarketPro_HQ_Phone_Normalized IS NOT NULL AND dc.MarketPro_HQ_Phone_Normalized != '' AND LENGTH(dc.MarketPro_HQ_Phone_Normalized) >= 10
          AND (STRPOS(dc.Advizor_Phone_Normalized, dc.MarketPro_HQ_Phone_Normalized) > 0 OR STRPOS(dc.MarketPro_HQ_Phone_Normalized, dc.Advizor_Phone_Normalized) > 0))
         OR (dc.MarketPro_Home_Phone_Normalized IS NOT NULL AND dc.MarketPro_Home_Phone_Normalized != '' AND LENGTH(dc.MarketPro_Home_Phone_Normalized) >= 10
          AND (STRPOS(dc.Advizor_Phone_Normalized, dc.MarketPro_Home_Phone_Normalized) > 0 OR STRPOS(dc.MarketPro_Home_Phone_Normalized, dc.Advizor_Phone_Normalized) > 0))
       )
      THEN 'MATCH_CONTAINED'
      
      -- 5. Missing Logic: All 3 Advizor phones AND all 4 MarketPro phones are NULL/Empty
      WHEN (dc.Advizor_Phone_Normalized IS NULL OR dc.Advizor_Phone_Normalized = '')
       AND (dc.Advizor_Firm_Phone_Normalized IS NULL OR dc.Advizor_Firm_Phone_Normalized = '')
       AND (dc.Advizor_Team_Phone_Normalized IS NULL OR dc.Advizor_Team_Phone_Normalized = '')
       AND (dc.Direct_Phone_Normalized IS NULL OR dc.Direct_Phone_Normalized = '')
       AND (dc.Branch_Phone_Normalized IS NULL OR dc.Branch_Phone_Normalized = '')
       AND (dc.MarketPro_HQ_Phone_Normalized IS NULL OR dc.MarketPro_HQ_Phone_Normalized = '')
       AND (dc.MarketPro_Home_Phone_Normalized IS NULL OR dc.MarketPro_Home_Phone_Normalized = '')
      THEN 'MATCH_BOTH_MISSING'
      
      -- Data Gaps
      WHEN (dc.Advizor_Phone_Normalized IS NULL OR dc.Advizor_Phone_Normalized = '')
       AND (dc.Advizor_Firm_Phone_Normalized IS NULL OR dc.Advizor_Firm_Phone_Normalized = '')
       AND (dc.Advizor_Team_Phone_Normalized IS NULL OR dc.Advizor_Team_Phone_Normalized = '')
      THEN 'MISSING_IN_ADVIZOR'
      WHEN (dc.Direct_Phone_Normalized IS NULL OR dc.Direct_Phone_Normalized = '')
       AND (dc.Branch_Phone_Normalized IS NULL OR dc.Branch_Phone_Normalized = '')
       AND (dc.MarketPro_HQ_Phone_Normalized IS NULL OR dc.MarketPro_HQ_Phone_Normalized = '')
       AND (dc.MarketPro_Home_Phone_Normalized IS NULL OR dc.MarketPro_Home_Phone_Normalized = '')
      THEN 'MISSING_IN_MARKETPRO'
      
      ELSE 'MISMATCH' 
    END as phone_match_status,
    
    -- Address matching
    -- NOTE: Location mismatches (City/Zip) are expected and do not invalidate record identity.
    -- One dataset may track Registered Branch Office (corporate hub) while the other tracks
    -- Physical Office or Home Address. CRD match is the authoritative identifier.
    CASE 
      WHEN dc.City_Normalized = dc.Branch_City_Normalized
       AND dc.State_Normalized = dc.Branch_State_Normalized
       AND dc.Zip_Normalized = dc.Branch_ZipCode_Normalized
      THEN 'MATCH' 
      WHEN dc.State_Normalized = dc.Branch_State_Normalized
       AND dc.Zip_Normalized = dc.Branch_ZipCode_Normalized
      THEN 'PARTIAL_MATCH'
      ELSE 'MISMATCH' 
    END as address_match_status,
    
    -- AUM matching with scaling logic and data gap detection
    CASE 
      -- Flag mega-firm AUMs first (likely firm-level assets, not individual advisor)
      -- These represent entire firm assets (e.g., LPL, Morgan Stanley) not individual advisor AUM
      WHEN dc.Firm_AUM > 50000000000 -- 50 Billion in dollars
       AND dc.TotalAssetsInMillions_Numeric > 50000 -- 50,000 Million
      THEN 'FIRM_LEVEL_ASSETS_DETECTED'
      
      -- Handle Missing Data
      WHEN (dc.Firm_AUM IS NULL OR dc.Firm_AUM = 0) AND dc.TotalAssetsInMillions_Numeric > 0
      THEN 'MISSING_IN_ADVIZOR'
      WHEN dc.Firm_AUM > 0 AND (dc.TotalAssetsInMillions_Numeric IS NULL OR dc.TotalAssetsInMillions_Numeric = 0)
      THEN 'MISSING_IN_MARKETPRO'
      
      -- Direct match (both in same units)
      WHEN ABS(dc.Firm_AUM - dc.TotalAssetsInMillions_Numeric) <= 1.0
      THEN 'MATCH' 
      -- Scaled match: AdvizorPro in dollars, MarketPro in millions
      WHEN ABS((dc.Firm_AUM / 1000000.0) - dc.TotalAssetsInMillions_Numeric) <= 1.0
      THEN 'MATCH_SCALED'
      -- Scaled double count: AdvizorPro = MarketPro * 2 * 1,000,000
      WHEN ABS((dc.Firm_AUM / 1000000.0) - (dc.TotalAssetsInMillions_Numeric * 2.0)) <= 1.0
      THEN 'MATCH_SCALED_DOUBLE_COUNT'
      -- Percentage-based close match
      WHEN ABS(dc.Firm_AUM - dc.TotalAssetsInMillions_Numeric) / NULLIF(dc.Firm_AUM, 0) <= 0.05
      THEN 'CLOSE_MATCH'
      ELSE 'MISMATCH' 
    END as aum_match_status,
    
    -- Account matching with double counting logic
    CASE 
      -- Direct match
      WHEN dc.Firm_Total_Accounts = dc.TotalAccounts_Numeric
      THEN 'MATCH'
      -- Double count match: AdvizorPro = MarketPro * 2 (BD + RIA sides)
      WHEN dc.Firm_Total_Accounts = (dc.TotalAccounts_Numeric * 2)
      THEN 'MATCH_DOUBLE_COUNT'
      -- Close match (within 5 accounts)
      WHEN ABS(dc.Firm_Total_Accounts - dc.TotalAccounts_Numeric) <= 5
      THEN 'CLOSE_MATCH'
      ELSE 'MISMATCH' 
    END as accounts_match_status
    
  FROM data_cleaning dc
  -- Left join nickname map for Advizor first name
  LEFT JOIN nickname_map nm_adv
    ON nm_adv.nickname = dc.First_Name_Clean
  -- Left join nickname map for MarketPro first name
  LEFT JOIN nickname_map nm_mkt
    ON nm_mkt.nickname = dc.FirstName_Clean
),
final_output AS (
  -- Step 3: Select all fields and calculate match_confidence based on status columns
  SELECT 
    CRD,
    -- Name fields
    First_Name_Normalized as advizor_first_name,
    FirstName as marketpro_first_name,
    Last_Name_Normalized as advizor_last_name,
    LastName as marketpro_last_name,
    name_match_status,
    -- RIA fields
    RIA_Normalized as advizor_ria,
    RIAFirmName as marketpro_ria,
    RIA_CRD_Int as advizor_ria_crd,
    RIAFirmCRD as marketpro_ria_crd,
    ria_match_status,
    -- BD fields
    Broker_Dealer_Normalized as advizor_bd,
    BDNameCurrent as marketpro_bd,
    Broker_Dealer_CRD_Int as advizor_bd_crd,
    PrimaryBDFirmCRD as marketpro_bd_crd,
    bd_match_status,
    -- Email fields
    Email_1_Normalized as advizor_email,
    Email_BusinessType_Normalized as marketpro_email,
    email_match_status,
    -- Phone fields
    Advizor_Phone_Normalized as advizor_phone,
    Advizor_Firm_Phone_Normalized as advizor_firm_phone,
    Advizor_Team_Phone_Normalized as advizor_team_phone,
    Direct_Phone_Normalized as marketpro_direct_phone,
    Branch_Phone_Normalized as marketpro_branch_phone,
    MarketPro_HQ_Phone_Normalized as marketpro_hq_phone,
    MarketPro_Home_Phone_Normalized as marketpro_home_phone,
    phone_match_status,
    -- Address fields
    City_Normalized as advizor_city,
    Branch_City_Normalized as marketpro_city,
    State_Normalized as advizor_state,
    Branch_State_Normalized as marketpro_state,
    Zip_Normalized as advizor_zip,
    Branch_ZipCode_Normalized as marketpro_zip,
    address_match_status,
    -- AUM fields
    Firm_AUM as advizor_aum,
    TotalAssetsInMillions_Numeric as marketpro_aum,
    aum_match_status,
    -- Account fields
    Firm_Total_Accounts as advizor_accounts,
    TotalAccounts_Numeric as marketpro_accounts,
    accounts_match_status,
    -- Match confidence based on status columns
    -- HIGH_CONFIDENCE: CRD Match AND Name matches AND (RIA/BD/Phone/Email is valid match)
    -- MEDIUM_CONFIDENCE: Name matches (including NICKNAME, INITIAL, FUZZY, TYPO, NICKNAME_FUZZY) OR Cross-reference phone match OR Firm fuzzy match
    -- LOW_CONFIDENCE: Everything else
    CASE 
      -- HIGH_CONFIDENCE: 
      -- CRD Match (implicit - we're joining on CRD)
      -- AND Name matches (Exact, Cleaned, Contained, Initial, Nickname, Typo, or Nickname_Fuzzy)
      -- AND (RIA is valid match OR BD is valid match OR Phone is PRIMARY/SECONDARY match OR Email is valid match)
      -- Note: 'MATCH_BOTH_MISSING' is neutral - doesn't drag score down but isn't enough alone
      WHEN name_match_status IN ('MATCH', 'MATCH_CLEANED', 'MATCH_CONTAINED', 'MATCH_INITIAL', 'MATCH_NICKNAME', 'MATCH_TYPO', 'MATCH_NICKNAME_FUZZY')
       AND (
         ria_match_status LIKE 'MATCH%' AND ria_match_status != 'MATCH_BOTH_MISSING'
         OR bd_match_status LIKE 'MATCH%' AND bd_match_status != 'MATCH_BOTH_MISSING'
         OR phone_match_status IN ('MATCH_PRIMARY', 'MATCH_SECONDARY')
         OR email_match_status LIKE 'MATCH%' AND email_match_status != 'MATCH_BOTH_MISSING'
       )
      THEN 'HIGH_CONFIDENCE'
      -- MEDIUM_CONFIDENCE: Name matches (including NICKNAME, INITIAL, FUZZY, TYPO, NICKNAME_FUZZY) OR Cross-reference phone match OR Firm fuzzy match
      WHEN name_match_status IN ('MATCH', 'MATCH_CLEANED', 'MATCH_CONTAINED', 'MATCH_INITIAL', 'MATCH_FUZZY', 'MATCH_NICKNAME', 'MATCH_TYPO', 'MATCH_NICKNAME_FUZZY')
       OR phone_match_status = 'MATCH_CROSS_REF'
       OR ria_match_status = 'MATCH_FIRM_FUZZY'
       OR bd_match_status = 'MATCH_FIRM_FUZZY'
      THEN 'MEDIUM_CONFIDENCE'
      -- LOW_CONFIDENCE: Everything else
      ELSE 'LOW_CONFIDENCE'
    END as match_confidence,
    
    -- Insight flag: Identify potential business events (e.g., firm changes)
    CASE 
      -- Potential Firm Change: High confidence name match but RIA mismatch
      WHEN name_match_status IN ('MATCH', 'MATCH_CLEANED', 'MATCH_TYPO', 'MATCH_NICKNAME_FUZZY')
       AND ria_match_status = 'MISMATCH'
      THEN 'POTENTIAL_FIRM_CHANGE'
      ELSE 'N/A'
    END as insight_flag,
    source_table
  FROM match_calculations
)
SELECT *
FROM final_output
ORDER BY CRD, marketpro_ria_crd
