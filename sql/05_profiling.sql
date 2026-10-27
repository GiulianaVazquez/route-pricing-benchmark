#1. Rows per distance band
WITH routes AS (
  SELECT
    CASE
      WHEN distance_miles < 500 THEN '1. Under 500'
      WHEN distance_miles < 1000 THEN '2. 500-999'
      WHEN distance_miles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band
  FROM airfare.stg_table1
)
SELECT 
  COUNT(*) AS row_count, 
  distance_band
FROM routes
GROUP BY distance_band
ORDER BY distance_band;

#2. Fare per mile by band
WITH routes AS (
  SELECT
    avg_fare / distance_miles AS fare_per_mile, 
    CASE
      WHEN distance_miles < 500 THEN '1. Under 500'
      WHEN distance_miles < 1000 THEN '2. 500-999'
      WHEN distance_miles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band
  FROM airfare.stg_table1
)
SELECT distance_band,
  ROUND(AVG(fare_per_mile), 3) AS avg_fpm,
  ROUND(MIN(fare_per_mile), 3) AS min_fpm, 
  ROUND(APPROX_QUANTILES(fare_per_mile, 4)[OFFSET(1)], 3) AS p25_fpm,
  ROUND(APPROX_QUANTILES(fare_per_mile, 4)[OFFSET(2)], 3)	AS median_fpm,
  ROUND(APPROX_QUANTILES(fare_per_mile, 4)[OFFSET(3)], 3)	AS p75_fpm,
  ROUND(MAX(fare_per_mile), 3) AS max_fpm
FROM routes
GROUP BY distance_band
ORDER BY distance_band;

#3a. Highest fare per mile
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
)
SELECT *
FROM routes
ORDER BY fare_per_mile DESC
LIMIT 10;

#3b. Lowest fare per mile
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
)
SELECT *
FROM routes
ORDER BY fare_per_mile ASC
LIMIT 10;

#4a. Table 1a null count
SELECT COUNT(*) as null_count
FROM airfare.stg_table1a
WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL;

#4b. Null rows (check passengers)
SELECT *
FROM airfare.stg_table1a
WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL;

#4c. Nulls by quarter
SELECT 
  COUNT(*) AS null_count,
  year,
  quarter
FROM airfare.stg_table1a
WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL
GROUP BY year, quarter
ORDER BY year DESC, quarter DESC;

#4d. Nulls by airport pair
SELECT 
  COUNT(*) AS null_count,
  airport_code_1,
  airport_code_2
FROM airfare.stg_table1a
WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL
GROUP BY airport_code_1, airport_code_2
ORDER BY null_count DESC;

#4e. Nulls by airport (both sides, UNION ALL)
WITH airports AS (
  SELECT airport_code_1 AS airport_code
  FROM airfare.stg_table1a 
  WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL
  UNION ALL
  SELECT airport_code_2 AS airport_code
  FROM airfare.stg_table1a
  WHERE largest_carrier_fare IS NULL OR largest_carrier IS NULL
)
SELECT 
  airport_code,
  COUNT(*) as null_count
FROM airports
GROUP BY airport_code
ORDER BY null_count DESC;
