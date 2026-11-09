# Route Pricing Benchmark
Where do U.S. domestic airfares sit compared to what a route “should” cost? A benchmark built from public DOT data, analyzed for a pricing team at a Chicago-based airline.

**Tools:** BigQuery SQL, Excel, Tableau

**Dashboard:** Tableau Public LINK

## Questions
Which routes have the highest fare per mile, by distance band?
Do routes dominated by one carrier have higher fares than competitive routes?
When a low-cost carrier has a meaningful share on a route, how much lower is the average fare?
How do Chicago routes compare to the national benchmark, and how does O'Hare compare to Midway?

## Key findings
Short routes cost over three times more per mile than long ones (median 51¢ vs 15¢), mostly because fixed per-flight costs are spread over fewer miles. A high fare per mile doesn't mean a route is overpriced: Portland to Seattle is within 2.2% of its benchmark, while Atlanta to Charlotte is 63.5% above it.
Carrier type matters more than dominance. Dominated routes cost 2.8% more when a legacy carrier leads, but 13.3% less when a low-cost carrier leads.
Routes with a low-cost carrier (10%+ share) have 5% to 13% lower average fares in every distance band.
Legacy routes lean above the benchmark. 21% of legacy-led routes price more than 15% above their expected fare, vs 3% of low-cost-led routes.
Chicago prices above the national benchmark. The typical Chicago route sits 5.1% above its benchmark, vs 1.0% below everywhere else.
O'Hare costs more than Midway to 70 of 76 shared destination cities, a median of $31.64 (14.5%) more per ticket.

All findings are comparisons, not proof of cause.

## Data
U.S. Department of Transportation, Domestic Airfare Consumer Report, Tables 1 and 1a, from data.transportation.gov. Table 1 has city-pair fares (main analysis), Table 1a has airport-level detail (O'Hare vs Midway).

**Time window:** 2022 Q1 to 2026 Q1 (17 quarters, 17,004 route-quarters, 1,266 routes). 2020 and 2021 were excluded because pandemic-era fares would distort a benchmark of current pricing. The benchmark uses the last 4 quarters (2025 Q2 to 2026 Q1).

## Method
Layered views in BigQuery: raw, staging, intermediate, mart.
Weighted averages: fares are weighted by passengers, so busy routes and quarters count more.
Outliers: flagged with Tukey fences within each distance band, and kept, since the extremes were consistent real pricing, not errors.
Groups: a route is Dominated if its largest carrier has 50%+ share. Low-cost presence means a low-cost carrier has 10%+ share.
Benchmark: expected fare = intercept + slope × distance, fit separately for each distance band and competition group, using the 854 routes with all 4 quarters. A first version (median fare per mile × miles) was biased by distance and was replaced.
Price gap: (actual fare − expected fare) / expected fare. Routes more than 15% above are Above, more than 15% below are Below, the rest In line. The cutoff is adjustable on the dashboard.
Limited data: 306 routes with fewer than 4 quarters are shown but not scored, since seasonal routes skewed the benchmark.
O'Hare vs Midway: compared only on destination cities both airports serve.

## Checks
Excel totals reconciled with SQL on 6 checks across 3 tables. All differences under 0.01.
Excel pivots and Tableau charts match the SQL results.

## Repo
Folder	What's in it
sql/	BigQuery queries, numbered in run order
excel/	Workbook with pivots, Route Lookup (XLOOKUP), Reconciliation, and Notes
docs/decision_log.md	Every step and decision, with the checks behind it

## Limits
Fares are quarterly market averages, not ticket prices.
Only the top 1,000 city-pair markets are included.
Markets are directionless, so Chicago to Miami and Miami to Chicago are one row.
Fares are not adjusted for inflation.
Each route's largest carrier comes from 2026 Q1 only.
In Table 1, Chicago combines O'Hare and Midway into one market.

Full list in the Notes sheet of the Excel workbook and in the decision log.
