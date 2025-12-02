Here is a detailed, step-by-step guide to implement "Option 2" using BigQuery's `ML.GENERATE_TEXT` function to create a filter-responsive, structured AI analysis for your "Funnel Performance" dashboard.

This solution is powerful because it uses BigQuery to pre-aggregate your filtered data, feeds that data to Gemini as structured JSON, and asks it to provide a specific, well-formatted analysis, which then appears directly in your Looker Studio report.

## Project Configuration
- **Project ID:** `savvy-gtm-analytics`
- **Dataset:** `savvy_analytics`
- **Location:** `northamerica-northeast2`
- **View:** `vw_actual_vs_forecast_by_source`
- **Key Fields:** `date_day`, `Channel_Grouping_Name`, `Original_source`, `sql_actual`, `sqo_actual`, `joined_actual`, `sql_forecast`, `sqo_forecast`, `joined_forecast`

-----

### \#\# Step 1: BQML Prerequisite (One-Time Setup)

Before you can use `ML.GENERATE_TEXT`, you must have a Gemini model connected to your BigQuery project.

1.  **Enable APIs:** Ensure the "Vertex AI API" is enabled in your Google Cloud project (`savvy-gtm-analytics`).
2.  **Create a Connection:** You need to create a BQML connection to Vertex AI. Run this query in the BigQuery UI:
    ```sql
    CREATE OR REPLACE CONNECTION `savvy-gtm-analytics.savvy_analytics.vertex_ai_connection`
      OPTIONS(cloud_resource_name = 'projects/savvy-gtm-analytics/locations/northamerica-northeast2');
    ```
    *(Note: You will need to grant specific IAM roles to the connection's service account. BigQuery will provide the service account email and guide you through granting the "Vertex AI User" role.)*
3.  **Create the Model:** Once the connection is made, create a model that points to Gemini:
    ```sql
    CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_analytics.gemini_pro_model`
      REMOTE WITH CONNECTION `savvy-gtm-analytics.savvy_analytics.vertex_ai_connection`
      OPTIONS(endpoint = 'gemini-pro');
    ```

-----

### \#\# Step 2: Create a New "Custom Query" Data Source

In your Looker Studio report, you will add a *new* data source. This query will be the "engine" for your AI analysis.

1.  In Looker Studio, go to **Resource \> Manage added data sources**.
2.  Click **ADD A DATA SOURCE** and select **BigQuery**.
3.  Select your project (`savvy-gtm-analytics`), but instead of choosing a table, click **CUSTOM QUERY**.

-----

### \#\# Step 3: Write the AI-Powered Custom Query

This is the most important part. Copy and paste the query below into the "Custom Query" box. This query is designed to:

1.  Define parameters for your Looker Studio filters.
2.  [cite\_start]Query your `vw_actual_vs_forecast_by_source` view[cite: 45], applying those filters.
3.  Aggregate the data into two JSON objects: one for totals and one for the source-level breakdown.
4.  Pass all this data inside a structured prompt to the Gemini model.

[cite\_start]*(**Note:** This query is based on your `vw_actual_vs_forecast_by_source` view [cite: 45] [cite\_start]and is designed to respond to the `Date`, `Channel`, and `Source` filters[cite: 18, 19, 20]. [cite\_start]Your `StageName` filter likely only applies to the bottom SQOs table[cite: 40], as your main performance view doesn't aggregate by `StageName`.)*

```sql
-- ##################################################################
-- ## STEP 3: YOUR CUSTOM QUERY FOR LOOKER STUDIO
-- ##################################################################

-- ======= 1. DEFINE FILTER PARAMETERS =======
-- These will link to your Looker Studio controls.
-- Default values include all channels - adjust based on your actual Channel_Grouping_Name values
DECLARE param_channel ARRAY<STRING> DEFAULT ['Outbound', 'Inbound', 'Ecosystem', 'Other', 'Unknown'];
DECLARE param_source ARRAY<STRING> DEFAULT NULL; -- NULL = All Sources by default

-- ======= 2. CALL THE GEMINI MODEL =======
SELECT
  ml_generate_text_result AS gemini_analysis
FROM
  ML.GENERATE_TEXT(
    MODEL `savvy-gtm-analytics.savvy_analytics.gemini_pro_model`, -- ⭐️ Your Gemini model (created in Step 1)
    (
      -- ======= 3. BUILD THE PROMPT WITH SUBQUERIES =======
      -- This subquery fetches filtered, aggregated data and builds the prompt
      SELECT
        CONCAT(
          'You are a senior business analyst. Your goal is to provide a concise, structured summary of funnel performance based on the data provided.',
          'The data is for the period between ', CAST(@DS_START_DATE AS STRING), ' and ', CAST(@DS_END_DATE AS STRING), '.\n\n',
          'Use the following JSON data to perform your analysis:\n',
          
          '---DATA START---\n',
          'Overall Performance Totals:\n',
          (
            -- Subquery 1: Get total performance
            SELECT
              TO_JSON_STRING(
                STRUCT(
                  SUM(sql_actual) AS total_sql_actual,
                  SUM(sql_forecast) AS total_sql_forecast,
                  SUM(sqo_actual) AS total_sqo_actual,
                  SUM(sqo_forecast) AS total_sqo_forecast,
                  SUM(joined_actual) AS total_joined_actual,
                  SUM(joined_forecast) AS total_joined_forecast
                )
              )
            FROM
              `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source` -- ⭐️ Your actual vs forecast view
            WHERE
              date_day BETWEEN @DS_START_DATE AND @DS_END_DATE
              AND (Channel_Grouping_Name IN UNNEST(param_channel))
              AND (param_source IS NULL OR Original_source IN UNNEST(param_source))
          ),
          '\n\nSource-Level Breakdown:\n',
          (
            -- Subquery 2: Get top 10 sources
            SELECT
              TO_JSON_STRING(
                ARRAY_AGG(
                  STRUCT(
                    Original_source,
                    Channel_Grouping_Name,
                    SUM(sql_actual) AS sql_actual,
                    SUM(sql_forecast) AS sql_forecast,
                    SUM(sqo_actual) AS sqo_actual,
                    SUM(sqo_forecast) AS sqo_forecast,
                    SUM(joined_actual) AS joined_actual,
                    SUM(joined_forecast) AS joined_forecast,
                    -- Calculate variance to help the AI
                    SUM(sqo_actual) - SUM(sqo_forecast) AS sqo_variance
                  )
                )
              )
            FROM
              `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source` -- ⭐️ Your actual vs forecast view
            WHERE
              date_day BETWEEN @DS_START_DATE AND @DS_END_DATE
              AND (Channel_Grouping_Name IN UNNEST(param_channel))
              AND (param_source IS NULL OR Original_source IN UNNEST(param_source))
            GROUP BY
              Original_source,
              Channel_Grouping_Name
            ORDER BY
              sqo_variance DESC
            LIMIT 10
          ),
          '\n---DATA END---\n\n',
          
          '---YOUR TASK---\n',
          'Provide your analysis in MARKDOWN format. The analysis must be structured with the following sections:',
          '1.  **Executive Summary:** A 2-3 sentence overview of performance vs. forecast for the key metrics (SQL, SQO, Joined).',
          '2.  **Key Metric Performance:** A bulleted list, one for each metric (SQL, SQO, Joined), stating the "Actual vs. Forecast" and the variance (e.g., "SQL: 120 vs 100 (20% above forecast)").',
          '3.  **Source-Level Insights:** Based on the source breakdown, identify the TOP 1-2 performing sources (highest positive variance) and the BOTTOM 1-2 under-performing sources (highest negative variance).',
          '4.  **Strategic Recommendation:** Based on the data, provide one brief, actionable recommendation.'
        ) AS prompt
      FROM
        -- This dummy table ensures the subqueries run
        (SELECT 1)
    ),
    -- Model parameters
    STRUCT(
      0.2 AS temperature,
      1024 AS max_output_tokens
    )
  );

```

-----

### \#\# Step 4: Configure the Data Source Parameters

After you paste the query, Looker Studio will see the parameters you defined.

1.  **Enable Date Parameters:** Find the `@DS_START_DATE` and `@DS_END_DATE` parameters. Ensure "Allow 'Date Range' parameter to be modified in reports" is **checked**.
2.  **Enable Filter Parameters:**
      * Find `param_channel`. Check **"Allow 'param\_channel' to be modified in reports"**.
      * Find `param_source`. Check **"Allow 'param\_source' to be modified in reports"**.

Click **ADD** to add this new data source to your report.

-----

### \#\# Step 5: Connect Your Dashboard Filters

Now, you must link your existing dashboard filter controls to this new data source.

1.  **Date Range:** Your main Date Range filter control will now *automatically* control this new data source because you enabled the `@DS_...` parameters.
2.  **Channel Filter:**
      * Click on your "Channel" dropdown filter.
      * In the **Properties** panel, find the **Data** tab.
      * For the "Control field," select the `Channel_Grouping_Name` field *from your main data source* (`savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`).
      * Now, click **"Add a filter"** under the "Filters" section (this is the key).
      * Select your new custom query data source (e.g., "Custom Query - Gemini Analysis").
      * In the filter setup, choose **"Select a field" \> `param_channel`**.
      * Set the condition to **"In"**.
      * This links your filter to the query parameter.
3.  **Source Filter:**
      * Repeat the exact same process for your "Source" dropdown filter, but this time, map it to the `param_source` parameter in your new data source.

-----

### \#\# Step 6: Add the AI Analysis to Your Dashboard

1.  Go to **Insert \> Scorecard**.
2.  Place the new scorecard at the top of your dashboard.
3.  In its **Properties** panel, set the **Data source** to your new "Custom Query - Gemini Analysis" source.
4.  Set the **Metric** to `gemini_analysis`.
5.  Go to the **Style** tab for the scorecard.
      * Under "Primary Metric," set the font size smaller (e.g., 12 or 14).
      * Under "Background and Border," remove any shadows and set the background to transparent or match your dashboard.
      * **Crucially:** Under "Text," change the alignment to **Left** and **Top**.
6.  Resize the scorecard box to be large enough to hold the text (e.g., 400px wide by 300px tall).

You're done\! Now, when you change your `Date`, `Channel`, or `Source` filters, the scorecard will briefly show "loading," BigQuery will re-run the entire query, Gemini will generate a new analysis based on the *filtered* data, and the text will update in your dashboard.

-----

## Additional Setup Notes

### Verifying Channel Values
Before setting up the filters, you may want to verify the actual `Channel_Grouping_Name` values in your view. You can run this query in BigQuery:

```sql
SELECT DISTINCT Channel_Grouping_Name 
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
ORDER BY Channel_Grouping_Name;
```

Update the `param_channel` default array in Step 3 if your actual channel values differ from the defaults.

### Testing the Model Connection
After creating the model in Step 1, test it with a simple query:

```sql
SELECT ml_generate_text_result
FROM ML.GENERATE_TEXT(
  MODEL `savvy-gtm-analytics.savvy_analytics.gemini_pro_model`,
  (SELECT 'Hello, this is a test.' AS prompt),
  STRUCT(0.2 AS temperature, 100 AS max_output_tokens)
);
```

If this returns a response, your model is working correctly.

### Troubleshooting
- **Connection errors:** Ensure the Vertex AI API is enabled and the service account has the "Vertex AI User" role
- **Model not found:** Verify the model name matches exactly: `savvy-gtm-analytics.savvy_analytics.gemini_pro_model`
- **Query timeout:** The query may take 10-30 seconds depending on data volume. Consider adding date range limits if needed
- **No data returned:** Check that your date range and filter parameters match actual data in `vw_actual_vs_forecast_by_source`