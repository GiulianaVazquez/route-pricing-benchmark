#Route benchmark view: one row per route, last 4 quarters, with expected fare and price gap
CREATE OR REPLACE VIEW airfare.mart_route_benchmark AS 
WITH latest_carrier AS (
  SELECT 
    largest_carrier_name,
    largest_carrier_type,
    city_id_1, 
    city_id_2
  FROM airfare.int_route_quarter
  WHERE year = 2026 AND quarter = 1
),
route_level AS (
  SELECT
    city_id_1,
    city_id_2,
    city_1,
    city_2,
    route,
    AVG(distance_miles) AS avg_distance_miles,
    AVG(passengers_per_day) AS avg_passengers_per_day,
    AVG(largest_carrier_share) AS avg_largest_carrier_share,
    SUM(avg_fare * passengers_per_day) / SUM(passengers_per_day) AS weighted_avg_fare,
    COUNT(quarter) AS quarters_present,
  FROM airfare.int_route_quarter
  WHERE year * 10 + quarter >= 20252
  GROUP BY city_id_1, city_id_2, city_1, city_2, route
),
route_calcs AS (
  SELECT
    r.*,
    c.largest_carrier_name,
    c.largest_carrier_type,
    r.weighted_avg_fare / r.avg_distance_miles AS fare_per_mile,
  CASE
    WHEN avg_distance_miles < 500 THEN '1. Under 500'
    WHEN avg_distance_miles < 1000 THEN '2. 500-999'
    WHEN avg_distance_miles < 1500 THEN '3. 1000-1499'
    ELSE '4. 1500+'
  END AS distance_band,
  CASE
    WHEN avg_largest_carrier_share >= 0.5 THEN 'Dominated'
    ELSE 'Competitive'
  END AS competition_group,
  FROM route_level AS r
  LEFT JOIN latest_carrier AS c
  ON r.city_id_1 = c.city_id_1
  AND r.city_id_2 = c.city_id_2
),
peer_groups AS (
  SELECT
    distance_band,
    competition_group,
    COVAR_POP(weighted_avg_fare, avg_distance_miles) / VAR_POP(avg_distance_miles) AS slope,
    AVG(weighted_avg_fare) - (COVAR_POP(weighted_avg_fare, avg_distance_miles) / VAR_POP(avg_distance_miles)) * 
      AVG(avg_distance_miles) AS intercept,
    COUNT(route) AS num_routes
  FROM route_calcs
  WHERE quarters_present = 4
  GROUP BY distance_band, competition_group
),
route_benchmark AS (
  SELECT
    r.*,
    p.slope,
    p.intercept,
    p.intercept + p.slope * r.avg_distance_miles AS expected_fare
  FROM peer_groups AS p
  JOIN route_calcs AS r
  ON r.distance_band = p.distance_band 
  AND r.competition_group = p.competition_group
),
route_gaps AS (
  SELECT *,
    (weighted_avg_fare - expected_fare) / expected_fare AS price_gap_pct,
    CASE
      WHEN quarters_present < 4 THEN 'Limited data'
      WHEN (weighted_avg_fare - expected_fare) / expected_fare > 0.15 THEN 'Above benchmark'
      WHEN (weighted_avg_fare - expected_fare) / expected_fare < -0.15 THEN 'Below benchmark'
      ELSE 'In line'
    END AS price_position
  FROM route_benchmark
)
SELECT * 
FROM route_gaps;

#Row count
SELECT COUNT(*) AS row_count
FROM airfare.mart_route_benchmark;

#Peer groups (full-year routes)
SELECT
  distance_band,
  competition_group,
  APPROX_QUANTILES(fare_per_mile, 2)[OFFSET(1)] AS median_fpm,
  COUNT(*) AS num_routes
FROM airfare.mart_route_benchmark
WHERE quarters_present = 4
GROUP BY distance_band, competition_group
ORDER BY distance_band, competition_group;

#Slope and intercept by group
SELECT 
  DISTINCT distance_band, 
  competition_group, 
  slope, 
  intercept
FROM airfare.mart_route_benchmark
ORDER BY distance_band, competition_group;

#Bucket check: distance bias (full-year routes under 500 miles)
SELECT 
  COUNT(*) AS row_count,
  APPROX_QUANTILES(price_gap_pct, 2)[OFFSET(1)] AS median_gap,
  CASE
    WHEN avg_distance_miles < 250 THEN '1. Under 250'
    WHEN avg_distance_miles < 350 THEN '2. 250-349'
    WHEN avg_distance_miles < 500 THEN '3. 350-499'
    ELSE '4. check'
  END AS distance_bucket
FROM airfare.mart_route_benchmark
WHERE avg_distance_miles < 500 AND quarters_present = 4
GROUP BY distance_bucket
ORDER BY distance_bucket;

#Gap percentiles
SELECT 
  APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(0)] AS mg_min,
  APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(1)] AS mg_10th,
  APPROX_QUANTILES(price_gap_pct, 4)[OFFSET(1)] AS mg_25th,
  APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(5)] AS mg_median,
  APPROX_QUANTILES(price_gap_pct, 4)[OFFSET(3)] AS mg_75th,
  APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(9)] AS mg_90th,
  APPROX_QUANTILES(price_gap_pct, 10)[OFFSET(10)] AS mg_max
FROM airfare.mart_route_benchmark;

#Price position counts
SELECT 
  COUNT(*) AS row_count,
  price_position
FROM airfare.mart_route_benchmark
GROUP BY price_position;

#Blank carrier names (full-year routes)
SELECT COUNT(*) AS row_count
FROM airfare.mart_route_benchmark
WHERE quarters_present = 4 AND largest_carrier_name IS NULL;

#Blank carrier names (all routes)
SELECT COUNT(*) AS row_count
FROM airfare.mart_route_benchmark
WHERE largest_carrier_name IS NULL;
