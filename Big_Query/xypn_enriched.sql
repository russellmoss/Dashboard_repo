/*
 * XYPN Advisors Enrichment Query
 * 
 * This query enriches XYPN advisors with data from discovery tables (t1, t2, t3)
 * using fuzzy matching on names and firm names.
 * 
 * Matching Strategy:
 * - Parses Name field (first + last) from XYPN_view
 * - Matches against FullName from discovery tables
 * - Also matches Firm against RIAFirmName
 * - Uses nickname mapping, normalization, and fuzzy matching techniques
 * 
 * Enrichment Fields:
 * - Phone numbers (Direct, Branch, HQ, Home)
 * - Emails (Business, Business2, Personal)
 * - LinkedIn URL
 * - AUM (TotalAssetsInMillions)
 * - Is Known Advisor (KnownNonAdvisor)
 * - Title
 * 
 * Performance Note:
 * This query uses a cross join with pre-filtering (first letter matching) to reduce
 * the search space. For large datasets, consider running during off-peak hours.
 * The query returns the best match per XYPN advisor based on match confidence ranking.
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
xypn_normalized AS (
  -- Parse and normalize XYPN data
  SELECT 
    Name,
    Firm,
    Accreditations,
    Profile_URL,
    -- Parse first and last name from Name field
    TRIM(SPLIT(Name, ' ')[OFFSET(0)]) as First_Name_Raw,
    TRIM(ARRAY_TO_STRING((SELECT ARRAY_AGG(TRIM(part)) FROM UNNEST(SPLIT(Name, ' ')) AS part WITH OFFSET AS offset WHERE part != '' AND offset > 0), ' ')) as Last_Name_Raw,
    -- Normalize first name
    UPPER(TRIM(SPLIT(Name, ' ')[OFFSET(0)])) as First_Name_Normalized,
    -- Normalize last name (remove accreditations and suffixes)
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        UPPER(TRIM(ARRAY_TO_STRING((SELECT ARRAY_AGG(TRIM(part)) FROM UNNEST(SPLIT(Name, ' ')) AS part WITH OFFSET AS offset WHERE part != '' AND offset > 0), ' '))),
        r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP®?|CHFC®?|RICP®?|CPA|EA|AFC®?|RLP®?|APMA®?|CFA|PHD|MSFP|CRPC®?|FBS®?|CSLP®?|CDFA®?|CIMA®?|TPCP®?|PFS|MR\.?|MS\.?)$', ''
      ),
      r'[^A-Z]', ''
    ) as Last_Name_Clean,
    REGEXP_REPLACE(UPPER(TRIM(SPLIT(Name, ' ')[OFFSET(0)])), r'[^A-Z]', '') as First_Name_Clean,
    -- Normalize firm name
    UPPER(TRIM(Firm)) as Firm_Normalized,
    -- Firm name normalization: strip common suffixes
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(UPPER(TRIM(Firm)), r' LLC\.?$', ''),
                    r' INC\.?$', ''
                  ), r' CORP\.?$', ''
                ), r' LTD\.?$', ''
              ), r' ADVISORS?\.?$', ''
            ), r' MANAGEMENT\.?$', ''
          ), r' GROUP\.?$', ''
        ), r' PARTNERS?\.?$', ''
      ), r' (WEALTH|FINANCIAL)\.?$', ''
    ) as Firm_Clean
  FROM `savvy-gtm-analytics.SavvyGTMData.XYPN_view`
  WHERE Name IS NOT NULL AND Name != ''
),
discovery_unified AS (
  -- Combine all discovery tables (t1, t2, t3)
  SELECT 
    RepCRD,
    FullName,
    FirstName,
    LastName,
    RIAFirmName,
    RIAFirmCRD,
    -- Normalize first name
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    -- Normalize last name (remove suffixes)
    REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
      r'[^A-Z]', ''
    ) as LastName_Clean,
    -- Normalize FullName for matching
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    -- Firm name normalization
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
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
    -- Enrichment fields
    DirectDial_Phone,
    Branch_Phone,
    HQ_Phone,
    Home_Phone,
    Email_BusinessType,
    Email_Business2Type,
    Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor,
    Title,
    't1' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t1`
  WHERE FullName IS NOT NULL AND FullName != ''
  
  UNION ALL
  
  SELECT 
    RepCRD,
    FullName,
    FirstName,
    LastName,
    RIAFirmName,
    RIAFirmCRD,
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
      r'[^A-Z]', ''
    ) as LastName_Clean,
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
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
    DirectDial_Phone,
    Branch_Phone,
    HQ_Phone,
    Home_Phone,
    Email_BusinessType,
    Email_Business2Type,
    Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor,
    Title,
    't2' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t2`
  WHERE FullName IS NOT NULL AND FullName != ''
  
  UNION ALL
  
  SELECT 
    RepCRD,
    FullName,
    FirstName,
    LastName,
    RIAFirmName,
    RIAFirmCRD,
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP|MR\.?|MS\.?|PHD|CPA)$', ''),
      r'[^A-Z]', ''
    ) as LastName_Clean,
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
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
    DirectDial_Phone,
    Branch_Phone,
    HQ_Phone,
    Home_Phone,
    Email_BusinessType,
    Email_Business2Type,
    Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor,
    Title,
    't3' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
  WHERE FullName IS NOT NULL AND FullName != ''
),
match_candidates AS (
  -- Find potential matches using fuzzy logic
  -- Pre-filter to reduce search space: match on last name first letter or firm first letter
  SELECT 
    x.*,
    d.*,
    -- Name matching logic
    CASE 
      -- Exact match on cleaned names
      WHEN x.First_Name_Clean = d.FirstName_Clean
       AND x.Last_Name_Clean = d.LastName_Clean
      THEN 'MATCH_EXACT'
      
      -- FullName contains or is contained by XYPN name (match against normalized FullName)
      WHEN STRPOS(d.FullName_Clean, x.First_Name_Clean || ' ' || x.Last_Name_Clean) > 0
       OR STRPOS(d.FullName_Clean, x.Last_Name_Clean || ' ' || x.First_Name_Clean) > 0
       OR STRPOS(x.First_Name_Clean || ' ' || x.Last_Name_Clean, d.FullName_Clean) > 0
      THEN 'MATCH_FULLNAME'
      
      -- Last name matches and first name matches with nickname
      WHEN x.Last_Name_Clean = d.LastName_Clean
       AND x.Last_Name_Clean != ''
       AND (
         (nm_x.formal_name IS NOT NULL AND nm_x.formal_name = d.FirstName_Clean)
         OR (nm_d.formal_name IS NOT NULL AND nm_d.formal_name = x.First_Name_Clean)
       )
      THEN 'MATCH_NICKNAME'
      
      -- Last name matches and first initial matches
      WHEN x.Last_Name_Clean = d.LastName_Clean
       AND x.Last_Name_Clean != ''
       AND SUBSTR(x.First_Name_Clean, 1, 1) = SUBSTR(d.FirstName_Clean, 1, 1)
       AND LENGTH(x.First_Name_Clean) > 0
       AND LENGTH(d.FirstName_Clean) > 0
      THEN 'MATCH_INITIAL'
      
      -- Soundex match
      WHEN SOUNDEX(x.First_Name_Normalized) = SOUNDEX(d.FirstName)
       AND SOUNDEX(x.Last_Name_Clean) = SOUNDEX(d.LastName)
      THEN 'MATCH_SOUNDEX'
      
      -- Edit distance match (typo tolerance)
      WHEN x.First_Name_Clean = d.FirstName_Clean
       AND x.Last_Name_Clean != '' 
       AND d.LastName_Clean != ''
       AND (
         (LENGTH(x.Last_Name_Clean) > 3 AND EDIT_DISTANCE(x.Last_Name_Clean, d.LastName_Clean) <= 2)
         OR (LENGTH(x.Last_Name_Clean) <= 3 AND EDIT_DISTANCE(x.Last_Name_Clean, d.LastName_Clean) <= 1)
       )
      THEN 'MATCH_TYPO'
      
      -- First 3 character match for unusual names
      WHEN x.Last_Name_Clean = d.LastName_Clean
       AND x.Last_Name_Clean != ''
       AND d.LastName_Clean != ''
       AND (
         STARTS_WITH(x.First_Name_Clean, d.FirstName_Clean)
         OR STARTS_WITH(d.FirstName_Clean, x.First_Name_Clean)
         OR (LENGTH(x.First_Name_Clean) >= 3 AND LENGTH(d.FirstName_Clean) >= 3 
             AND SUBSTR(x.First_Name_Clean, 1, 3) = SUBSTR(d.FirstName_Clean, 1, 3))
       )
      THEN 'MATCH_FUZZY'
      
      ELSE 'NO_MATCH'
    END as name_match_type,
    
    -- Firm matching logic
    CASE
      -- Exact match
      WHEN x.Firm_Normalized = d.RIAFirmName_Normalized
      THEN 'MATCH_EXACT'
      
      -- Cleaned firm names match
      WHEN x.Firm_Clean = d.RIAFirmName_Clean
       AND x.Firm_Clean != ''
       AND d.RIAFirmName_Clean != ''
      THEN 'MATCH_CLEANED'
      
      -- Substring match
      WHEN STRPOS(x.Firm_Normalized, d.RIAFirmName_Normalized) > 0
       OR STRPOS(d.RIAFirmName_Normalized, x.Firm_Normalized) > 0
      THEN 'MATCH_SUBSTRING'
      
      ELSE 'NO_MATCH'
    END as firm_match_type
    
  FROM xypn_normalized x
  CROSS JOIN discovery_unified d
  -- Left join nickname maps
  LEFT JOIN nickname_map nm_x
    ON nm_x.nickname = x.First_Name_Clean
  LEFT JOIN nickname_map nm_d
    ON nm_d.nickname = d.FirstName_Clean
  WHERE 
    -- Pre-filter: last name first letter matches OR firm first letter matches
    -- This significantly reduces the cross join size
    (
      (LENGTH(x.Last_Name_Clean) > 0 AND LENGTH(d.LastName_Clean) > 0 
       AND SUBSTR(x.Last_Name_Clean, 1, 1) = SUBSTR(d.LastName_Clean, 1, 1))
      OR
      (LENGTH(x.Firm_Clean) > 0 AND LENGTH(d.RIAFirmName_Clean) > 0
       AND SUBSTR(x.Firm_Clean, 1, 1) = SUBSTR(d.RIAFirmName_Clean, 1, 1))
    )
    AND
    -- At least one match type must be valid
    (
      -- Name matches (any type except NO_MATCH)
      (CASE 
        WHEN x.First_Name_Clean = d.FirstName_Clean
         AND x.Last_Name_Clean = d.LastName_Clean
        THEN 'MATCH_EXACT'
        WHEN STRPOS(d.FullName_Clean, x.First_Name_Clean || ' ' || x.Last_Name_Clean) > 0
         OR STRPOS(d.FullName_Clean, x.Last_Name_Clean || ' ' || x.First_Name_Clean) > 0
         OR STRPOS(x.First_Name_Clean || ' ' || x.Last_Name_Clean, d.FullName_Clean) > 0
        THEN 'MATCH_FULLNAME'
        WHEN x.Last_Name_Clean = d.LastName_Clean
         AND x.Last_Name_Clean != ''
         AND (
           (nm_x.formal_name IS NOT NULL AND nm_x.formal_name = d.FirstName_Clean)
           OR (nm_d.formal_name IS NOT NULL AND nm_d.formal_name = x.First_Name_Clean)
         )
        THEN 'MATCH_NICKNAME'
        WHEN x.Last_Name_Clean = d.LastName_Clean
         AND x.Last_Name_Clean != ''
         AND SUBSTR(x.First_Name_Clean, 1, 1) = SUBSTR(d.FirstName_Clean, 1, 1)
         AND LENGTH(x.First_Name_Clean) > 0
         AND LENGTH(d.FirstName_Clean) > 0
        THEN 'MATCH_INITIAL'
        WHEN SOUNDEX(x.First_Name_Normalized) = SOUNDEX(d.FirstName)
         AND SOUNDEX(x.Last_Name_Clean) = SOUNDEX(d.LastName)
        THEN 'MATCH_SOUNDEX'
        WHEN x.First_Name_Clean = d.FirstName_Clean
         AND x.Last_Name_Clean != '' 
         AND d.LastName_Clean != ''
         AND (
           (LENGTH(x.Last_Name_Clean) > 3 AND EDIT_DISTANCE(x.Last_Name_Clean, d.LastName_Clean) <= 2)
           OR (LENGTH(x.Last_Name_Clean) <= 3 AND EDIT_DISTANCE(x.Last_Name_Clean, d.LastName_Clean) <= 1)
         )
        THEN 'MATCH_TYPO'
        WHEN x.Last_Name_Clean = d.LastName_Clean
         AND x.Last_Name_Clean != ''
         AND d.LastName_Clean != ''
         AND (
           STARTS_WITH(x.First_Name_Clean, d.FirstName_Clean)
           OR STARTS_WITH(d.FirstName_Clean, x.First_Name_Clean)
           OR (LENGTH(x.First_Name_Clean) >= 3 AND LENGTH(d.FirstName_Clean) >= 3 
               AND SUBSTR(x.First_Name_Clean, 1, 3) = SUBSTR(d.FirstName_Clean, 1, 3))
         )
        THEN 'MATCH_FUZZY'
        ELSE 'NO_MATCH'
      END) != 'NO_MATCH'
      OR
      -- Firm matches (any type except NO_MATCH)
      (CASE
        WHEN x.Firm_Normalized = d.RIAFirmName_Normalized
        THEN 'MATCH_EXACT'
        WHEN x.Firm_Clean = d.RIAFirmName_Clean
         AND x.Firm_Clean != ''
         AND d.RIAFirmName_Clean != ''
        THEN 'MATCH_CLEANED'
        WHEN STRPOS(x.Firm_Normalized, d.RIAFirmName_Normalized) > 0
         OR STRPOS(d.RIAFirmName_Normalized, x.Firm_Normalized) > 0
        THEN 'MATCH_SUBSTRING'
        ELSE 'NO_MATCH'
      END) != 'NO_MATCH'
    )
),
ranked_matches AS (
  -- Rank matches by confidence (exact matches first, then fuzzy)
  SELECT 
    *,
    ROW_NUMBER() OVER (
      PARTITION BY Name, Firm, Profile_URL
      ORDER BY 
        CASE name_match_type
          WHEN 'MATCH_EXACT' THEN 1
          WHEN 'MATCH_FULLNAME' THEN 2
          WHEN 'MATCH_NICKNAME' THEN 3
          WHEN 'MATCH_INITIAL' THEN 4
          WHEN 'MATCH_SOUNDEX' THEN 5
          WHEN 'MATCH_TYPO' THEN 6
          WHEN 'MATCH_FUZZY' THEN 7
          ELSE 99
        END,
        CASE firm_match_type
          WHEN 'MATCH_EXACT' THEN 1
          WHEN 'MATCH_CLEANED' THEN 2
          WHEN 'MATCH_SUBSTRING' THEN 3
          ELSE 99
        END
    ) as match_rank
  FROM match_candidates
  WHERE name_match_type != 'NO_MATCH' OR firm_match_type != 'NO_MATCH'
)
SELECT 
  -- XYPN original fields
  x.Name,
  x.Firm,
  x.Accreditations,
  x.Profile_URL,
  
  -- Match information
  r.name_match_type,
  r.firm_match_type,
  r.match_rank,
  r.source_table,
  
  -- Discovery data (enrichment)
  r.RepCRD,
  r.FullName as Discovery_FullName,
  r.FirstName as Discovery_FirstName,
  r.LastName as Discovery_LastName,
  r.RIAFirmName as Discovery_RIAFirmName,
  r.RIAFirmCRD as Discovery_RIAFirmCRD,
  
  -- Phone numbers
  r.DirectDial_Phone,
  r.Branch_Phone,
  r.HQ_Phone,
  r.Home_Phone,
  
  -- Emails
  r.Email_BusinessType,
  r.Email_Business2Type,
  r.Email_PersonalType,
  
  -- LinkedIn
  r.SocialMedia_LinkedIn as LinkedIn,
  
  -- AUM
  r.TotalAssetsInMillions_Numeric as AUM_Millions,
  
  -- Is Known Advisor
  r.KnownNonAdvisor as Is_Known_Advisor,
  
  -- Title
  r.Title
  
FROM xypn_normalized x
LEFT JOIN ranked_matches r
  ON x.Name = r.Name
  AND x.Firm = r.Firm
  AND x.Profile_URL = r.Profile_URL
  AND r.match_rank = 1  -- Only best match per XYPN advisor
ORDER BY x.Name, x.Firm

