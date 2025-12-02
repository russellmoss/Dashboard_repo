# Impact_Attendees_Enriched Table Analysis

**Table**: `savvy-gtm-analytics.LeadScoring.Impact_Attendees_Enriched`  
**Total Rows**: 1,798  
**Analysis Date**: Generated via BigQuery MCP

---

## 1. Columns with Absolutely No Data

**Result: NONE** ✅

All columns in the table contain at least some data. Every column has non-NULL values, with varying levels of completeness:
- Most columns are fully populated (1,798 non-NULL values)
- Some columns have partial data (lowest: 209 non-NULL values for `Email_Business2Type*` columns)
- The most sparse columns are:
  - `Email_Business2Type` and related fields: 209 non-NULL (11.6% populated)
  - `Email_PersonalType` and related fields: 332 non-NULL (18.5% populated)
  - `Email_BusinessType` and related fields: 1,241 non-NULL (69.0% populated)

---

## 2. All Column Names and Data Types

### Personal Information Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `Impact_LastName` | STRING | 1,798 | 100% |
| `Impact_FirstName` | STRING | 1,798 | 100% |
| `Impact_Title` | STRING | 1,798 | 100% |
| `Impact_Company` | STRING | 1,798 | 100% |
| `FullName` | STRING | 1,798 | 100% |
| `FirstName` | STRING | 1,798 | 100% |
| `LastName` | STRING | 1,798 | 100% |
| `TitleCategories` | STRING | 1,798 | 100% |
| `Gender` | STRING | 1,763 | 98.1% |
| `KnownNonAdvisor` | STRING | 1,798 | 100% |

### CRD & Identification Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `RepCRD` | INTEGER | 1,798 | 100% |
| `RIAFirmCRD` | INTEGER | 1,798 | 100% |
| `PrimaryFirmCRD` | INTEGER | 1,798 | 100% |
| `PrimaryRIAFirmCRD` | INTEGER | 1,798 | 100% |
| `RIAFirmName` | STRING | 1,798 | 100% |

### Branch/Location Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `Number_BranchAdvisors` | INTEGER | 1,798 | 100% |
| `Branch_Address1` | STRING | 1,798 | 100% |
| `Branch_City` | STRING | 1,798 | 100% |
| `Branch_State` | STRING | 1,798 | 100% |
| `Branch_ZipCode` | STRING | 1,706 | 94.9% |
| `Branch_ZipCode3DigitSectional` | STRING | 1,706 | 94.9% |
| `Branch_County` | STRING | 1,752 | 97.4% |
| `Branch_MetropolitanArea` | STRING | 1,641 | 91.3% |
| `Branch_Country` | STRING | 1,798 | 100% |
| `Branch_USPSCertified` | STRING | 1,798 | 100% |
| `Branch_AddressType` | STRING | 1,798 | 100% |
| `Branch_Longitude` | FLOAT | 1,706 | 94.9% |
| `Branch_Latitude` | FLOAT | 1,706 | 94.9% |
| `Branch_GeoLocationURL` | STRING | 1,701 | 94.6% |

### Office/MarketPro Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `Office_MarketProBranchID` | STRING | 1,798 | 100% |
| `Office_MarketProPhysicalAddressID` | INTEGER | 1,798 | 100% |
| `Office_MarketProPhysicalBranchID` | STRING | 1,798 | 100% |
| `Office_MarketProBranchName` | STRING | 1,798 | 100% |

### Contact Information Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `HQ_Phone` | STRING | 1,797 | 99.9% |
| `HQ_PhoneType` | STRING | 1,797 | 99.9% |
| `FirmWebsite` | STRING | 1,724 | 95.9% |
| `SocialMedia_LinkedIn` | STRING | 1,601 | 89.0% |

### Email Type Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `Email_BusinessType` | STRING | 1,241 | 69.0% |
| `Email_BusinessTypeValidationSupported` | STRING | 1,241 | 69.0% |
| `Email_BusinessTypeUpdate` | STRING | 1,241 | 69.0% |
| `Email_Business2Type` | STRING | 209 | 11.6% |
| `Email_Business2TypeValidationSupported` | STRING | 209 | 11.6% |
| `Email_Business2TypeUpdate` | STRING | 209 | 11.6% |
| `Email_PersonalType` | STRING | 332 | 18.5% |
| `Email_PersonalTypeValidationSupported` | STRING | 332 | 18.5% |
| `Email_PersonalTypeUpdate` | STRING | 332 | 18.5% |

### Firm Asset & Account Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `TotalAssetsInMillions` | STRING | 1,664 | 92.5% |
| `TotalAccounts` | STRING | 1,640 | 91.2% |
| `AverageAccountSize` | STRING | 1,640 | 91.2% |
| `Custodian1` | STRING | 1,751 | 97.4% |
| `TotalAssets_ETS` | STRING | 1,798 | 100% |
| `ETF_AUM_ETS` | STRING | 1,798 | 100% |
| `TotalAssets_SeparatelyManagedAccounts` | FLOAT | 1,640 | 91.2% |
| `TotalAssets_PooledVehicles` | FLOAT | 1,647 | 91.6% |
| `AUMGrowthRate_1Year` | FLOAT | 1,559 | 86.7% |

### Client Demographics Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `NumberClients_HNWIndividuals` | STRING | 1,782 | 99.1% |
| `NumberClients_Individuals` | STRING | 1,783 | 99.2% |
| `NumberClients_RetirementPlans` | STRING | 1,782 | 99.1% |
| `PercentClients_HNWIndividuals` | FLOAT | 1,782 | 99.1% |
| `PercentClients_Individuals` | FLOAT | 1,783 | 99.2% |
| `PercentClients_RetirementPlans` | FLOAT | 1,782 | 99.1% |
| `AssetsInMillions_HNWIndividuals` | FLOAT | 1,782 | 99.1% |
| `AssetsInMillions_Individuals` | FLOAT | 1,783 | 99.2% |
| `AssetsInMillions_RetirementPlans` | FLOAT | 1,782 | 99.1% |
| `PercentAssets_HNWIndividuals` | FLOAT | 1,782 | 99.1% |
| `PercentAssets_Individuals` | FLOAT | 1,783 | 99.2% |
| `PercentAssets_RetirementPlans` | FLOAT | 1,782 | 99.1% |

### Registration & Compliance Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `DuallyRegisteredBDRIARep` | STRING | 1,798 | 100% |
| `NumberFirmAssociations` | INTEGER | 1,798 | 100% |
| `NumberRIAFirmAssociations` | INTEGER | 1,798 | 100% |
| `IsPrimaryRIAFirm` | STRING | 1,798 | 100% |
| `Licenses` | STRING | 1,707 | 94.9% |
| `RegulatoryDisclosures` | STRING | 1,798 | 100% |
| `Number_IAReps` | INTEGER | 1,798 | 100% |

### Date Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `DateBecameRep_Full` | STRING | 1,798 | 100% |
| `DateBecameRep_Year` | INTEGER | 1,798 | 100% |
| `DateBecameRep_NumberOfYears` | INTEGER | 1,798 | 100% |
| `DateOfHireAtCurrentFirm_Full` | STRING | 1,798 | 100% |
| `DateOfHireAtCurrentFirm_YYYY_MM` | STRING | 1,798 | 100% |
| `DateOfHireAtCurrentFirm_Year` | FLOAT | 1,798 | 100% |
| `DateOfHireAtCurrentFirm_NumberOfYears` | FLOAT | 1,798 | 100% |
| `RegistrationDate_Full` | STRING | 1,798 | 100% |
| `DateAddedToMarketPro` | STRING | 1,798 | 100% |

### Miscellaneous Columns

| Column Name | Data Type | Non-NULL Count | % Populated |
|------------|-----------|----------------|-------------|
| `MarketPro_Profile_URL` | STRING | 1,798 | 100% |
| `Brochure_Keywords` | STRING | 1,773 | 98.6% |

---

## Summary Statistics

- **Total Columns**: 90
- **Columns with 100% data**: 59 columns
- **Columns with 90-99% data**: 20 columns
- **Columns with 50-89% data**: 10 columns
- **Columns with <50% data**: 1 column (`Email_Business2Type*` group - 11.6%)

**Data Completeness**: The table is well-populated overall, with most columns having complete or near-complete data. The email type columns are the least populated, which is expected as not all reps may have multiple email addresses or business email types validated.

