#1a. O'Hare vs Midway, same destination cities (last 4 quarters)
WITH city_fares AS (
  SELECT
    chicago_airport,
    dest_city,
    SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day) AS weighted_avg_fare,
    SUM(passengers_per_day) / 4 AS avg_daily_passengers,
    COUNT(*) AS num_rows
  FROM airfare.mart_chicago_airports
  WHERE year * 10 + quarter >= 20252 AND passengers_per_day > 0
  GROUP BY chicago_airport, dest_city
),
side_by_side AS (
  SELECT
    dest_city,
    MAX(CASE WHEN chicago_airport = 'ORD' THEN weighted_avg_fare END) AS ord_fare,
    MAX(CASE WHEN chicago_airport = 'MDW' THEN weighted_avg_fare END) AS mdw_fare
FROM city_fares
GROUP BY dest_city
),
city_diffs AS (
  SELECT 
    dest_city,
    ord_fare - mdw_fare AS fare_diff,
    (ord_fare - mdw_fare) / mdw_fare AS pct_diff
  FROM side_by_side
  WHERE mdw_fare IS NOT NULL
)
SELECT
  COUNT(dest_city) AS num_cities,
  SUM(CASE WHEN fare_diff > 0 THEN 1 ELSE 0 END) AS ord_higher,
  ROUND(APPROX_QUANTILES(fare_diff, 2)[OFFSET(1)], 2) AS median_fare_diff,
  ROUND(APPROX_QUANTILES(pct_diff, 2)[OFFSET(1)] * 100, 1) AS median_pct_diff,
FROM city_diffs;

#1b. Robustness: cities where both airports have all 4 quarters
WITH city_fares AS (
  SELECT
    chicago_airport,
    dest_city,
    SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day) AS weighted_avg_fare,
    SUM(passengers_per_day) / 4 AS avg_daily_passengers,
    COUNT(*) AS num_rows,
    COUNT(DISTINCT year * 10 + quarter) AS quarters_present
  FROM airfare.mart_chicago_airports
  WHERE year * 10 + quarter >= 20252 AND passengers_per_day > 0
  GROUP BY chicago_airport, dest_city
),
side_by_side AS (
  SELECT
    dest_city,
    MAX(CASE WHEN chicago_airport = 'ORD' THEN weighted_avg_fare END) AS ord_fare,
    MAX(CASE WHEN chicago_airport = 'MDW' THEN weighted_avg_fare END) AS mdw_fare,
    MAX(CASE WHEN chicago_airport = 'ORD' THEN quarters_present END) AS ord_quarters,
    MAX(CASE WHEN chicago_airport = 'MDW' THEN quarters_present END) AS mdw_quarters
FROM city_fares
GROUP BY dest_city
),
city_diffs AS (
  SELECT 
    dest_city,
    ord_fare - mdw_fare AS fare_diff,
    (ord_fare - mdw_fare) / mdw_fare AS pct_diff
  FROM side_by_side
  WHERE mdw_fare IS NOT NULL AND ord_quarters = 4 AND mdw_quarters = 4
)
SELECT
  COUNT(dest_city) AS num_cities,
  SUM(CASE WHEN fare_diff > 0 THEN 1 ELSE 0 END) AS ord_higher,
  ROUND(APPROX_QUANTILES(fare_diff, 2)[OFFSET(1)], 2) AS median_fare_diff,
  ROUND(APPROX_QUANTILES(pct_diff, 2)[OFFSET(1)] * 100, 1) AS median_pct_diff,
FROM city_diffs;

#2a. Chicago vs national, median price gap (full-year routes)
WITH route_groups AS (
  SELECT
    *,
    CASE
      WHEN city_1 = 'Chicago, IL' OR city_2 = 'Chicago, IL' THEN 'Chicago'
      ELSE 'Other'
    END AS market
  FROM airfare.mart_route_benchmark
)
SELECT 
  market,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM route_groups
WHERE quarters_present = 4
GROUP BY market;

#2b. Chicago price positions (all routes)
WITH route_groups AS (
  SELECT
    *,
    CASE
      WHEN city_1 = 'Chicago, IL' OR city_2 = 'Chicago, IL' THEN 'Chicago'
      ELSE 'Other'
    END AS market
  FROM airfare.mart_route_benchmark
)
SELECT 
  price_position,
  COUNT(*) AS num_routes
FROM route_groups
WHERE market = 'Chicago'
GROUP BY price_position;

#2c. Chicago by competition group (full-year routes)
WITH route_groups AS (
  SELECT
    *,
    CASE
      WHEN city_1 = 'Chicago, IL' OR city_2 = 'Chicago, IL' THEN 'Chicago'
      ELSE 'Other'
    END AS market
  FROM airfare.mart_route_benchmark
)
SELECT 
  competition_group,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM route_groups
WHERE market = 'Chicago' AND quarters_present = 4
GROUP BY competition_group;

#2d. Chicago by carrier type (full-year routes)
WITH route_groups AS (
  SELECT
    *,
    CASE
      WHEN city_1 = 'Chicago, IL' OR city_2 = 'Chicago, IL' THEN 'Chicago'
      ELSE 'Other'
    END AS market
  FROM airfare.mart_route_benchmark
)
SELECT
  largest_carrier_type,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM route_groups
WHERE market = 'Chicago' AND quarters_present = 4
GROUP BY largest_carrier_type;

#2e. Chicago by carrier name (full-year routes)
WITH route_groups AS (
  SELECT
    *,
    CASE
      WHEN city_1 = 'Chicago, IL' OR city_2 = 'Chicago, IL' THEN 'Chicago'
      ELSE 'Other'
    END AS market
  FROM airfare.mart_route_benchmark
)
SELECT
  largest_carrier_name,
  ROUND(APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] * 100, 1) AS median_gap_pct,
  COUNT(*) AS num_routes
FROM route_groups
WHERE market = 'Chicago' AND quarters_present = 4
GROUP BY largest_carrier_name;
