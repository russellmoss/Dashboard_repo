CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_experimentation_tag_performance` AS
WITH base AS (
  SELECT
    primary_key,
    COALESCE(Experimentation_Tag__c, "Unspecified") AS Experimentation_Tag__c,
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
    SQL_conversion_status,
    StageName,
    Disposition__c
  FROM `savvy-gtm-analytics.savvy_analytics.vw_experimentation_tags`
),
tag_metrics AS (
  SELECT
    Experimentation_Tag__c,
    STRING_AGG(DISTINCT Experimentation_Tag_Raw__c, ' | ') AS Experimentation_Tag_Raw__c,
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
    -- UPDATED: Only include MQLs with final outcome (became SQL or has Disposition__c) - excludes open MQLs
    SUM(CASE 
      WHEN is_mql = 1 
        AND (is_sql = 1 OR Disposition__c IS NOT NULL)
      THEN 1 
      ELSE 0 
    END) AS mql_denominator,
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
    -- UPDATED: Only include SQOs with final outcome (joined or closed lost) - excludes open SQOs
    COUNT(DISTINCT CASE 
      WHEN is_sqo = 1 
        AND Full_Opportunity_ID__c IS NOT NULL
        AND (is_joined = 1 OR StageName = 'Closed Lost')
      THEN Full_Opportunity_ID__c 
    END) AS sqo_denominator,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS sqo_to_signed_numerator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_denominator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND is_joined = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_to_joined_numerator
  FROM base
  GROUP BY 1
),
tag_lists AS (
  SELECT
    Experimentation_Tag__c,
    ARRAY_AGG(DISTINCT tag ORDER BY tag) AS Experimentation_Tag_List
  FROM base
  LEFT JOIN UNNEST(IFNULL(Experimentation_Tag_List, [])) AS tag
  GROUP BY 1
),
tag_level AS (
  SELECT
    'tag' AS row_type,
    m.Experimentation_Tag__c,
    m.Experimentation_Tag_Raw__c,
    l.Experimentation_Tag_List,
    m.total_prospects,
    m.contacting,
    m.mql,
    m.sql,
    m.sqo,
    m.signed,
    m.joined,
    m.signed_aum,
    SAFE_DIVIDE(m.contacted_to_mql_numerator, m.contacted_denominator) AS contacted_to_mql_rate,
    SAFE_DIVIDE(m.mql_to_sql_numerator, m.mql_denominator) AS mql_to_sql_rate,
    SAFE_DIVIDE(m.sql_to_sqo_numerator, m.sql_to_sqo_denominator) AS sql_to_sqo_rate,
    SAFE_DIVIDE(m.sqo_to_signed_numerator, m.sqo_denominator) AS sqo_to_signed_rate,
    SAFE_DIVIDE(m.signed_to_joined_numerator, m.signed_denominator) AS signed_to_joined_rate
  FROM tag_metrics m
  LEFT JOIN tag_lists l
    ON m.Experimentation_Tag__c = l.Experimentation_Tag__c
),
combination_base AS (
  SELECT
    *
  FROM base
  WHERE Experimentation_Tag_Raw__c IS NOT NULL AND Experimentation_Tag_Raw__c != ''
),
combination_metrics AS (
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
    -- UPDATED: Only include MQLs with final outcome (became SQL or has Disposition__c) - excludes open MQLs
    SUM(CASE 
      WHEN is_mql = 1 
        AND (is_sql = 1 OR Disposition__c IS NOT NULL)
      THEN 1 
      ELSE 0 
    END) AS mql_denominator,
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
    -- UPDATED: Only include SQOs with final outcome (joined or closed lost) - excludes open SQOs
    COUNT(DISTINCT CASE 
      WHEN is_sqo = 1 
        AND Full_Opportunity_ID__c IS NOT NULL
        AND (is_joined = 1 OR StageName = 'Closed Lost')
      THEN Full_Opportunity_ID__c 
    END) AS sqo_denominator,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS sqo_to_signed_numerator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_denominator,
    COUNT(DISTINCT CASE WHEN is_signed = 1 AND is_joined = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS signed_to_joined_numerator
  FROM combination_base
  GROUP BY 1
),
combination_tags AS (
  SELECT
    Experimentation_Tag_Raw__c,
    ARRAY_AGG(DISTINCT tag ORDER BY tag) AS Experimentation_Tag_List
  FROM combination_base
  LEFT JOIN UNNEST(IFNULL(Experimentation_Tag_List, [])) AS tag
  GROUP BY 1
),
combination_level AS (
  SELECT
    'combination' AS row_type,
    tag AS Experimentation_Tag__c,
    m.Experimentation_Tag_Raw__c,
    t.Experimentation_Tag_List,
    m.total_prospects,
    m.contacting,
    m.mql,
    m.sql,
    m.sqo,
    m.signed,
    m.joined,
    m.signed_aum,
    SAFE_DIVIDE(m.contacted_to_mql_numerator, m.contacted_denominator) AS contacted_to_mql_rate,
    SAFE_DIVIDE(m.mql_to_sql_numerator, m.mql_denominator) AS mql_to_sql_rate,
    SAFE_DIVIDE(m.sql_to_sqo_numerator, m.sql_to_sqo_denominator) AS sql_to_sqo_rate,
    SAFE_DIVIDE(m.sqo_to_signed_numerator, m.sqo_denominator) AS sqo_to_signed_rate,
    SAFE_DIVIDE(m.signed_to_joined_numerator, m.signed_denominator) AS signed_to_joined_rate
  FROM combination_metrics m
  LEFT JOIN combination_tags t
    ON m.Experimentation_Tag_Raw__c = t.Experimentation_Tag_Raw__c
  LEFT JOIN UNNEST(
    IF(ARRAY_LENGTH(t.Experimentation_Tag_List) = 0, [CAST(NULL AS STRING)], t.Experimentation_Tag_List)
  ) AS tag
),
all_rows AS (
  SELECT * FROM tag_level
  UNION ALL
  SELECT * FROM combination_level
)
SELECT * FROM all_rows;
