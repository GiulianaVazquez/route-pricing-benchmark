# Benchmark v1 (rejected): median fare per mile × distance
# Made short routes look overpriced (+102% under 250 miles, −11% at 350 to 499)
# Replaced by the regression in 08_mart_route_benchmark
WITH route_level AS (
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
    *,
    weighted_avg_fare / avg_distance_miles AS fare_per_mile,
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
  FROM route_level
),
peer_groups AS (
  SELECT
    distance_band,
    competition_group,
    APPROX_QUANTILES(fare_per_mile, 2)[OFFSET(1)] AS median_fpm,
    COUNT(route) AS num_routes
  FROM route_calcs
  GROUP BY distance_band, competition_group
),
route_benchmark AS (
  SELECT
    r.*,
    p.median_fpm,
    p.median_fpm * r.avg_distance_miles AS expected_fare
  FROM peer_groups AS p
  JOIN route_calcs AS r
  ON r.distance_band = p.distance_band 
  AND r.competition_group = p.competition_group
),
route_gaps AS (
  SELECT *,
    (weighted_avg_fare - expected_fare) / expected_fare AS price_gap_pct
  FROM route_benchmark
)
SELECT 
  COUNT(*) AS num_routes,
  APPROX_QUANTILES(price_gap_pct, 2)[OFFSET(1)] AS median_gap,
  CASE
    WHEN avg_distance_miles < 250 THEN '1. Under 250'
    WHEN avg_distance_miles < 349 THEN '2. 250-349'
    WHEN avg_distance_miles < 499 THEN '3. 350-499'
    ELSE '4. check'
  END AS distance_bucket
FROM route_gaps
WHERE avg_distance_miles < 500 
GROUP BY distance_bucket
ORDER BY distance_bucket;
