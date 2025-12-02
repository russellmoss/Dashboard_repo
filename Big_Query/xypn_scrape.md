Here is a comprehensive documentation of the workflow we executed to scrape, store, and enrich the XY Planning Network advisor data. You can save this directly as a `.md` file in VS Code.

-----

# Workflow Documentation: XY Planning Network Data Acquisition & Enrichment

**Date:** November 2025
**Project:** Advisor Data Enrichment
**Source:** [XY Planning Network - Find an Advisor](https://connect.xyplanningnetwork.com/find-an-advisor)

-----

## 1\. Overview

This project involved a three-step process to acquire and enhance advisor data:

1.  **Extraction:** Reverse-engineering the XYPN internal API to scrape structured advisor data (Name, Firm, Accreditations, Location) using a browser-based JavaScript automation.
2.  **Storage:** Loading the raw CSV data into Google BigQuery.
3.  **Enrichment:** Using complex SQL fuzzy matching logic to merge the scraped data with our internal `Market Pro Discovery` datasets (t1, t2, t3) to append contact info, AUM, and CRD numbers.

-----

## 2\. Data Extraction (Scraping)

We initially attempted to scrape the HTML directly but found that the pagination was controlled by JavaScript. We discovered a direct JSON API endpoint used by the frontend: `https://connect.xyplanningnetwork.com/api/v1/find-an-advisor`.

### Challenges & Solutions

  * **Pagination:** The API required iteration through pages using the `page` parameter.
  * **Hidden Data:** The firm name was not in the top-level object but nested within the API response. We used a "universal finder" script to identify the correct key (`advisor.firmName`).
  * **Format:** The API structure was `json.data.items` rather than a direct array.

### The Scraper Script

Run the following code in the **Browser Console (F12)** on the XYPN website.

```javascript
async function scrapeFinal() {
    let allAdvisors = [];
    let page = 1;
    const perPage = 50; 
    let hasMore = true;

    console.log("🚀 Starting Final Scraper...");

    while (hasMore) {
        console.log(`📄 Fetching page ${page}...`);
        
        try {
            // Fetch data from the internal API
            const response = await fetch(`https://connect.xyplanningnetwork.com/api/v1/find-an-advisor?page=${page}&perPage=${perPage}`);
            const json = await response.json();
            
            // Locate the array of advisors
            let advisors = json.data.items;

            if (!advisors || advisors.length === 0) {
                console.log("✅ Reached end of list.");
                hasMore = false;
                break;
            }

            advisors.forEach(advisor => {
                // Extract and normalize relevant fields
                let cleanData = {
                    "Name": advisor.name || (advisor.firstName + ' ' + advisor.lastName),
                    "Firm": advisor.firmName || advisor.company || "N/A", 
                    "Accreditations": Array.isArray(advisor.designations) ? advisor.designations.join(", ") : (advisor.designations || "N/A"),
                    "City": advisor.city || (advisor.address ? advisor.address.city : "N/A"),
                    "State": advisor.state || (advisor.address ? advisor.address.state : "N/A"),
                    "Website": advisor.website || "N/A",
                    "Profile_URL": "https://connect.xyplanningnetwork.com/find-an-advisor/" + (advisor.slug || "")
                };
                allAdvisors.push(cleanData);
            });

            // Polite delay to prevent rate limiting
            await new Promise(r => setTimeout(r, 400));
            page++;

        } catch (error) {
            console.error("❌ Error on page " + page, error);
            hasMore = false;
        }
    }

    console.log(`🎉 Scraped ${allAdvisors.length} advisors!`);
    
    // Trigger CSV Download
    downloadCSV(allAdvisors);
    
    // Backup: Copy to Clipboard
    copyToClipboard(allAdvisors);
}

// Helper: Convert JSON to CSV and trigger download
function downloadCSV(data) {
    if (!data || data.length === 0) return;
    const headers = Object.keys(data[0]);
    const csvRows = [headers.join(',')];
    for (const row of data) {
        const values = headers.map(header => {
            const val = row[header] || "";
            const escaped = ('' + val).replace(/"/g, '\\"');
            return `"${escaped}"`;
        });
        csvRows.push(values.join(','));
    }
    const blob = new Blob([csvRows.join('\n')], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.setAttribute('hidden', '');
    a.setAttribute('href', url);
    a.setAttribute('download', 'xy_advisors_final.csv');
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

// Helper: Format data for Excel paste
function copyToClipboard(data) {
    const headers = Object.keys(data[0]);
    const csvRows = [headers.join('\t')]; 
    for (const row of data) {
        const values = headers.map(header => {
            let val = row[header] || "";
            return val.toString().replace(/\t/g, " ").replace(/\n/g, " ");
        });
        csvRows.push(values.join('\t'));
    }
    const textString = csvRows.join('\n');
    
    const el = document.createElement('textarea');
    el.value = textString;
    document.body.appendChild(el);
    el.select();
    document.execCommand('copy');
    document.body.removeChild(el);
    console.log("📋 Data also copied to clipboard!");
}

scrapeFinal();
```

-----

## 3\. Data Ingestion (BigQuery)

The resulting CSV file was uploaded to BigQuery. We created a view to cast the raw string fields into structured columns for easier querying.

### View Definition

**Source Table:** `savvy-gtm-analytics.SavvyGTMData.XYPN`

```sql
SELECT 
  string_field_0 AS Name,
  string_field_1 AS Firm,
  string_field_2 AS Accreditations,
  string_field_3 AS Profile_URL
FROM `savvy-gtm-analytics.SavvyGTMData.XYPN`
```

-----

## 4\. Data Enrichment (Fuzzy Matching)

We enriched the scraped XYPN data by matching it against our internal `Market Pro Discovery` database (tables `t1`, `t2`, `t3`).

### Enrichment Strategy

Since names and firm names often vary slightly between sources (e.g., "Bill Smith" vs. "William Smith", or "Livelihood LLC" vs. "Livelihood Financial"), we implemented a robust **SQL Fuzzy Matching Algorithm**.

**Key Logic Features:**

1.  **Normalization:** Cleaning names (removing "Mr.", "CFP", "PhD", etc.) and Firms (removing "LLC", "Inc", "Advisors").
2.  **Nickname Mapping:** Automatic mapping of 30+ common nicknames (Bill -\> William, Bob -\> Robert).
3.  **Fuzzy Algorithms:**
      * `SOUNDEX`: Matches names that sound alike.
      * `EDIT_DISTANCE`: Allows for small typos (1-2 character differences).
      * `STARTS_WITH`: Matches substring variations.
4.  **Ranking:** Matches are ranked by confidence (Exact \> Nickname \> Soundex \> Fuzzy), selecting only the single best match per advisor.

### Enrichment Query

```sql
/*
 * XYPN Advisors Enrichment Query
 * Matches XYPN data against discovery tables (t1, t2, t3)
 */

WITH nickname_map AS (
  -- Common nickname to formal name mappings (e.g., BILL -> WILLIAM)
  SELECT 'BILL' as nickname, 'WILLIAM' as formal_name
  UNION ALL SELECT 'BOB', 'ROBERT'
  UNION ALL SELECT 'JIM', 'JAMES'
  UNION ALL SELECT 'CHRIS', 'CHRISTOPHER'
  UNION ALL SELECT 'MIKE', 'MICHAEL'
  -- ... (See full list in query execution) ...
  UNION ALL SELECT 'TIM', 'TIMOTHY'
  UNION ALL SELECT 'VINCE', 'VINCENT'
),
xypn_normalized AS (
  -- Parse and normalize scraped XYPN data
  SELECT 
    Name,
    Firm,
    Accreditations,
    Profile_URL,
    -- Extract First/Last
    TRIM(SPLIT(Name, ' ')[OFFSET(0)]) as First_Name_Raw,
    TRIM(ARRAY_TO_STRING((SELECT ARRAY_AGG(TRIM(part)) FROM UNNEST(SPLIT(Name, ' ')) AS part WITH OFFSET AS offset WHERE part != '' AND offset > 0), ' ')) as Last_Name_Raw,
    -- Clean First Name
    UPPER(TRIM(SPLIT(Name, ' ')[OFFSET(0)])) as First_Name_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(SPLIT(Name, ' ')[OFFSET(0)])), r'[^A-Z]', '') as First_Name_Clean,
    -- Clean Last Name (remove credentials/suffixes)
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        UPPER(TRIM(ARRAY_TO_STRING((SELECT ARRAY_AGG(TRIM(part)) FROM UNNEST(SPLIT(Name, ' ')) AS part WITH OFFSET AS offset WHERE part != '' AND offset > 0), ' '))),
        r' (JR\.?|SR\.?|I{2,3}|IV|MBA|CFP®?|CHFC®?|RICP®?|CPA|EA|AFC®?|RLP®?|APMA®?|CFA|PHD|MSFP|CRPC®?|FBS®?|CSLP®?|CDFA®?|CIMA®?|TPCP®?|PFS|MR\.?|MS\.?)$', ''
      ),
      r'[^A-Z]', ''
    ) as Last_Name_Clean,
    -- Normalize Firm Name
    UPPER(TRIM(Firm)) as Firm_Normalized,
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(UPPER(TRIM(Firm)), r' LLC\.?$', ''),
        r' (WEALTH|FINANCIAL|ADVISORS|MANAGEMENT|GROUP|PARTNERS|INC|CORP|LTD)\.?$', ''
      ), 
      r'[^A-Z0-9]', ''
    ) as Firm_Clean
  FROM `savvy-gtm-analytics.SavvyGTMData.XYPN_view`
  WHERE Name IS NOT NULL AND Name != ''
),
discovery_unified AS (
  -- Combine all discovery tables (t1, t2, t3) and normalize fields
  SELECT 
    RepCRD, FullName, FirstName, LastName, RIAFirmName, RIAFirmCRD,
    -- Normalize Names
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|CFP|MR\.?|CPA)$', ''), r'[^A-Z]', '') as LastName_Clean,
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    -- Normalize Firms
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
    REGEXP_REPLACE(
      REGEXP_REPLACE(UPPER(TRIM(RIAFirmName)), r' (LLC|INC|CORP|LTD|ADVISORS|MANAGEMENT|GROUP|PARTNERS|WEALTH|FINANCIAL)\.?$', ''), 
      r'[^A-Z0-9]', ''
    ) as RIAFirmName_Clean,
    -- Contact Data
    DirectDial_Phone, Branch_Phone, HQ_Phone, Home_Phone,
    Email_BusinessType, Email_Business2Type, Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor, Title,
    't1' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t1`
  WHERE FullName IS NOT NULL
  
  UNION ALL
  -- ... (Repeat SELECT for t2 and t3) ...
  SELECT 
    RepCRD, FullName, FirstName, LastName, RIAFirmName, RIAFirmCRD,
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|CFP|MR\.?|CPA)$', ''), r'[^A-Z]', '') as LastName_Clean,
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(RIAFirmName)), r' (LLC|INC|CORP|LTD|ADVISORS|MANAGEMENT|GROUP|PARTNERS|WEALTH|FINANCIAL)\.?$', ''), r'[^A-Z0-9]', '') as RIAFirmName_Clean,
    DirectDial_Phone, Branch_Phone, HQ_Phone, Home_Phone,
    Email_BusinessType, Email_Business2Type, Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor, Title,
    't2' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t2`
  WHERE FullName IS NOT NULL

  UNION ALL 
  -- Select for t3...
   SELECT 
    RepCRD, FullName, FirstName, LastName, RIAFirmName, RIAFirmCRD,
    REGEXP_REPLACE(UPPER(TRIM(FirstName)), r'[^A-Z]', '') as FirstName_Clean,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(LastName)), r' (JR\.?|SR\.?|CFP|MR\.?|CPA)$', ''), r'[^A-Z]', '') as LastName_Clean,
    UPPER(TRIM(FullName)) as FullName_Normalized,
    REGEXP_REPLACE(UPPER(TRIM(FullName)), r'[^A-Z ]', '') as FullName_Clean,
    UPPER(TRIM(RIAFirmName)) as RIAFirmName_Normalized,
    REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(RIAFirmName)), r' (LLC|INC|CORP|LTD|ADVISORS|MANAGEMENT|GROUP|PARTNERS|WEALTH|FINANCIAL)\.?$', ''), r'[^A-Z0-9]', '') as RIAFirmName_Clean,
    DirectDial_Phone, Branch_Phone, HQ_Phone, Home_Phone,
    Email_BusinessType, Email_Business2Type, Email_PersonalType,
    SocialMedia_LinkedIn,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    KnownNonAdvisor, Title,
    't3' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
  WHERE FullName IS NOT NULL
),
match_candidates AS (
  SELECT 
    x.*, d.*,
    CASE 
      WHEN x.First_Name_Clean = d.FirstName_Clean AND x.Last_Name_Clean = d.LastName_Clean THEN 'MATCH_EXACT'
      WHEN STRPOS(d.FullName_Clean, x.First_Name_Clean || ' ' || x.Last_Name_Clean) > 0 THEN 'MATCH_FULLNAME'
      WHEN x.Last_Name_Clean = d.LastName_Clean AND ((nm_x.formal_name = d.FirstName_Clean) OR (nm_d.formal_name = x.First_Name_Clean)) THEN 'MATCH_NICKNAME'
      WHEN x.Last_Name_Clean = d.LastName_Clean AND SUBSTR(x.First_Name_Clean, 1, 1) = SUBSTR(d.FirstName_Clean, 1, 1) THEN 'MATCH_INITIAL'
      WHEN SOUNDEX(x.First_Name_Normalized) = SOUNDEX(d.FirstName) AND SOUNDEX(x.Last_Name_Clean) = SOUNDEX(d.LastName) THEN 'MATCH_SOUNDEX'
      WHEN x.First_Name_Clean = d.FirstName_Clean AND EDIT_DISTANCE(x.Last_Name_Clean, d.LastName_Clean) <= 2 THEN 'MATCH_TYPO'
      ELSE 'NO_MATCH'
    END as name_match_type,
    CASE
      WHEN x.Firm_Normalized = d.RIAFirmName_Normalized THEN 'MATCH_EXACT'
      WHEN x.Firm_Clean = d.RIAFirmName_Clean AND x.Firm_Clean != '' THEN 'MATCH_CLEANED'
      ELSE 'NO_MATCH'
    END as firm_match_type
  FROM xypn_normalized x
  CROSS JOIN discovery_unified d
  LEFT JOIN nickname_map nm_x ON nm_x.nickname = x.First_Name_Clean
  LEFT JOIN nickname_map nm_d ON nm_d.nickname = d.FirstName_Clean
  WHERE 
    -- Optimization: Pre-filter to reduce cross join size
    ((LENGTH(x.Last_Name_Clean) > 0 AND SUBSTR(x.Last_Name_Clean, 1, 1) = SUBSTR(d.LastName_Clean, 1, 1))
    OR (LENGTH(x.Firm_Clean) > 0 AND SUBSTR(x.Firm_Clean, 1, 1) = SUBSTR(d.RIAFirmName_Clean, 1, 1)))
),
ranked_matches AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY Name, Firm, Profile_URL
      ORDER BY 
        CASE name_match_type WHEN 'MATCH_EXACT' THEN 1 WHEN 'MATCH_FULLNAME' THEN 2 WHEN 'MATCH_NICKNAME' THEN 3 ELSE 99 END,
        CASE firm_match_type WHEN 'MATCH_EXACT' THEN 1 WHEN 'MATCH_CLEANED' THEN 2 ELSE 99 END
    ) as match_rank
  FROM match_candidates
  WHERE name_match_type != 'NO_MATCH' OR firm_match_type != 'NO_MATCH'
)
SELECT 
  x.Name, x.Firm, x.Accreditations, x.Profile_URL,
  r.RepCRD, r.FullName as Discovery_FullName,
  r.DirectDial_Phone, r.Email_BusinessType, r.SocialMedia_LinkedIn,
  r.TotalAssetsInMillions_Numeric as AUM_Millions
FROM xypn_normalized x
LEFT JOIN ranked_matches r ON x.Name = r.Name AND x.Firm = r.Firm AND r.match_rank = 1
ORDER BY x.Name;
```