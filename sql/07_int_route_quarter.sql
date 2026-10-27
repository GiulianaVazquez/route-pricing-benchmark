#Route quarter view: one row per route per quarter, with bands, flags, and carrier names
CREATE OR REPLACE VIEW airfare.int_route_quarter AS
WITH routes AS (
  SELECT
    year,
    quarter,
    city_id_1,
    city_id_2,
    city_1,
    city_2,
    route,
    distance_miles,
    passengers_per_day,
    avg_fare,
    low_fare_carrier_fare,
    largest_carrier_fare,
    low_fare_carrier,
    largest_carrier,
    low_fare_carrier_share,
    largest_carrier_share,
    avg_fare / distance_miles AS fare_per_mile,
    CASE
      WHEN distance_miles < 500 THEN '1. Under 500'
      WHEN distance_miles < 1000 THEN '2. 500-999'
      WHEN distance_miles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band,
    CASE
      WHEN largest_carrier_share >= 0.5 THEN 'Dominated'
      ELSE 'Competitive'
    END AS competition_group,
  FROM airfare.stg_table1
),
band_stats AS (
  SELECT 
    distance_band,
    APPROX_QUANTILES(fare_per_mile, 4)[OFFSET(1)] AS p25_fpm,
    APPROX_QUANTILES(fare_per_mile, 4)[OFFSET(3)] AS p75_fpm,
  FROM routes
  GROUP BY distance_band
),
fences AS (
  SELECT 
    distance_band,
    p25_fpm,
    p75_fpm,
    (p75_fpm - p25_fpm) AS iqr,
    p25_fpm - (1.5 * (p75_fpm - p25_fpm)) AS lower_bound,
    p75_fpm + (1.5 * (p75_fpm - p25_fpm)) AS upper_bound
FROM band_stats
)
SELECT 
  r.*,
  CASE
    WHEN fare_per_mile > f.upper_bound THEN 'High'
    WHEN fare_per_mile < f.lower_bound THEN 'Low'
    ELSE 'Normal'
  END AS outlier_flag,
  CASE
    WHEN lo.carrier_type = 'Low-cost' AND r.low_fare_carrier_share >= 0.10 THEN 'Low-cost present'
    ELSE 'No low-cost'
  END AS lcc_group,
  lg.carrier_name AS largest_carrier_name,
  lg.carrier_type AS largest_carrier_type,
  lo.carrier_name AS low_fare_carrier_name,
  lo.carrier_type AS low_fare_carrier_type
FROM routes AS r
JOIN fences AS f
  ON r.distance_band = f.distance_band
LEFT JOIN airfare.dim_carrier AS lg
  ON r.largest_carrier = lg.carrier_code
LEFT JOIN airfare.dim_carrier AS lo
  ON r.low_fare_carrier = lo.carrier_code;

#Row count
SELECT COUNT(*) AS row_count
FROM airfare.int_route_quarter;

#Blank carrier names
SELECT COUNT(*) AS row_count
FROM airfare.int_route_quarter
WHERE largest_carrier_name IS NULL;

#Outlier counts (should match 06_outlier_rule)
SELECT 
  COUNT(*) AS row_count,
  outlier_flag
FROM airfare.int_route_quarter
GROUP BY outlier_flag;

#Preview first 10
SELECT *
FROM airfare.int_route_quarter
LIMIT 10;
