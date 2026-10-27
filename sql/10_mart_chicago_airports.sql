#Chicago airport view: O'Hare and Midway routes, one row per airport pair per quarter
CREATE OR REPLACE VIEW airfare.mart_chicago_airports AS
SELECT
  year,
  quarter,
  distance_miles,
  passengers_per_day,
  avg_fare,
  largest_carrier, 
  largest_carrier_share,
  low_fare_carrier, 
  low_fare_carrier_share,
  avg_fare / distance_miles AS fare_per_mile,
  CASE
    WHEN airport_code_1 IN ('ORD', 'MDW') THEN airport_code_1
    ELSE airport_code_2
  END AS chicago_airport,
  CASE
    WHEN airport_code_1 IN ('ORD', 'MDW') THEN airport_code_2
    ELSE airport_code_1
  END AS dest_airport,
  CASE
    WHEN city_1 = 'Chicago, IL' THEN city_2
    ELSE city_1
  END AS dest_city,
  lg.carrier_name AS largest_carrier_name,
  lg.carrier_type AS largest_carrier_type,
  lo.carrier_name AS low_fare_carrier_name,
  lo.carrier_type AS low_fare_carrier_type
FROM airfare.stg_table1a AS t
LEFT JOIN airfare.dim_carrier AS lg
  ON t.largest_carrier = lg.carrier_code
LEFT JOIN airfare.dim_carrier AS lo
  ON t.low_fare_carrier = lo.carrier_code
WHERE airport_code_1 IN ('ORD', 'MDW')
   OR airport_code_2 IN ('ORD', 'MDW');

#Row count
SELECT COUNT(*) AS row_count
FROM airfare.mart_chicago_airports;

#Rows per airport
SELECT
  chicago_airport,
  COUNT(*) AS row_count
FROM airfare.mart_chicago_airports
GROUP BY chicago_airport;

#Blank carrier names
SELECT COUNT(*) AS row_count
FROM airfare.mart_chicago_airports
WHERE largest_carrier_name IS NULL;
