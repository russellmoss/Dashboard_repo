# AdvizorPro and MarketPro Discovery Data Comparison Plan

## Executive Summary

This document provides a comprehensive analysis of two data sources containing financial advisor/representative information:
1. **AdvizorPro Data** - Last 6 months of SQLs from SavvyWealth (`savvy-gtm-analytics.SavvyGTMData.last-6-month-advizorpro`)
2. **MarketPro Discovery Data** - MarketPro discovery data from three staging tables (`savvy-gtm-analytics.LeadScoring.staging_discovery_t1`, `t2`, `t3`)

The document documents the structure, data types, and meaning of variables in each source, and identifies matching fields that can be used for data validation and accuracy checks.

### Key Findings from Data Investigation

**MarketPro Table Structure:**
- **t1**: 198,024 rows with 191,166 distinct CRDs
- **t2**: 173,631 rows with 169,436 distinct CRDs
- **t3**: 106,246 rows with 103,230 distinct CRDs
- **Overlap Analysis**: 99.8% of CRDs appear in only one table; 0.19% appear in 2 tables; 0.014% appear in all 3 tables
- **Critical Finding**: The three tables represent **different RIA firm associations** for the same representatives, not time periods. A single CRD can have multiple RIA associations (one CRD has 51 different RIAs). This means we need to handle multiple rows per CRD when joining.

**Data Quality:**
- **NULL CRDs**: MarketPro has 0% NULL RepCRD values (all rows have valid CRDs)
- **State Format**: Both sources use 2-letter state codes (NY, CA, etc.) - consistent
- **Email Format**: MarketPro emails are all lowercase - use LOWER() for comparison
- **Phone Format**: Standard US format with dashes (e.g., "607-724-2421") - need regex normalization
- **Asset/Account Format**: MarketPro uses formatted strings with dollar signs and commas (e.g., "$597.14", "2,313") - requires parsing

**Data Type Considerations:**
- **CRDs**: AdvizorPro `CRD` is INTEGER; MarketPro `RepCRD` is INTEGER - direct match possible
- **RIA/BD CRDs**: AdvizorPro stores as STRING; MarketPro stores as INTEGER/FLOAT - type conversion needed
- **Formatted Numerics**: MarketPro stores AUM and account counts as formatted strings requiring REGEXP extraction

---

## 1. AdvizorPro Data Source

### 1.1 Overview
- **Table Name**: `savvy-gtm-analytics.SavvyGTMData.last-6-month-advizorpro`
- **Table Type**: EXTERNAL (Google Sheets)
- **Location**: `northamerica-northeast2`
- **Total Fields**: 100
- **Description**: Contains the last 6 months of SQLs (Sales Qualified Leads) from SavvyWealth's AdvizorPro system

### 1.2 Data Structure and Field Categories

#### 1.2.1 Identifier Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `CRD` | INTEGER | Central Registration Depository number - unique identifier for the financial representative |
| `AdvizorPro_ID` | STRING | Unique identifier within the AdvizorPro system |

#### 1.2.2 Personal Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `First_Name` | STRING | Representative's first name |
| `Middle_Name` | STRING | Representative's middle name |
| `Last_Name` | STRING | Representative's last name |
| `Other_Names` | STRING | Alternative names or aliases |
| `Gender` | STRING | Gender identification |
| `Est__Age` | INTEGER | Estimated age of the representative |
| `Years_of_Experience` | INTEGER | Total years of experience in the industry |

#### 1.2.3 Professional Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Title` | STRING | Professional title or role |
| `Designations` | STRING | Professional designations (e.g., CFP, CFA) |
| `Licenses___Exams` | STRING | Financial licenses and exam certifications |
| `Years_with_Current_BD` | FLOAT | Years with current broker-dealer |
| `Current_BD_Start_Date` | DATE | Start date with current broker-dealer |
| `Years_with_Current_RIA` | STRING | Years with current RIA (may be string due to formatting) |
| `Current_RIA_Start_Date` | DATE | Start date with current RIA |

#### 1.2.4 Broker-Dealer (BD) Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Broker_Dealer` | STRING | Name of current broker-dealer firm |
| `Broker_Dealer_CRD` | STRING | CRD number of the broker-dealer firm |
| `Previous_Broker_Dealer` | STRING | Previous broker-dealer firm name |

#### 1.2.5 RIA (Registered Investment Advisor) Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `RIA` | STRING | Name of RIA firm |
| `RIA_CRD` | STRING | CRD number of the RIA firm |
| `Previous_RIA` | STRING | Previous RIA firm name |

#### 1.2.6 Team Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Named_Team_ID` | STRING | Team identifier |
| `Named_Team` | STRING | Team name |
| `Named_Team_Address` | STRING | Team address |
| `Named_Team_Phone` | STRING | Team phone number |
| `Named_Team_Website` | STRING | Team website URL |

#### 1.2.7 Contact Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Address` | STRING | Representative's address |
| `City` | STRING | City |
| `State` | STRING | State |
| `Zip` | INTEGER | ZIP code |
| `Metro_Area` | STRING | Metropolitan area |
| `Phone` | STRING | Phone number |
| `Phone___Type` | STRING | Type of phone (e.g., mobile, landline) |
| `Email_1` | STRING | Primary email address |
| `Email_2` | STRING | Secondary email address |
| `Email_3` | STRING | Tertiary email address |
| `Personal_Email` | STRING | Personal email address |
| `LinkedIn` | STRING | LinkedIn profile URL |

#### 1.2.8 Firm Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Firm_Company_Name` | STRING | Firm company name |
| `Firm_Type` | STRING | Type of firm |
| `Firm_Website` | STRING | Firm website URL |
| `Firm_Address` | STRING | Firm address |
| `Firm_City` | STRING | Firm city |
| `Firm_State` | STRING | Firm state |
| `Firm_Zip` | INTEGER | Firm ZIP code |
| `Firm_Phone` | STRING | Firm phone number |
| `Firm_AUM` | INTEGER | Firm Assets Under Management |
| `Firm_Total_Accounts` | INTEGER | Total number of accounts |
| `Firm_Custodians` | STRING | Custodian information |
| `Firm_Total_Employees` | INTEGER | Total employees at firm |
| `Firm_RIA_Reps` | INTEGER | Number of RIA representatives |
| `Firm_BD_Reps` | INTEGER | Number of BD representatives |
| `Firm_Form_13F` | BOOLEAN | Whether firm files Form 13F |

#### 1.2.9 Tag and Classification Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Person_Tag___Role` | STRING | Role tags |
| `Person_Tag___Family` | STRING | Family-related tags |
| `Person_Tag___Hobbies` | STRING | Hobby tags |
| `Person_Tag___Expertise` | STRING | Expertise tags |
| `Person_Tag___Services` | STRING | Service tags |
| `Person_Tag___Investments` | STRING | Investment-related tags |
| `Person_Tag___Sports_Teams` | STRING | Sports team tags |
| `Person_Tag___School` | STRING | Educational institution tags |
| `Person_Tag___Greek_Life` | STRING | Greek life affiliation tags |
| `Person_Tag___Military_Status` | STRING | Military status tags |
| `Person_Tag___Faith_Based_Investing` | STRING | Faith-based investing tags |
| `Firm_Tag___Platform` | STRING | Platform tags |
| `Firm_Tag___Technology` | STRING | Technology tags |
| `Firm_Tag___Custodian` | STRING | Custodian tags |
| `Firm_Tag___Services` | STRING | Service tags |
| `Firm_Tag___Client_Personas` | STRING | Client persona tags |
| `Firm_Tag___Asset_Classes` | STRING | Asset class tags |
| `Firm_Tag___Investment_Themes` | STRING | Investment theme tags |
| `Firm_Tag___Investment_Vehicles` | STRING | Investment vehicle tags |
| `Firm_Tag___Fund_Managers` | STRING | Fund manager tags |
| `Firm_Tag___Accredited_Investors` | STRING | Accredited investor tags |
| `Firm_Tag___CRM` | STRING | CRM system tags |

#### 1.2.10 Additional Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Bio` | STRING | Biographical information |
| `Notes` | STRING | Additional notes |
| `Profile` | STRING | Profile information |
| `SEC_Link` | STRING | Link to SEC filing |
| `FINRA_Link` | STRING | Link to FINRA information |
| `Registration_Type` | STRING | Registration type |
| `Non_Advisor` | BOOLEAN | Whether the person is a non-advisor |

---

## 2. MarketPro Discovery Data Source

### 2.1 Overview
- **Table Names**: 
  - `savvy-gtm-analytics.LeadScoring.staging_discovery_t1` (198,024 rows)
  - `savvy-gtm-analytics.LeadScoring.staging_discovery_t2` (173,631 rows)
  - `savvy-gtm-analytics.LeadScoring.staging_discovery_t3` (106,246 rows)
- **Table Type**: Standard BigQuery tables
- **Location**: `northamerica-northeast2`
- **Total Fields**: 200 (all three tables have identical schema)
- **Description**: MarketPro discovery data containing detailed information about financial representatives, their firms, and associated metadata

**Note**: All three tables (t1, t2, t3) have the same column structure and data types. They appear to be different time periods or segments of the same data source.

### 2.2 Data Structure and Field Categories

#### 2.2.1 Identifier Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `RepCRD` | INTEGER | Central Registration Depository number - unique identifier for the financial representative |
| `Office_MarketProBranchID` | STRING | MarketPro branch identifier |
| `Office_MarketProPhysicalAddressID` | INTEGER | Physical address identifier in MarketPro |
| `Office_MarketProPhysicalBranchID` | STRING | Physical branch identifier |
| `NPN` | FLOAT | National Producer Number (insurance-related) |

#### 2.2.2 Personal Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `FullName` | STRING | Complete full name of representative |
| `PreferredName_` | STRING | Preferred name or nickname |
| `FirstName` | STRING | First name |
| `MiddleName` | STRING | Middle name |
| `LastName` | STRING | Last name |
| `Suffix` | STRING | Name suffix (Jr., Sr., III, etc.) |
| `Gender` | STRING | Gender identification |
| `DateOfBirth_Full_` | STRING | Full date of birth |
| `DateOfBirth_Year` | FLOAT | Year of birth |
| `DateBecameRep_Full` | STRING | Full date when became a representative |
| `DateBecameRep_Year` | INTEGER | Year when became a representative |
| `DateBecameRep_NumberOfYears` | INTEGER | Number of years as a representative (experience) |

#### 2.2.3 Professional Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Title` | STRING | Professional title |
| `TitleCategories` | STRING | Categories of titles (e.g., "Advisor, Executive") |
| `Licenses` | STRING | Financial licenses (e.g., "66, 7, CFP") |
| `DateOfHireAtCurrentFirm_Full` | STRING | Full date of hire at current firm |
| `DateOfHireAtCurrentFirm_YYYY_MM` | STRING | Date of hire in YYYY-MM format |
| `DateOfHireAtCurrentFirm_Year` | FLOAT | Year of hire at current firm |
| `DateOfHireAtCurrentFirm_NumberOfYears` | FLOAT | Number of years at current firm |
| `RegistrationDate_Full` | STRING | Full registration date |
| `DateAddedToMarketPro` | STRING | Date when added to MarketPro system |

#### 2.2.4 RIA Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `RIAFirmCRD` | INTEGER | CRD number of the RIA firm |
| `RIAFirmName` | STRING | Name of the RIA firm |
| `DBAName` | STRING | Doing Business As name |
| `PrimaryRIAFirmCRD` | INTEGER | Primary RIA firm CRD |
| `IsPrimaryRIAFirm` | STRING | Whether this is the primary RIA firm (Yes/No) |
| `NumberRIAFirmAssociations` | INTEGER | Number of RIA firm associations |
| `DuallyRegisteredBDRIARep` | STRING | Whether dually registered as BD and RIA rep (Yes/No) |

#### 2.2.5 Broker-Dealer Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `BDNameCurrent` | STRING | Current broker-dealer name |
| `PrimaryBDFirmCRD` | FLOAT | Primary BD firm CRD number |
| `NumberBDFirmAssociations` | FLOAT | Number of BD firm associations |
| `BreakawayRep` | STRING | Whether this is a breakaway rep |
| `BreakawayRepFormerBDName` | STRING | Former BD name if breakaway rep |
| `BreakawayDate` | STRING | Date of breakaway |

#### 2.2.6 Firm Association Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `NumberFirmAssociations` | INTEGER | Total number of firm associations |
| `PrimaryFirmCRD` | INTEGER | Primary firm CRD |
| `PriorFirm1` through `PriorFirm4` | STRING | Names of up to 4 prior firms |
| `PriorFirm1_FirmCRD` through `PriorFirm4_FirmCRD` | FLOAT | CRD numbers of prior firms |
| `StartDate1` through `StartDate4` | STRING | Start dates at prior firms |
| `EndDate1` through `EndDate4` | STRING | End dates at prior firms |
| `Number_YearsPriorFirm1` through `Number_YearsPriorFirm4` | FLOAT | Years at each prior firm |

#### 2.2.7 Branch/Office Location Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Branch_Address1` | STRING | Branch address line 1 |
| `Branch_Address2` | STRING | Branch address line 2 |
| `Branch_City` | STRING | Branch city |
| `Branch_State` | STRING | Branch state |
| `Branch_ZipCode` | FLOAT | Branch ZIP code (5-digit) |
| `Branch_ZipCode4` | FLOAT | ZIP+4 extension |
| `Branch_ZipCode3DigitSectional` | FLOAT | 3-digit sectional center |
| `Branch_County` | STRING | Branch county |
| `Branch_MetropolitanArea` | STRING | Metropolitan area |
| `Branch_Country` | STRING | Country |
| `Branch_USPSCertified` | STRING | Whether address is USPS certified (Yes/No) |
| `Branch_AddressType` | STRING | Type of address (e.g., "Local Office") |
| `Branch_AddressUpdate` | STRING | Date of address update |
| `Branch_Longitude` | FLOAT | Geographic longitude |
| `Branch_Latitude` | FLOAT | Geographic latitude |
| `Branch_GeoLocationURL` | STRING | Google Maps URL for location |
| `Office_MarketProBranchName` | STRING | MarketPro branch name |
| `Number_BranchAdvisors` | INTEGER | Number of advisors at branch |

#### 2.2.8 Home Address Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Home_Address1` | STRING | Home address line 1 |
| `Home_Address2` | STRING | Home address line 2 |
| `Home_City` | STRING | Home city |
| `Home_State` | STRING | Home state |
| `Home_ZipCode` | FLOAT | Home ZIP code |
| `Home_ZipCode4` | FLOAT | Home ZIP+4 |
| `Home_MetropolitanArea` | STRING | Home metropolitan area |
| `Home_County` | STRING | Home county |
| `Home_USPSCertified` | STRING | Whether home address is USPS certified |
| `Home_Longitude` | FLOAT | Home longitude |
| `Home_Latitude` | FLOAT | Home latitude |
| `Home_GeoLocationURL` | STRING | Google Maps URL for home |
| `MilesToWork` | FLOAT | Distance in miles from home to work |

#### 2.2.9 Contact Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `DirectDial_Phone` | STRING | Direct dial phone number |
| `DirectDial_PhoneExtension` | FLOAT | Phone extension |
| `DirectDial_PhoneDoNotCall` | STRING | Do not call flag |
| `DirectDial_PhoneType` | STRING | Type of direct dial phone |
| `Branch_Phone` | STRING | Branch phone number |
| `Branch_PhoneExtension` | FLOAT | Branch phone extension |
| `Branch_PhoneDoNotCall` | STRING | Branch phone DNC flag |
| `Branch_PhoneType` | STRING | Branch phone type |
| `Branch_PhoneUpdate` | STRING | Branch phone update date |
| `HQ_Phone` | STRING | Headquarters phone number |
| `HQ_PhoneDoNotCall` | STRING | HQ phone DNC flag |
| `HQ_PhoneType` | STRING | HQ phone type |
| `Home_Phone` | STRING | Home phone number |
| `Home_PhoneDoNotCall` | STRING | Home phone DNC flag |
| `Home_PhoneType` | STRING | Home phone type |
| `Email_BusinessType` | STRING | Business email address |
| `Email_BusinessTypeValidationSupported` | STRING | Whether email validation is supported |
| `Email_BusinessTypeUpdate` | STRING | Business email update date |
| `Email_Business2Type` | STRING | Secondary business email |
| `Email_Business2TypeValidationSupported` | STRING | Secondary email validation support |
| `Email_Business2TypeUpdate` | STRING | Secondary email update date |
| `Email_PersonalType` | STRING | Personal email address |
| `Email_PersonalTypeValidationSupported` | STRING | Personal email validation support |
| `Email_PersonalTypeUpdate` | STRING | Personal email update date |
| `SocialMedia_LinkedIn` | STRING | LinkedIn profile URL |
| `PersonalWebpage` | STRING | Personal webpage URL |
| `FirmWebsite` | STRING | Firm website URL |
| `MarketPro_Profile_URL` | STRING | MarketPro profile URL |

#### 2.2.10 Firm Financial Metrics Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `TotalAssetsInMillions` | STRING | Total assets under management in millions (formatted string) |
| `TotalAccounts` | STRING | Total number of accounts (formatted string) |
| `AverageAccountSize` | STRING | Average account size (formatted string) |
| `Number_IAReps` | INTEGER | Number of IA (Investment Advisor) representatives |
| `Custodian1` through `Custodian5` | STRING | Primary through fifth custodian names |
| `CustodianAUM_Fidelity_NationalFinancial` | FLOAT | AUM at Fidelity/National Financial |
| `CustodianAUM_Pershing` | FLOAT | AUM at Pershing |
| `CustodianAUM_Schwab` | FLOAT | AUM at Schwab |
| `CustodianAUM_TDAmeritrade` | FLOAT | AUM at TD Ameritrade |
| `AUMGrowthRate_1Year` | FLOAT | 1-year AUM growth rate percentage |
| `AUMGrowthRate_5Year` | FLOAT | 5-year AUM growth rate percentage |

#### 2.2.11 Client Demographics Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `NumberClients_HNWIndividuals` | STRING | Number of high net worth individual clients |
| `NumberClients_Individuals` | STRING | Number of individual clients |
| `NumberClients_RetirementPlans` | STRING | Number of retirement plan clients |
| `PercentClients_HNWIndividuals` | FLOAT | Percentage of HNW individual clients |
| `PercentClients_Individuals` | FLOAT | Percentage of individual clients |
| `PercentClients_RetirementPlans` | FLOAT | Percentage of retirement plan clients |
| `AssetsInMillions_HNWIndividuals` | FLOAT | Assets in millions for HNW individuals |
| `AssetsInMillions_Individuals` | FLOAT | Assets in millions for individuals |
| `AssetsInMillions_RetirementPlans` | STRING | Assets in millions for retirement plans |
| `PercentAssets_HNWIndividuals` | FLOAT | Percentage of assets from HNW individuals |
| `PercentAssets_Individuals` | FLOAT | Percentage of assets from individuals |
| `PercentAssets_RetirementPlans` | FLOAT | Percentage of assets from retirement plans |

#### 2.2.12 Investment Product Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `TotalAssets_ETS` | STRING | Total assets in Exchange Traded Securities |
| `ETF_AUM_ETS` | STRING | ETF AUM in ETS |
| `TotalAssets_SeparatelyManagedAccounts` | FLOAT | Total assets in separately managed accounts |
| `TotalAssets_PooledVehicles` | FLOAT | Total assets in pooled vehicles |
| `AssetsInMillions_MutualFunds` | FLOAT | Assets in millions in mutual funds |
| `AssetsInMillions_PrivateFunds` | FLOAT | Assets in millions in private funds |
| `AssetsInMillions_Equity_ExchangeTraded` | FLOAT | Assets in millions in exchange-traded equity |
| `PercentAssets_MutualFunds` | FLOAT | Percentage of assets in mutual funds |
| `PercentAssets_PrivateFunds` | FLOAT | Percentage of assets in private funds |
| `PercentAssets_Equity_ExchangeTraded` | FLOAT | Percentage of assets in exchange-traded equity |

#### 2.2.13 Additional Information Fields
| Field Name | Data Type | Description |
|------------|-----------|-------------|
| `Education` | STRING | Educational background |
| `Language` | STRING | Languages spoken |
| `MilitaryBranch` | STRING | Military branch affiliation |
| `RegulatoryDisclosures` | STRING | Regulatory disclosure information |
| `KnownNonAdvisor` | STRING | Whether known as non-advisor (Yes/No) |
| `Brochure_Keywords` | STRING | Keywords from firm brochure |
| `CustomKeywords` | FLOAT | Custom keywords (appears to be numeric) |
| `Notes` | FLOAT | Notes field (appears to be numeric) |

---

## 3. Field Mapping and Comparison Strategy

### 3.1 Primary Matching Fields

These fields should match exactly if both data sources are accurate and refer to the same individual:

#### 3.1.1 Unique Identifiers
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `CRD` | `RepCRD` | **Exact Match** | Both are INTEGER type. This is the primary key for matching records. CRD numbers are unique identifiers issued by FINRA. |

#### 3.1.2 Name Fields
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `First_Name` | `FirstName` | **Exact Match** | Both STRING. Should match exactly (case-insensitive comparison recommended). |
| `Last_Name` | `LastName` | **Exact Match** | Both STRING. Should match exactly (case-insensitive comparison recommended). |
| `Middle_Name` | `MiddleName` | **Exact Match** | Both STRING. May be null in either source. |

#### 3.1.3 RIA Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `RIA` | `RIAFirmName` | **Exact Match** | Both STRING. RIA firm name should match (case-insensitive). |
| `RIA_CRD` | `RIAFirmCRD` | **Exact Match** | AdvizorPro is STRING, MarketPro is INTEGER. May need type conversion. Should match exactly. |

#### 3.1.4 Broker-Dealer Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Broker_Dealer` | `BDNameCurrent` | **Exact Match** | Both STRING. Current BD name should match (case-insensitive). |
| `Broker_Dealer_CRD` | `PrimaryBDFirmCRD` | **Exact Match** | AdvizorPro is STRING, MarketPro is FLOAT. May need type conversion. Should match exactly. |

### 3.2 Secondary Matching Fields

These fields should match but may have formatting differences or be stored differently:

#### 3.2.1 Contact Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Email_1` | `Email_BusinessType` | **Fuzzy Match** | Both STRING. Should match exactly (case-insensitive). Email_1 is primary email in AdvizorPro, Email_BusinessType is business email in MarketPro. |
| `Phone` | `Branch_Phone` OR `DirectDial_Phone` | **Fuzzy Match** | AdvizorPro has single Phone field, MarketPro has multiple phone fields. Check both Branch_Phone and DirectDial_Phone. |
| `LinkedIn` | `SocialMedia_LinkedIn` | **Fuzzy Match** | Both STRING. LinkedIn URLs should match (may have different formatting). |

#### 3.2.2 Address Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Address` | `Branch_Address1` | **Fuzzy Match** | Both STRING. May have formatting differences. AdvizorPro has single Address field, MarketPro has Address1 and Address2. |
| `City` | `Branch_City` | **Exact Match** | Both STRING. Should match exactly (case-insensitive). |
| `State` | `Branch_State` | **Exact Match** | Both STRING. Should match exactly (case-insensitive, normalize to uppercase). |
| `Zip` | `Branch_ZipCode` | **Exact Match** | AdvizorPro is INTEGER, MarketPro is FLOAT. Should match exactly (may need to truncate MarketPro to 5 digits). |
| `Metro_Area` | `Branch_MetropolitanArea` | **Fuzzy Match** | Both STRING. Metropolitan area names may have slight variations. |

#### 3.2.3 Professional Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Title` | `Title` | **Fuzzy Match** | Both STRING. Titles may have variations or abbreviations. |
| `Licenses___Exams` | `Licenses` | **Fuzzy Match** | Both STRING. License formats may differ (e.g., "7, 66" vs "Series 7, Series 66"). |
| `Years_of_Experience` | `DateBecameRep_NumberOfYears` | **Approximate Match** | AdvizorPro is INTEGER, MarketPro is INTEGER. Should be close but may differ by 1-2 years due to calculation method or update timing. |
| `Years_with_Current_BD` | `DateOfHireAtCurrentFirm_NumberOfYears` | **Approximate Match** | AdvizorPro is FLOAT, MarketPro is FLOAT. Should be close but may differ slightly. |

#### 3.2.4 Firm Information
| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Firm_Company_Name` | `RIAFirmName` OR `Office_MarketProBranchName` | **Fuzzy Match** | May match RIAFirmName or branch name depending on context. |
| `Firm_AUM` | `TotalAssetsInMillions` | **Approximate Match** | AdvizorPro is INTEGER (likely in millions), MarketPro is STRING (formatted). Need to parse MarketPro string and compare. |
| `Firm_Total_Accounts` | `TotalAccounts` | **Approximate Match** | AdvizorPro is INTEGER, MarketPro is STRING (formatted with commas). Need to parse MarketPro string and compare. |
| `Firm_Custodians` | `Custodian1` (and Custodian2-5) | **Fuzzy Match** | AdvizorPro has single STRING field, MarketPro has multiple custodian fields. May need to check if AdvizorPro value appears in any MarketPro custodian field. |

### 3.3 Validation Fields

These fields can be used to validate matches but may not always be present:

| AdvizorPro Field | MarketPro Discovery Field | Match Type | Notes |
|------------------|--------------------------|------------|-------|
| `Gender` | `Gender` | **Exact Match** | Both STRING. Should match exactly. |
| `Previous_Broker_Dealer` | `BreakawayRepFormerBDName` OR `PriorFirm1` through `PriorFirm4` | **Fuzzy Match** | Check if AdvizorPro previous BD matches any of MarketPro's prior firm fields. |
| `Previous_RIA` | `PriorFirm1` through `PriorFirm4` | **Fuzzy Match** | Check if AdvizorPro previous RIA matches any of MarketPro's prior firm fields. |

---

## 4. Comparison and Validation Strategy

### 4.1 MarketPro Table Unification Strategy

**Critical Understanding**: The three MarketPro tables (t1, t2, t3) represent different RIA firm associations for the same representatives, not different time periods. A single CRD can appear multiple times across tables with different RIA associations.

**Unification Approach**: 
- Use `UNION ALL` to combine all three tables
- **DO NOT** use `DISTINCT` on the entire row, as different RIA associations are valid separate records
- When joining to AdvizorPro, we need to handle one-to-many relationships (one AdvizorPro record may match multiple MarketPro records)

**Recommended Unification Query**:
```sql
-- Unified MarketPro view with source table indicator
WITH unified_marketpro AS (
  SELECT 
    RepCRD,
    FirstName,
    LastName,
    MiddleName,
    RIAFirmName,
    RIAFirmCRD,
    BDNameCurrent,
    CAST(PrimaryBDFirmCRD AS INT64) as PrimaryBDFirmCRD,
    Email_BusinessType,
    COALESCE(DirectDial_Phone, Branch_Phone, HQ_Phone) as Phone,
    Branch_City,
    Branch_State,
    CAST(Branch_ZipCode AS INT64) as Branch_ZipCode,
    Branch_MetropolitanArea,
    -- Parse formatted numeric fields
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as TotalAccounts_Numeric,
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
    CAST(PrimaryBDFirmCRD AS INT64) as PrimaryBDFirmCRD,
    Email_BusinessType,
    COALESCE(DirectDial_Phone, Branch_Phone, HQ_Phone) as Phone,
    Branch_City,
    Branch_State,
    CAST(Branch_ZipCode AS INT64) as Branch_ZipCode,
    Branch_MetropolitanArea,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as TotalAccounts_Numeric,
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
    CAST(PrimaryBDFirmCRD AS INT64) as PrimaryBDFirmCRD,
    Email_BusinessType,
    COALESCE(DirectDial_Phone, Branch_Phone, HQ_Phone) as Phone,
    Branch_City,
    Branch_State,
    CAST(Branch_ZipCode AS INT64) as Branch_ZipCode,
    Branch_MetropolitanArea,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as TotalAccounts_Numeric,
    DateBecameRep_NumberOfYears,
    DateOfHireAtCurrentFirm_NumberOfYears,
    't3' as source_table
  FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
  WHERE RepCRD IS NOT NULL
)
```

### 4.2 Data Cleaning and Normalization Functions

#### 4.2.1 Phone Number Normalization
```sql
-- Normalize phone numbers to digits only for comparison
REGEXP_REPLACE(COALESCE(phone_field, ''), r'[^0-9]', '') as phone_normalized
```

#### 4.2.2 Asset/Account Parsing
```sql
-- Parse TotalAssetsInMillions from "$597.14" or "$11,156.01" format
CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as aum_numeric

-- Parse TotalAccounts from "2,313" format
CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as accounts_numeric
```

#### 4.2.3 CRD Type Conversion
```sql
-- Convert AdvizorPro STRING CRDs to INT64 for comparison
CAST(RIA_CRD AS INT64) as ria_crd_int
CAST(Broker_Dealer_CRD AS INT64) as bd_crd_int
```

#### 4.2.4 String Normalization
```sql
-- Normalize strings for comparison (trim, uppercase)
UPPER(TRIM(field_name)) as field_normalized

-- Email normalization (already lowercase in MarketPro, but normalize AdvizorPro)
LOWER(TRIM(email_field)) as email_normalized
```

### 4.3 Matching Algorithm

1. **Primary Match on CRD**: 
   - Match `CRD` (AdvizorPro) with `RepCRD` (MarketPro Discovery)
   - This is the most reliable matching method as CRD numbers are unique identifiers
   - **Note**: One AdvizorPro record may match multiple MarketPro records (one-to-many relationship)

2. **Validation Checks** (for matched CRD pairs):
   - **Name Validation**: Compare `First_Name`/`FirstName` and `Last_Name`/`LastName` (case-insensitive, trimmed)
   - **RIA Validation**: Compare `RIA`/`RIAFirmName` (case-insensitive) and `RIA_CRD`/`RIAFirmCRD` (with type conversion)
   - **BD Validation**: Compare `Broker_Dealer`/`BDNameCurrent` (case-insensitive) and `Broker_Dealer_CRD`/`PrimaryBDFirmCRD` (with type conversion)
   - **Contact Validation**: Compare `Email_1`/`Email_BusinessType` (lowercase) and normalized phone numbers
   - **Address Validation**: Compare address components (City, State, Zip) with normalization

3. **Data Quality Indicators**:
   - **High Confidence Match**: CRD matches AND name matches AND RIA/BD matches
   - **Medium Confidence Match**: CRD matches AND name matches (but RIA/BD differs - may indicate different firm associations or data update lag)
   - **Low Confidence Match**: CRD matches but significant differences in other fields (may indicate data quality issues)

### 4.2 Expected Match Rates

Assuming both data sources are accurate and up-to-date:
- **CRD Match**: Should be 100% if both sources contain the same individuals
- **Name Match**: Should be >95% (allowing for minor spelling variations)
- **RIA Match**: Should be >90% (allowing for timing differences in updates)
- **BD Match**: Should be >90% (allowing for timing differences in updates)
- **Email Match**: Should be >80% (email may not always be available in both sources)
- **Phone Match**: Should be >70% (phone numbers may vary or be formatted differently)

### 4.3 Data Type Considerations

1. **String vs Numeric**: Some fields like `RIA_CRD` and `Broker_Dealer_CRD` are STRING in AdvizorPro but INTEGER/FLOAT in MarketPro. Convert to same type before comparison.

2. **Formatted Strings**: MarketPro has many fields stored as formatted strings (e.g., `TotalAssetsInMillions` = "$597.14", `TotalAccounts` = "2,313"). These need to be parsed before numeric comparison.

3. **Date Formats**: Date fields may be stored in different formats (DATE type vs STRING). Standardize format before comparison.

4. **Null Handling**: Many fields may be NULL in one source but populated in another. This is expected and should not be considered a mismatch.

### 4.4 Master Comparison Query Skeleton

**Complete Comparison Query with All Normalizations**:

```sql
WITH unified_marketpro AS (
  -- Unified MarketPro data (see section 4.1 for full query)
  SELECT 
    RepCRD,
    FirstName,
    LastName,
    MiddleName,
    RIAFirmName,
    RIAFirmCRD,
    BDNameCurrent,
    CAST(PrimaryBDFirmCRD AS INT64) as PrimaryBDFirmCRD,
    LOWER(TRIM(Email_BusinessType)) as Email_BusinessType_Normalized,
    REGEXP_REPLACE(COALESCE(DirectDial_Phone, Branch_Phone, HQ_Phone, ''), r'[^0-9]', '') as Phone_Normalized,
    UPPER(TRIM(Branch_City)) as Branch_City_Normalized,
    UPPER(TRIM(Branch_State)) as Branch_State_Normalized,
    CAST(Branch_ZipCode AS INT64) as Branch_ZipCode_Normalized,
    CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as TotalAssetsInMillions_Numeric,
    CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as TotalAccounts_Numeric,
    DateBecameRep_NumberOfYears,
    DateOfHireAtCurrentFirm_NumberOfYears,
    source_table
  FROM (
    SELECT * FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t1`
    UNION ALL
    SELECT * FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t2`
    UNION ALL
    SELECT * FROM `savvy-gtm-analytics.LeadScoring.staging_discovery_t3`
  )
  WHERE RepCRD IS NOT NULL
),
advizorpro_normalized AS (
  SELECT 
    CRD,
    UPPER(TRIM(First_Name)) as First_Name_Normalized,
    UPPER(TRIM(Last_Name)) as Last_Name_Normalized,
    UPPER(TRIM(Middle_Name)) as Middle_Name_Normalized,
    UPPER(TRIM(RIA)) as RIA_Normalized,
    CAST(RIA_CRD AS INT64) as RIA_CRD_Int,
    UPPER(TRIM(Broker_Dealer)) as Broker_Dealer_Normalized,
    CAST(Broker_Dealer_CRD AS INT64) as Broker_Dealer_CRD_Int,
    LOWER(TRIM(Email_1)) as Email_1_Normalized,
    REGEXP_REPLACE(COALESCE(Phone, ''), r'[^0-9]', '') as Phone_Normalized,
    UPPER(TRIM(City)) as City_Normalized,
    UPPER(TRIM(State)) as State_Normalized,
    Zip as Zip_Normalized,
    Firm_AUM,
    Firm_Total_Accounts,
    Years_of_Experience,
    Years_with_Current_BD
  FROM `savvy-gtm-analytics.SavvyGTMData.last-6-month-advizorpro`
  WHERE CRD IS NOT NULL
)
SELECT 
  a.CRD,
  -- Name matching
  a.First_Name_Normalized as advizor_first_name,
  m.FirstName as marketpro_first_name,
  a.Last_Name_Normalized as advizor_last_name,
  m.LastName as marketpro_last_name,
  CASE 
    WHEN a.First_Name_Normalized = UPPER(TRIM(m.FirstName))
     AND a.Last_Name_Normalized = UPPER(TRIM(m.LastName))
    THEN 'MATCH' ELSE 'MISMATCH' 
  END as name_match_status,
  
  -- RIA matching
  a.RIA_Normalized as advizor_ria,
  m.RIAFirmName as marketpro_ria,
  a.RIA_CRD_Int as advizor_ria_crd,
  m.RIAFirmCRD as marketpro_ria_crd,
  CASE 
    WHEN a.RIA_Normalized = UPPER(TRIM(m.RIAFirmName))
     AND a.RIA_CRD_Int = m.RIAFirmCRD
    THEN 'MATCH' 
    WHEN a.RIA_CRD_Int = m.RIAFirmCRD
    THEN 'CRD_MATCH_NAME_DIFF'
    ELSE 'MISMATCH' 
  END as ria_match_status,
  
  -- BD matching
  a.Broker_Dealer_Normalized as advizor_bd,
  m.BDNameCurrent as marketpro_bd,
  a.Broker_Dealer_CRD_Int as advizor_bd_crd,
  m.PrimaryBDFirmCRD as marketpro_bd_crd,
  CASE 
    WHEN a.Broker_Dealer_Normalized = UPPER(TRIM(m.BDNameCurrent))
     AND a.Broker_Dealer_CRD_Int = m.PrimaryBDFirmCRD
    THEN 'MATCH' 
    WHEN a.Broker_Dealer_CRD_Int = m.PrimaryBDFirmCRD
    THEN 'CRD_MATCH_NAME_DIFF'
    ELSE 'MISMATCH' 
  END as bd_match_status,
  
  -- Email matching
  a.Email_1_Normalized as advizor_email,
  m.Email_BusinessType_Normalized as marketpro_email,
  CASE 
    WHEN a.Email_1_Normalized = m.Email_BusinessType_Normalized
    THEN 'MATCH' 
    WHEN a.Email_1_Normalized IS NULL OR m.Email_BusinessType_Normalized IS NULL
    THEN 'MISSING'
    ELSE 'MISMATCH' 
  END as email_match_status,
  
  -- Phone matching
  a.Phone_Normalized as advizor_phone,
  m.Phone_Normalized as marketpro_phone,
  CASE 
    WHEN a.Phone_Normalized = m.Phone_Normalized 
     AND LENGTH(a.Phone_Normalized) >= 10
    THEN 'MATCH' 
    WHEN a.Phone_Normalized IS NULL OR m.Phone_Normalized IS NULL
    THEN 'MISSING'
    ELSE 'MISMATCH' 
  END as phone_match_status,
  
  -- Address matching
  a.City_Normalized as advizor_city,
  m.Branch_City_Normalized as marketpro_city,
  a.State_Normalized as advizor_state,
  m.Branch_State_Normalized as marketpro_state,
  a.Zip_Normalized as advizor_zip,
  m.Branch_ZipCode_Normalized as marketpro_zip,
  CASE 
    WHEN a.City_Normalized = m.Branch_City_Normalized
     AND a.State_Normalized = m.Branch_State_Normalized
     AND a.Zip_Normalized = m.Branch_ZipCode_Normalized
    THEN 'MATCH' 
    WHEN a.State_Normalized = m.Branch_State_Normalized
     AND a.Zip_Normalized = m.Branch_ZipCode_Normalized
    THEN 'PARTIAL_MATCH'
    ELSE 'MISMATCH' 
  END as address_match_status,
  
  -- Numeric field comparisons
  a.Firm_AUM as advizor_aum,
  m.TotalAssetsInMillions_Numeric as marketpro_aum,
  CASE 
    WHEN ABS(a.Firm_AUM - m.TotalAssetsInMillions_Numeric) <= 1.0
    THEN 'MATCH' 
    WHEN ABS(a.Firm_AUM - m.TotalAssetsInMillions_Numeric) / NULLIF(a.Firm_AUM, 0) <= 0.05
    THEN 'CLOSE_MATCH'
    ELSE 'MISMATCH' 
  END as aum_match_status,
  
  a.Firm_Total_Accounts as advizor_accounts,
  m.TotalAccounts_Numeric as marketpro_accounts,
  CASE 
    WHEN a.Firm_Total_Accounts = m.TotalAccounts_Numeric
    THEN 'MATCH' 
    WHEN ABS(a.Firm_Total_Accounts - m.TotalAccounts_Numeric) <= 5
    THEN 'CLOSE_MATCH'
    ELSE 'MISMATCH' 
  END as accounts_match_status,
  
  -- Overall match confidence
  CASE 
    WHEN a.First_Name_Normalized = UPPER(TRIM(m.FirstName))
     AND a.Last_Name_Normalized = UPPER(TRIM(m.LastName))
     AND a.RIA_CRD_Int = m.RIAFirmCRD
     AND a.Broker_Dealer_CRD_Int = m.PrimaryBDFirmCRD
    THEN 'HIGH_CONFIDENCE'
    WHEN a.First_Name_Normalized = UPPER(TRIM(m.FirstName))
     AND a.Last_Name_Normalized = UPPER(TRIM(m.LastName))
    THEN 'MEDIUM_CONFIDENCE'
    ELSE 'LOW_CONFIDENCE'
  END as match_confidence,
  
  m.source_table

FROM advizorpro_normalized a
INNER JOIN unified_marketpro m
  ON a.CRD = m.RepCRD
ORDER BY a.CRD, m.RIAFirmCRD
```

### 4.5 Handling One-to-Many Relationships

Since one AdvizorPro record can match multiple MarketPro records (due to multiple RIA associations), consider:

1. **Option A: All Matches** - Return all MarketPro records that match the CRD (may result in multiple rows per AdvizorPro record)

2. **Option B: Best Match** - Use window functions to select the "best" match based on RIA/BD alignment:
```sql
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY a.CRD 
  ORDER BY 
    CASE WHEN a.RIA_CRD_Int = m.RIAFirmCRD THEN 1 ELSE 2 END,
    CASE WHEN a.Broker_Dealer_CRD_Int = m.PrimaryBDFirmCRD THEN 1 ELSE 2 END
) = 1
```

3. **Option C: Aggregate** - Aggregate MarketPro data per CRD (e.g., count of RIA associations, list of RIA names)

---

## 5. Conclusion: Fields for Accuracy and Precision Validation

### 5.1 Primary Validation Fields (Must Match)

These fields should match exactly if both data sources are accurate and refer to the same individual:

1. **`CRD` / `RepCRD`** - Primary identifier, must match exactly
2. **`First_Name` / `FirstName`** - Must match (case-insensitive)
3. **`Last_Name` / `LastName`** - Must match (case-insensitive)
4. **`RIA_CRD` / `RIAFirmCRD`** - Must match exactly (with type conversion)
5. **`Broker_Dealer_CRD` / `PrimaryBDFirmCRD`** - Must match exactly (with type conversion)

### 5.2 Secondary Validation Fields (Should Match)

These fields should match but may have minor variations or formatting differences:

1. **`RIA` / `RIAFirmName`** - Should match (case-insensitive)
2. **`Broker_Dealer` / `BDNameCurrent`** - Should match (case-insensitive)
3. **`Email_1` / `Email_BusinessType`** - Should match (case-insensitive)
4. **`City` / `Branch_City`** - Should match (case-insensitive)
5. **`State` / `Branch_State`** - Should match (normalized to uppercase)
6. **`Zip` / `Branch_ZipCode`** - Should match (first 5 digits)

### 5.3 Approximate Validation Fields (Should Be Close)

These fields should be similar but may differ slightly due to calculation methods or update timing:

1. **`Years_of_Experience` / `DateBecameRep_NumberOfYears`** - Should be within 1-2 years
2. **`Years_with_Current_BD` / `DateOfHireAtCurrentFirm_NumberOfYears`** - Should be within 1 year
3. **`Firm_AUM` / `TotalAssetsInMillions`** - Should be close (allowing for rounding differences)
4. **`Firm_Total_Accounts` / `TotalAccounts`** - Should match exactly (after parsing formatted string)

### 5.4 Recommended Validation Workflow

1. **Step 1: Match on CRD**
   - Join tables on `CRD` = `RepCRD`
   - This identifies records that should represent the same individual

2. **Step 2: Validate Primary Fields**
   - Check name match (`First_Name` = `FirstName`, `Last_Name` = `LastName`)
   - Check RIA match (`RIA_CRD` = `RIAFirmCRD`, `RIA` = `RIAFirmName`)
   - Check BD match (`Broker_Dealer_CRD` = `PrimaryBDFirmCRD`, `Broker_Dealer` = `BDNameCurrent`)

3. **Step 3: Validate Secondary Fields**
   - Check email match (`Email_1` = `Email_BusinessType`)
   - Check address match (City, State, Zip)
   - Check phone match (`Phone` = `Branch_Phone` OR `DirectDial_Phone`)

4. **Step 4: Validate Approximate Fields**
   - Compare years of experience (allow ±2 years difference)
   - Compare AUM and account counts (allow for rounding/formatt

ing differences)

5. **Step 5: Flag Discrepancies**
   - Create a report of all mismatches
   - Categorize mismatches by severity (critical vs. minor)
   - Investigate significant discrepancies to determine data quality issues

### 5.5 Expected Outcomes

If both data sources are accurate and up-to-date:
- **>95%** of records should match on CRD
- **>90%** of matched records should have matching names
- **>85%** of matched records should have matching RIA information
- **>85%** of matched records should have matching BD information
- **>70%** of matched records should have matching email addresses
- **>80%** of matched records should have matching address information

Lower match rates may indicate:
- Data quality issues in one or both sources
- Timing differences in data updates
- Different data collection methodologies
- Missing or incomplete data in one source

---

## 6. Recommendations

1. **Use CRD as Primary Key**: Always match records using CRD numbers first, as this is the most reliable identifier.

2. **Normalize Before Comparison**: 
   - Convert all strings to uppercase/lowercase for comparison
   - Remove leading/trailing whitespace
   - Handle NULL values appropriately

3. **Type Conversion**: Convert STRING CRD fields to INTEGER before comparison to ensure accurate matching.

4. **Parse Formatted Fields**: Extract numeric values from formatted strings (e.g., "$597.14" → 597.14) before comparison.

5. **Allow for Timing Differences**: Some fields may differ due to update timing. Allow reasonable tolerances for date-based calculations.

6. **Document Discrepancies**: Maintain a log of all discrepancies found during validation to identify patterns and data quality issues.

7. **Regular Validation**: Perform these comparisons regularly to ensure ongoing data quality and identify when one source may be out of sync with the other.

---

## 7. Investigation Findings Summary

### 7.1 MarketPro Table Structure Findings

| Finding | Details |
|---------|---------|
| **Table Sizes** | t1: 198,024 rows (191,166 distinct CRDs)<br>t2: 173,631 rows (169,436 distinct CRDs)<br>t3: 106,246 rows (103,230 distinct CRDs) |
| **Overlap** | 99.8% of CRDs appear in only 1 table<br>0.19% appear in 2 tables<br>0.014% appear in all 3 tables |
| **Key Insight** | Tables represent **different RIA firm associations**, not time periods. Same CRD can have multiple RIA associations across tables. |
| **Deduplication Strategy** | Use `UNION ALL` (not DISTINCT) to preserve all firm associations. Handle one-to-many relationships when joining to AdvizorPro. |

### 7.2 Data Format Findings

| Field Type | Format | Normalization Required |
|------------|--------|----------------------|
| **TotalAssetsInMillions** | "$597.14" or "$11,156.01" | `REGEXP_REPLACE(field, r'[^0-9.]', '')` then `CAST AS FLOAT64` |
| **TotalAccounts** | "2,313" | `REGEXP_REPLACE(field, r'[^0-9]', '')` then `CAST AS INT64` |
| **Phone Numbers** | "607-724-2421" | `REGEXP_REPLACE(field, r'[^0-9]', '')` to extract digits only |
| **States** | "NY", "CA" (2-letter codes) | Already normalized, use `UPPER(TRIM())` for consistency |
| **Emails** | All lowercase in MarketPro | Use `LOWER(TRIM())` for both sources |

### 7.3 Data Quality Findings

| Metric | Finding |
|--------|---------|
| **NULL CRDs in MarketPro** | 0% (all rows have valid RepCRD) |
| **CRD Data Types** | AdvizorPro: INTEGER<br>MarketPro: INTEGER<br>✅ Direct match possible |
| **RIA/BD CRD Types** | AdvizorPro: STRING<br>MarketPro: INTEGER/FLOAT<br>⚠️ Type conversion needed: `CAST(AdvizorPro_CRD AS INT64)` |

### 7.4 Recommended SQL Patterns

**Phone Normalization:**
```sql
REGEXP_REPLACE(COALESCE(phone_field, ''), r'[^0-9]', '') as phone_normalized
```

**Asset Parsing:**
```sql
CAST(REGEXP_REPLACE(TotalAssetsInMillions, r'[^0-9.]', '') AS FLOAT64) as aum_numeric
```

**Account Parsing:**
```sql
CAST(REGEXP_REPLACE(TotalAccounts, r'[^0-9]', '') AS INT64) as accounts_numeric
```

**String Normalization:**
```sql
UPPER(TRIM(field_name)) as field_normalized  -- For names, addresses
LOWER(TRIM(email_field)) as email_normalized  -- For emails
```

**CRD Type Conversion:**
```sql
CAST(RIA_CRD AS INT64) as ria_crd_int
CAST(Broker_Dealer_CRD AS INT64) as bd_crd_int
```

---

**Document Version**: 2.0  
**Last Updated**: 2025-01-27  
**Author**: Data Analysis Team  
**Revision Notes**: Updated with data investigation findings, refined SQL strategies, and normalization patterns

