# File Cleanup Script for Big Query Forecasting Project
# Date: October 30, 2025

# Create archive directory
New-Item -ItemType Directory -Path "archive" -Force

# Files to archive (obsolete/duplicate development history)
$filesToArchive = @(
    # Backtest development files
    "BACKTEST_ERROR_FIXED.md",
    "BACKTEST_FINAL_FIX.md",
    "BACKTEST_FINAL_QUOTE_FIX.md",
    "BACKTEST_NEXT_STEPS.md",
    "BACKTEST_QUICK_CHECK.sql",
    "BACKTEST_QUICK_REFERENCE.md",
    "BACKTEST_RESUME_GUIDE.md",
    "BACKTEST_SIMPLE_FIX.md",
    "BACKTEST_TEMP_TABLE_FIX.md",
    "BACKTEST_VALIDATION_GUIDE.md",
    "REACTIVE_BACKTEST_FIX_APPLIED.md",
    "REACTIVE_BACKTEST_FIXED_FINAL.md",
    "REACTIVE_BACKTEST_SUCCESS.md",
    "REACTIVE_MODEL_BACKTEST_GUIDE.md",
    
    # Old backtest SQL (replaced by BACKTEST_REACTIVE_180DAY.sql)
    "BACKTEST_FIXED.sql",
    
    # Trailing rates fix files
    "trailing_rates_FINAL_FIX.sql",
    "trailing_rates_fixed_correct_dates.sql",
    "trailing_rates_fixed.sql",
    "trailing_rates_PROD_FIXED.sql",
    "rebuild_trailing_rates_correct.sql",
    
    # Forecast development files (replaced by HYBRID_FORECAST_FIXED.sql)
    "complete_forecast_insert_hybrid.sql",
    "complete_forecast_insert.sql",
    
    # Heuristic view fix (now in Views/)
    "vw_heuristic_forecast_FIXED.sql",
    
    # Multiple summary/development files
    "ARIMA_INVESTIGATION.md",
    "ARIMA_PLAN_UPDATE_SUMMARY.md",
    "CONFIDENCE_SUMMARY.md",
    "Conversion_Rate_Calculation_Logic.md",
    "CONVERSION_RATE_FIX.md",
    "DATA_ATTRIBUTION_BUG_FOUND.md",
    "DATA_ATTRIBUTION_FIX_COMPLETE.md",
    "FINAL_CONFIRMATION.md",
    "FINAL_FORECAST_SUMMARY.md",
    "FINAL_IMPLEMENTATION_SUMMARY.md",
    "FINAL_RECOMMENDATION.md",
    "FINAL_SQO_DECISION.md",
    "FINAL_SUMMARY.md",
    "FORECAST_FIXED_SUMMARY.md",
    "FORECAST_PIPELINE_ISSUE.md",
    "FORECAST_REGENERATED_FINAL.md",
    "FORECAST_STATUS_SUMMARY.md",
    "Forecasting_Implementation_Summary.md",
    "HYBRID_FORECAST_COMPLETE.md",
    "IMPLEMENTATION_COMPLETE_SUMMARY.md",
    "MCP_Setup_Guide.md",
    "MOdel remediation plan v2.md",
    "PRODUCTION_FORECAST_LAUNCHED.md",
    "PROPENSITY_MODEL_FIX_SUMMARY.md",
    "Q4_SQO_FORECAST_AND_CONFIDENCE.md",
    "QUICK_START.md",
    "REACTIVE_MODEL_STATUS.md",
    "SGA_SGM_FILTER_ANALYSIS.md",
    "SQO_FORECAST_DIAGNOSIS.md",
    "STEP_5_1_COMPLETE_SUMMARY.md",
    "STEP_BY_STEP_EXECUTION_GUIDE.md",
    "TRAINING_TABLE_FIX_CONFIRMED.md",
    "ULTRA_REACTIVE_FORECAST_RESULTS.md",
    "WHAT_TO_DO_NEXT.md",
    "BQML_Forecasting_Plan.md"
)

Write-Host "Archiving $($filesToArchive.Count) obsolete files..." -ForegroundColor Yellow

$archivedCount = 0
$notFoundCount = 0

foreach ($file in $filesToArchive) {
    if (Test-Path $file) {
        Move-Item -Path $file -Destination "archive\" -Force
        $archivedCount++
        Write-Host "  Archived: $file" -ForegroundColor Green
    } else {
        $notFoundCount++
        Write-Host "  Not found: $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Archive complete!" -ForegroundColor Cyan
Write-Host "  Archived: $archivedCount files" -ForegroundColor Green
Write-Host "  Not found: $notFoundCount files" -ForegroundColor Gray
Write-Host ""
Write-Host "Files moved to 'archive/' directory for safe keeping." -ForegroundColor Cyan
Write-Host "You can review them there and delete the archive folder if everything looks good." -ForegroundColor Cyan
Write-Host ""
Write-Host "Active files remaining in root:" -ForegroundColor Yellow
Get-ChildItem -Path . -File -Exclude "cleanup.ps1","CLEANUP_PLAN.md","*.zip","*.7z" | Select-Object Name | Format-Table -AutoSize

