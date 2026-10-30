#Reconciliation: totals to compare against the Excel workbook. All 6 matched.
#Route quarter checks
SELECT 
  COUNT(*) AS row_count,
  SUM(passengers_per_day) AS total_passengers_per_day,
  SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day) AS weighted_avg_fare
FROM airfare.int_route_quarter;

#Benchmark checks
SELECT
  COUNT(*) AS row_count,
  SUM(CASE WHEN price_position = 'Above benchmark' THEN 1 ELSE 0 END) AS above_count
FROM airfare.mart_route_benchmark;

#Chicago checks
SELECT COUNT(*) AS row_count
FROM airfare.mart_chicago_airports;
