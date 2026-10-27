#Staging view for Table 1a: airport pairs, 2022 on, renamed and cleaned
CREATE OR REPLACE VIEW airfare.stg_table1a AS
SELECT
  Year AS year,
  quarter,
  citymarketid_1 AS city_id_1,
  citymarketid_2 AS city_id_2,
  REPLACE(city1, ' (Metropolitan Area)', '') AS city_1,
  REPLACE(city2, ' (Metropolitan Area)', '') AS city_2,
  CONCAT(
    REPLACE(city1, ' (Metropolitan Area)', ''),
    ' to ',
    REPLACE(city2, ' (Metropolitan Area)', '')
  ) AS route,
  airportid_1 AS airport_id_1,
  airportid_2 AS airport_id_2,
  airport_1 AS airport_code_1,
  airport_2 AS airport_code_2,
  CONCAT(airport_1,' to ',airport_2) AS airport_route,
  nsmiles AS distance_miles,
  passengers AS passengers_per_day,
  fare AS avg_fare,
  carrier_lg AS largest_carrier,
  large_ms AS largest_carrier_share,
  fare_lg AS largest_carrier_fare,
  carrier_low AS low_fare_carrier,
  lf_ms AS low_fare_carrier_share,
  fare_low AS low_fare_carrier_fare
FROM airfare.raw_table1a
WHERE Year >= 2022;

#Row count
SELECT COUNT(*) AS row_count
FROM airfare.stg_table1a;

#Preview first 10
SELECT *
FROM airfare.stg_table1a
LIMIT 10;
