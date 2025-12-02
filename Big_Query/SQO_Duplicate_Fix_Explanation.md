# SQO Duplicate Issue - Resolution Summary

## Problem Identified

We discovered a duplicate entry issue in the Outbound SQOs table where the **Luis Rosa** opportunity appeared twice with different SGA owners:
- One entry showing **SGA_Owner_Name__c = Ryan Crandall**
- Another entry showing **SGA_Owner_Name__c = Chris Morgan**

Both entries pointed to the same Salesforce opportunity record (`006VS00000RD1GUYA1`), but the dashboard was showing conflicting SGA attribution.

## Root Cause

This occurred due to Salesforce's account structure where **one Account can have multiple Contacts**. In this case:

1. **Account**: Contains two contacts
   - **Luis Rosa** (Contact 1)
   - **Catalina Franco-Cicero** (Contact 2)

2. **Lead Records**:
   - **Luis Rosa Lead** (`00QVS00000FcGkh2AF`): 
     - Original SGA: **Chris Morgan**
     - Converted to Opportunity: `006VS00000RD1GUYA1`
     - Converted Date: 2025-10-09
   
   - **Catalina Franco-Cicero Lead** (`00QVS00000D6B9P2AV`):
     - Original SGA: **Ryan Crandall**
     - Also converted to the same Opportunity: `006VS00000RD1GUYA1`
     - Converted Date: 2025-11-12

3. **Opportunity Record**:
   - Name: **Luis Rosa**
   - SGA: **Ryan Crandall** (the correct SGA for the SQO)
   - SQO Status: Yes
   - Date Became SQO: 2025-10-16

### Why This Happened

When multiple leads convert to the same opportunity, our view (`vw_funnel_lead_to_joined_v2`) was creating one row per lead-opportunity combination. The original logic was using each lead's SGA owner, which caused:
- Luis Rosa's row to show **Chris Morgan** (from his lead)
- Catalina's row to show **Ryan Crandall** (from her lead)

However, **only Luis Rosa actually became an SQO** - Catalina Franco-Cicero retired and never became an SQO, even though her lead converted to the same opportunity.

## Solution Implemented

We modified the view logic in two key areas:

### 1. SQO Identification (`is_sqo` field)
Changed the logic to only mark a lead as an SQO if:
- The opportunity is an SQO (`SQO_raw = 'yes'`)
- **AND** the lead's name matches the opportunity name (or it's an opportunity-only record)

This ensures only the **primary contact** (whose name matches the opportunity) is counted as the SQO.

### 2. SGA Attribution (`SGA_Owner_Name__c` field)
Updated the logic to:
- **For SQOs**: Use the **Opportunity's SGA** (the source of truth for SQO attribution)
- **For non-SQOs**: Use the **Lead's SGA** (preserves original lead attribution for non-SQO records)

## Results After Fix

After deploying the updated view:

### Luis Rosa
- ✅ `is_sqo = 1` (correctly identified as SQO)
- ✅ `SGA_Owner_Name__c = Ryan Crandall` (from Opportunity - correct attribution)
- ✅ Appears in Outbound SQOs dashboard

### Catalina Franco-Cicero
- ✅ `is_sqo = 0` (correctly NOT identified as SQO - she retired)
- ✅ `SGA_Owner_Name__c = Ryan Crandall` (from Lead - her original SGA)
- ✅ Does NOT appear in Outbound SQOs dashboard (filtered out by `is_sqo = 1`)

## Key Takeaway

This scenario can occur in Salesforce when:
- One Account has multiple Contacts
- Multiple Leads convert to the same Opportunity
- Only one Contact actually becomes an SQO

Our fix ensures that:
1. **Only the primary contact** (name matching opportunity) is counted as the SQO
2. **SQO attribution** always comes from the Opportunity record (the source of truth)
3. **Non-SQO leads** maintain their original Lead SGA attribution

## Dashboard Impact

Your Outbound SQOs table will now show:
- ✅ **One entry** for Luis Rosa
- ✅ **Correct SGA attribution**: Ryan Crandall (from Opportunity)
- ✅ **No duplicate entries** for the same opportunity
- ✅ **Catalina Franco-Cicero excluded** from SQO reporting (as she didn't SQO)

The view has been deployed and is live in BigQuery. The dashboard should automatically reflect these changes on the next refresh.

