#Quick findings: early exploratory check on raw_table1, before the views were built.
#Confirmed later on int_route_quarter in 09_findings (exact match).

#1. Low-cost present vs not, by band (passenger-weighted)
WITH routes AS (
  SELECT
    t.fare,
    t.passengers,
    CASE
      WHEN t.nsmiles < 500 THEN '1. Under 500'
      WHEN t.nsmiles < 1000 THEN '2. 500-999'
      WHEN t.nsmiles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band,
    CASE
      WHEN c.carrier_type = 'Low-cost' AND t.lf_ms >= 0.10 THEN 'Low-cost present'
      ELSE 'No low-cost'
    END AS lcc_group
  FROM airfare.raw_table1 AS t
  LEFT JOIN airfare.dim_carrier AS c
    ON t.carrier_low = c.carrier_code
  WHERE t.Year >= 2022
)
SELECT
  distance_band,
  lcc_group,
  COUNT(*) AS row_count,
  ROUND(SUM(fare * passengers) / SUM(passengers), 2) AS weighted_avg_fare
FROM routes
GROUP BY distance_band, lcc_group
ORDER BY distance_band, lcc_group;

#2. Dominated vs competitive, by band (passenger-weighted)
WITH routes AS (
  SELECT
    fare,
    passengers,
    CASE
      WHEN nsmiles < 500 THEN '1. Under 500'
      WHEN nsmiles < 1000 THEN '2. 500-999'
      WHEN nsmiles < 1500 THEN '3. 1000-1499'
      ELSE '4. 1500+'
    END AS distance_band,
    CASE
      WHEN large_ms >= 0.5 THEN 'Dominated'
      ELSE 'Competitive'
    END AS competition_group
  FROM airfare.raw_table1
  WHERE Year >= 2022
)
SELECT
  distance_band,
  competition_group,
  COUNT(*) AS row_count,
  ROUND(SUM(fare * passengers) / SUM(passengers), 2) AS weighted_avg_fare
FROM routes
GROUP BY distance_band, competition_group
ORDER BY distance_band, competition_group;
