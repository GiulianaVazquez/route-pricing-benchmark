#1a. Median fare per mile by band
SELECT
  distance_band,
  ROUND(APPROX_QUANTILES(fare_per_mile, 2)[OFFSET(1)], 3) AS median_fpm,
  COUNT(*) AS row_count
FROM airfare.int_route_quarter
GROUP BY distance_band
ORDER BY distance_band;

#1b. Highest fare per mile overall
SELECT 
  year, 
  quarter, 
  route, 
  distance_miles, 
  avg_fare, 
  fare_per_mile, 
  distance_band
FROM airfare.int_route_quarter
ORDER BY fare_per_mile DESC
LIMIT 10;

#1c. Portland to Seattle (benchmark check)
SELECT 
  route, 
  ROUND(avg_distance_miles, 0) AS distance,
  ROUND(weighted_avg_fare, 2) AS actual_fare,
  ROUND(expected_fare, 2) AS expected_fare,
  ROUND(price_gap_pct * 100, 1) AS gap_pct,
  competition_group,
  quarters_present
FROM airfare.mart_route_benchmark
WHERE route = 'Portland, OR to Seattle, WA';

#1d. Top 10 above benchmark (full-year routes)
SELECT
  route,
  ROUND(avg_distance_miles, 0) AS distance,
  ROUND(weighted_avg_fare, 2) AS actual_fare,
  ROUND(expected_fare, 2) AS expected_fare,
  ROUND(price_gap_pct * 100, 1) AS gap_pct,
  competition_group,
  largest_carrier_name,
  quarters_present
FROM airfare.mart_route_benchmark
WHERE price_position != 'Limited data'
ORDER BY price_gap_pct DESC
LIMIT 10;

#1e. Bottom 10 below benchmark (full-year routes)
SELECT
  route,
  ROUND(avg_distance_miles, 0) AS distance,
  ROUND(weighted_avg_fare, 2) AS actual_fare,
  ROUND(expected_fare, 2) AS expected_fare,
  ROUND(price_gap_pct * 100, 1) AS gap_pct,
  competition_group,
  largest_carrier_name,
  quarters_present
FROM airfare.mart_route_benchmark
WHERE price_position != 'Limited data'
ORDER BY price_gap_pct ASC
LIMIT 10;

#2a. Dominated vs competitive fares by band
SELECT
  distance_band,
  competition_group,
  COUNT(*) AS row_count,
  ROUND(SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day), 2) AS weighted_avg_fare
FROM airfare.int_route_quarter
GROUP BY distance_band, competition_group
ORDER BY distance_band, competition_group;

#2b. Carrier type vs competition (full-year routes)
SELECT
  competition_group,
  largest_carrier_type,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM airfare.mart_route_benchmark
WHERE quarters_present = 4
GROUP BY competition_group, largest_carrier_type
ORDER BY competition_group, largest_carrier_type;

#2c. Carrier type vs competition by band (full-year routes)
SELECT
  competition_group,
  largest_carrier_type,
  distance_band,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM airfare.mart_route_benchmark
WHERE quarters_present = 4
GROUP BY competition_group, largest_carrier_type, distance_band
ORDER BY competition_group, largest_carrier_type, distance_band;

#3a. Low-cost present vs not, by band
SELECT
  distance_band,
  lcc_group,
  COUNT(*) AS row_count,
  ROUND(SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day), 2) AS weighted_avg_fare
FROM airfare.int_route_quarter
GROUP BY distance_band, lcc_group
ORDER BY distance_band, lcc_group;

#3b. Robustness: Southwest and JetBlue as legacy
SELECT
  distance_band,
  CASE
    WHEN lcc_group = 'Low-cost present' AND low_fare_carrier NOT IN ('WN', 'B6') THEN 'Low-cost present'
    ELSE 'No low-cost'
  END AS lcc_group_strict,
  COUNT(*) AS row_count,
  ROUND(SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day), 2) AS weighted_avg_fare
FROM airfare.int_route_quarter
GROUP BY distance_band, lcc_group_strict
ORDER BY distance_band, lcc_group_strict;
