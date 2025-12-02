CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_experimentation_tag_combinations` AS
WITH base AS (
  SELECT
    primary_key,
    Experimentation_Tag_Raw__c,
    Experimentation_Tag_List,
    FilterDate,
    Full_prospect_id__c,
    Full_Opportunity_ID__c,
    is_contacted,
    is_mql,
    is_sql,
    is_sqo,
    is_signed,
    is_joined,
    Opportunity_AUM,
    SQL_conversion_status
  FROM `savvy-gtm-analytics.savvy_analytics.vw_experimentation_tags`
  WHERE Experimentation_Tag_Raw__c IS NOT NULL AND Experimentation_Tag_Raw__c != ''
),
metrics AS (
  SELECT
    Experimentation_Tag_Raw__c,
    COUNT(DISTINCT CASE WHEN Full_prospect_id__c IS NOT NULL THEN Full_prospect_id__c END) AS total_prospects,
    COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN primary_key END) AS contacting,
    COUNT(DISTINCT CASE WHEN is_mql = 1 THEN primary_key END) AS mql,
    COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END) AS sql,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN primary_key END) AS sqo,
    COUNT(DISTINCT CASE WHEN is_signed = 1 THEN primary_key END) AS signed,
    COUNT(DISTINCT CASE WHEN is_joined = 1 THEN primary_key END) AS joined,
    SUM(CASE WHEN is_signed = 1 THEN Opportunity_AUM ELSE 0 END) AS signed_aum,
    SUM(CASE WHEN is_contacted = 1 THEN 1 ELSE 0 END) AS contacted_denominator,
    SUM(CASE WHEN is_contacted = 1 AND is_mql = 1 THEN 1 ELSE 0 END) AS contacted_to_mql_numerator,
    SUM(CASE WHEN is_mql = 1 THEN 1 ELSE 0 END) AS mql_denominator,
    SUM(CASE WHEN is_mql = 1 AND is_sql = 1 THEN 1 ELSE 0 END) AS mql_to_sql_numerator,
    COUNT(DISTINCT CASE 
        WHEN is_sql = 1 
         AND SQL_conversion_status IN ("Converted", "Closed")
         AND Full_Opportunity_ID__c IS NOT NULL
        THEN Full_Opportunity_ID__c END) AS sql_to_sqo_denominator,
    COUNT(DISTINCT CASE 
        WHEN is_sql = 1 
         AND is_sqo = 1 
         AND Full_Opportunity_ID__c IS NOT NULL
        THEN Full_Opportunity_ID__c END) AS sql_to_sqo_numerator,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS sqo_denominator,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS sqo_to_signed_numerator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_denominator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND is_joined = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_to_joined_numerator
  FROM base
  GROUP BY 1
),
tags AS (
  SELECT
    Experimentation_Tag_Raw__c,
    ARRAY_AGG(DISTINCT tag) AS Experimentation_Tags
  FROM base
  LEFT JOIN UNNEST(IFNULL(Experimentation_Tag_List, [])) AS tag
  GROUP BY 1
),
combined AS (
  SELECT
    m.*,
    t.Experimentation_Tags
  FROM metrics m
  LEFT JOIN tags t
    ON m.Experimentation_Tag_Raw__c = t.Experimentation_Tag_Raw__c
)
SELECT
  c.Experimentation_Tag_Raw__c,
  tag AS Experimentation_Tag__c,
  c.Experimentation_Tags AS Experimentation_Tag_List,
  c.total_prospects,
  c.contacting,
  c.mql,
  c.sql,
  c.sqo,
  c.signed,
  c.joined,
  c.signed_aum,
  SAFE_DIVIDE(c.contacted_to_mql_numerator, c.contacted_denominator) AS contacted_to_mql_rate,
  SAFE_DIVIDE(c.mql_to_sql_numerator, c.mql_denominator) AS mql_to_sql_rate,
  SAFE_DIVIDE(c.sql_to_sqo_numerator, c.sql_to_sqo_denominator) AS sql_to_sqo_rate,
  SAFE_DIVIDE(c.sqo_to_signed_numerator, c.sqo_denominator) AS sqo_to_signed_rate,
  SAFE_DIVIDE(c.signed_to_joined_numerator, c.signed_denominator) AS signed_to_joined_rate
FROM combined c
LEFT JOIN UNNEST(
  IF(ARRAY_LENGTH(c.Experimentation_Tags) = 0, [CAST(NULL AS STRING)], c.Experimentation_Tags)
) AS tag;
