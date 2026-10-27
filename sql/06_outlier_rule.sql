#Outlier counts by band (Tukey's fences, 1.5 × IQR)
WITH routes AS (
  SELECT
    year,
    quarter,
    route,
    avg_fare,
    distance_miles,
    avg_fare / distance_miles AS fare_per_mile,
    largest_carrier,
    largest_carrier_share, 
    CASE
      WHEN distance_miles < 500 THEN '1. Under 500'
      WHEN distance_miles < 1000 THEN '2. 500-999'
      WHEN distance_miles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band
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
  r.distance_band,
  CASE
    WHEN fare_per_mile > upper_bound THEN 'High'
    WHEN fare_per_mile < lower_bound THEN 'Low'
    ELSE 'Normal'
  END AS outlier_flag,
  COUNT(*) AS row_count
FROM routes AS r
JOIN fences AS f
  ON r.distance_band = f.distance_band
GROUP BY r.distance_band, outlier_flag
ORDER BY r.distance_band, outlier_flag;
