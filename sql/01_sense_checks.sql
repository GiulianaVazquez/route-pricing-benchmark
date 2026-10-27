#1. Row counts per quarter
SELECT 
  Year,
  quarter,
  COUNT(*) AS row_count
FROM airfare.raw_table1
WHERE Year >= 2022
GROUP BY Year, quarter
ORDER BY Year, quarter;

#2. Duplicate routes within a quarter
SELECT 
  Year,
  quarter,
  citymarketid_1,
  citymarketid_2,
  COUNT(*) AS times_listed
FROM airfare.raw_table1
WHERE Year >= 2022
GROUP BY Year, quarter, citymarketid_1, citymarketid_2
HAVING COUNT(*) > 1;

#3. Spot check: Miami to New York, 2026 Q1
SELECT 
  city1, 
  city2, 
  passengers, 
  fare, 
  fare_lg, 
  fare_low
FROM airfare.raw_table1
WHERE Year = 2026 AND quarter = 1 AND city1 LIKE 'Miami%' AND city2 LIKE 'New York%';

#4. Fare logic checks
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN fare_low > fare_lg THEN 1 ELSE 0 END) AS lowest_above_largest,
  SUM(CASE WHEN fare_low > fare THEN 1 ELSE 0 END) AS lowest_above_avg,
  SUM(CASE WHEN fare > fare_lg THEN 1 ELSE 0 END) AS avg_above_largest
FROM airfare.raw_table1
WHERE Year >= 2022;

#5. Market share checks (0 to 1)
SELECT
  MIN(large_ms) AS min_large_ms,
  MAX(large_ms) AS max_large_ms,
  MIN(lf_ms) AS min_lf_ms,
  MAX(lf_ms) AS max_lf_ms,
  SUM(CASE WHEN large_ms < 0 OR large_ms > 1 OR lf_ms < 0 OR lf_ms > 1 THEN 1 ELSE 0 END) AS out_of_range,
  SUM(CASE WHEN lf_ms > large_ms THEN 1 ELSE 0 END) AS low_share_above_largest,
  SUM(CASE WHEN carrier_low = carrier_lg AND lf_ms != large_ms THEN 1 ELSE 0 END) AS same_carrier_diff_share
FROM airfare.raw_table1
WHERE Year >= 2022;

#6. Join test: Table 1a city pairs found in Table 1
WITH pairs_1a AS (
  SELECT 
    DISTINCT Year,
    quarter,
    citymarketid_1,
    citymarketid_2
  FROM airfare.raw_table1a
  WHERE Year >= 2022
)
SELECT
  COUNT(*) AS pairs_in_1a,
  SUM(CASE WHEN t1.citymarketid_1 IS NOT NULL THEN 1 ELSE 0 END) AS matched,
  SUM(CASE WHEN t1.citymarketid_1 IS NULL THEN 1 ELSE 0 END) AS not_matched
FROM pairs_1a AS a
LEFT JOIN airfare.raw_table1 AS t1
  ON a.Year = t1.Year
  AND a.quarter = t1.quarter
  AND a.citymarketid_1 = t1.citymarketid_1
  AND a.citymarketid_2 = t1.citymarketid_2;
