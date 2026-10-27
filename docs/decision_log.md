# Route Pricing Benchmark: Project Log

## Step 1: Topic
Simple question: Which routes have the highest fares?  
Project name: Route Pricing Benchmark  
Scenario: I am an analyst on a pricing team at a Chicago-based airline. The team wants to know where its fares sit relative to the market.  
Stakeholders: Pricing manager, revenue management lead, network planning  
Sub-questions:

- Which routes have the highest fare per mile, by distance band?  
- Do routes dominated by one carrier have higher fares than competitive routes?  
- When a low-cost carrier has a meaningful share on a route, how much lower is the average fare?  
- How do Chicago routes compare to the national benchmark, and how does O’Hare compare to Midway?

Problem statement: How can we build a fare benchmark that flags which routes are priced above or below what their distance and competition level would predict?

## Step 2: Data
[Domestic Airfare Consumer Report from U.S. Department of Transportation](https://www.transportation.gov/policy/aviation-policy/domestic-airfare-consumer-report), downloaded October 11, 2026 from [data.transportation.gov](http://data.transportation.gov).   
Table 1 \- Top 1,000 Contiguous State City-Pair Markets  
Table 1a \- Multi-City Airport Markets Only  
Table 2 \- Top 1,000 City-Pair Markets Summarized By City  
Table 6 \- Contiguous State City-Pair Markets That Average At Least 10 Passengers Per Day  
Table 7 \- Fare Premiums for Select Cities With More Than 20 Passengers Per Day

Used Table 1 (city-pair fares, the main analysis) and Table 1a (airport-level detail, for O’Hare vs Midway). Tables 2 and 7 are kept for validation in the Excel reconciliation. Table 6 is a possible future extension to smaller markets. The report also includes Tables 3, 4, and 5, which were skipped because they’re DOT’s own finished analysis.

Time window: 2022 Q1 to 2026 Q1 (17 quarters). The passenger-weighted average fare was about \$183 in 2020 and \$186 in 2021, then \$228 in 2022 and \$234 in 2025\. Pandemic-era fares would distort a benchmark of current pricing, so 2020 and 2021 were excluded. The raw tables keep all years, and the filter is applied in the staging views.

## Step 3: BigQuery Set Up  
Created BigQuery project airfare-project (ID airfare-511403) with dataset airfare and uploaded 3 CSVs *dim\_carrier*, *raw\_table1*, and *raw\_table1a.*  
Removed 10 geocode columns from both Table 1 and Table 1a before upload because BigQuery rejects parentheses in column names. 4 of them were 100% empty in each file, and none were needed for the analysis.

Built dim\_carrier in Excel: 14 carrier codes appearing in Table 1 from 2022 on, with name and type (Legacy, Low-cost, Regional). The type labels are a judgment call: Southwest and JetBlue are sometimes called hybrid carriers, and Alaska isn’t always counted as legacy. Later removed leading spaces from some carrier names, which would have broken filters.

## Step 4: Query Checks
1\. Row counts. I want to make sure all the data is loaded completely.  
2\. Duplicates. I want to make sure each route is listed once per quarter since duplicates would double count routes in averages.  
3\. Spot check. Make sure BigQuery’s auto detect converted values correctly.  
4\. Fare logic. Make sure the fares follow rules that must be true.  
5\. Market shares. Making sure they are in between 0 and 1\.  
6\. The join test. To check how many Table 1a routes find their partner in Table 1\.

Check 1 passed. 17 quarters, 17,004 rows. Four quarters have 1,001 markets instead of 1,000 (2022 Q2, 2023 Q2, 2023 Q3, 2024 Q2). DOT doesn’t explain the extra market. Possibly a tie at the 1,000th spot, but unconfirmed.

Check 2 passed. No route appears twice in the same quarter.

Check 3 passed. BigQuery auto detect converted currency and comma fields to numbers. Verified against Miami to New York, 2026 Q1 (18,659 passengers, \$238.05).

Check 4 passed. fare\_low never exceeds fare\_lg. fare\_low exceeds the average fare in 443 rows (2.6%), median gap \$2.55, likely from small carriers excluded from the low-fare pick. Average fare exceeds the largest carrier’s fare in 6,033 rows, which is expected when the largest carrier is a low-cost airline. fare\_low means “lowest fare among the main airlines,” not “the cheapest ticket on the route.”

Check 5 passed. Both share columns fall between 0 and 1\. The lowest-fare carrier’s share never exceeds the largest carrier’s. When they’re the same airline the shares match exactly. 201 rows show one carrier with 100% of passengers.

Check 6 passed. Join key: Year \+ quarter \+ citymarketid\_1 \+ citymarketid\_2. 10,862 of 10,865 Table 1a city pairs (99.97%) match Table 1\. The 3 unmatched pairs are all from 2022 Q3 and are absent from Table 1 in that quarter. Cause unknown, impact negligible. (2022 Q3: Birmingham to Los Angeles, Boston to Bozeman, and Little Rock to Los Angeles)

## Step 5: Cleaning  
Built stg\_table1: filtered to 2022 Q1 to 2026 Q1, removed table\_1\_flag, renamed columns for readability, removed “(Metropolitan Area)” from city names, added a route label. 17,004 rows.  
Built stg\_table1a: filtered to 2022 Q1 to 2026 Q1, removed the tbl label column and the tbl1apk key, renamed columns for readability, kept airport IDs for matching and airport codes for readability, added city and airport route labels. 33,634 rows. Rows with missing carrier and fare values were kept and handled in profiling (see Table 1a nulls in Step 6).

## Step 6: Profile the data  
Each row is one route in one quarter (for example, Chicago to Miami in 2024 Q1). The 2022 to 2026 window has 17,004 rows covering 1,266 different routes.

Distance bands: Under 500 (2,976 rows, 18%), 500 to 999 (6,250, 37%), 1,000 to 1,499 (4,090, 24%), 1,500+ (3,688, 22%). Bands are uneven but the smallest band still has 2,976 rows, enough for stable comparisons. Kept the cutoffs.

Fare per mile by band (median): Under 500 at 51¢, 500 to 999 at 29¢, 1,000 to 1,499 at 20¢, 1,500+ at 15¢. Shorter routes cost more per mile and vary more: the middle half of routes spans 46% of the median in the under 500 band vs 25% in the 1,500+ band, likely because fixed per-flight costs are spread over fewer miles. The most extreme short route is 3.2x its band median vs 2.4x for long routes. The average is above the median in every band, so a few high-priced routes pull averages up (right skew). Decision: set outlier limits separately within each distance band, and favor medians over averages when describing typical fares.

Extreme fare per mile: the 10 highest are all under 500 miles, led by Portland to Seattle (7 of 10, \$196 to \$215 across 2022 to 2026). Consistent across quarters, so treated as real pricing, not errors. The 10 lowest are mostly low-cost carriers (Avelo, Frontier) with 70% to 100% share from secondary airports (New Haven, Trenton), suggesting single-carrier dominance doesn’t always mean higher fares. Distance for the same route varies slightly across quarters (Portland to Seattle: 129 vs 135 miles).

Table 1a nulls: 74 rows (0.2%) have no largest carrier, market shares, or carrier fares. All have 0 to 2 passengers per day, so these are very small markets where DOT doesn’t report carrier details. Spread across all quarters (1 to 9 per quarter, none in 2022 Q1). Concentrated at secondary airports: ISP 19, PAE 14, ACY 11, MIA 11\. Chicago is barely affected (MDW 1, ORD 0). Kept in the table. They have no effect on passenger-weighted averages and will be excluded from any carrier-level analysis.

## Step 7: Decide the outlier rule 
Outlier rule: Tukey’s fences within each distance band (Q1 − 1.5 × IQR, Q3 \+ 1.5 × IQR), calculated in SQL with APPROX\_QUANTILES. The 1.5 multiplier is the standard convention, not derived from this data. Result: 311 route-quarters flagged High (1.8%) and 5 flagged Low (all Avelo routes from New Haven, 1,000 to 1,499 miles). Flagged rows are kept, not deleted, because profiling showed the extremes are consistent real pricing (Portland to Seattle, Avelo routes), not data errors. Note: approximate percentiles shift the fences slightly, which changes the High count by about 14 compared to exact percentiles, so counts near the fence are sensitive.

## Step 8: Add the calculations
Built int\_route\_quarter: one row per route per quarter with fare per mile, distance band, competition group (Dominated if largest carrier share is 50%+), low-cost presence (low-cost carrier with 10%+ share), outlier flag, and carrier names and types joined from dim\_carrier. Validated: 17,004 rows (matches stg\_table1, so joins didn’t drop or duplicate rows), 0 missing carrier names, and outlier counts match 06\_outlier\_rule (311 High, 5 Low).

## Step 9: Build the benchmark 
Benchmark period: last 4 quarters (2025 Q2 to 2026 Q1), so each route covers one full year of seasons and reflects current prices. Collapsed to one row per route: 1,160 routes. 854 (74%) appear in all 4 quarters, while 134 appear in only 1 because they moved in and out of the top 1,000. All kept for now, with a quarters\_present column so a minimum can be applied later. Fare is passenger-weighted across quarters. Distance and largest carrier share are averaged, since both vary slightly by quarter.

Peer groups: 8 groups (4 distance bands × Dominated or Competitive), using the median route fare per mile. Smallest group: under 500 Competitive with 54 routes. Dominated routes have a higher median fare per mile than Competitive in all 4 bands (about 9% to 21%). Note: the quick findings showed mixed results in the shortest and longest bands, but used passenger-weighted fares over all 17 quarters. Reconciled in Step 11\. (Version 1\. Replaced by the regression benchmark below.)

The first benchmark (median fare per mile × miles) was biased by distance. Among routes under 500 miles, those under 250 miles had a median gap of \+102%, falling to −11% for 350 to 499 miles. Cause: fares stay roughly flat at short distances because of fixed per-flight costs, so dividing by fewer miles inflates fare per mile. The method flagged routes for being short, not for being expensive. Query saved in 08a\_benchmark\_v1\_distance\_bias.

Switched the benchmark to a within-group regression (expected fare \= intercept \+ slope × distance). Rechecked routes under 500 miles: median gap is now −0.5%, −0.7%, and \+0.9% across the three distance buckets, compared to \+102% to −11% before.

In the under 500 mile Competitive group, fares slightly decrease with distance. The shortest routes in this group are mostly Northeast corridor markets (Boston to New York, New York to Washington), which have rail alternatives and capacity-limited airports. A likely explanation is a higher share of time-sensitive business travelers, but this data can’t confirm it. This group had 54 routes (47 after limiting to full-year routes), so a handful of routes can move its slope a lot.

Price position cutoff: ±15%. The middle half of routes falls between −12% and \+11%, so 15% sits just outside normal variation, while staying inside the 10th and 90th percentiles (−21%, \+24%). Result: 222 Above benchmark, 718 In line, 220 Below benchmark (38% flagged). Kept adjustable: the Tableau dashboard will let viewers change the cutoff with a parameter. (Before Limited data was added. Final counts in the seasonal routes entry.)

Portland to Seattle was the most extreme route in profiling (about \$1.60 per mile). Under the final benchmark it sits at −2.2%, In line: its \$205 fare is close to the \$210 expected for a 134-mile Dominated route. Its high fare per mile came from a short distance, not overpricing, which confirms the method change.

Seasonal routes: 6 of the top 10 routes above benchmark appeared in only 1 quarter, mostly ski and winter destinations (Aspen, Eagle/Vail, Jackson Hole, Palm Springs, Key West). These routes only reach the top 1,000 in peak season, so their fare reflects peak pricing, not a full year. Fix: the regression is now fit only on the 854 routes present in all 4 quarters, and routes with fewer quarters are labeled “Limited data” instead of Above or Below. Result: 129 Above, 586 In line, 139 Below, 306 Limited data.

Peer groups now fit on the 854 routes present in all 4 quarters. Smallest group: under 500 Competitive with 47 routes. Dominated routes still have a higher median fare per mile than Competitive in all 4 bands. Bucket check on 4-quarter routes under 500 miles: median gaps of \+1.1%, −0.2%, and \+0.6%, so no distance bias.

Hub test: the 10 routes furthest above benchmark (full-year routes only) are all dominated by legacy airlines (Delta 8, American 2), mostly touching their hubs (Atlanta, Minneapolis, Detroit, Philadelphia). The 10 furthest below are all dominated by low-cost airlines (Allegiant, Avelo, Spirit, Breeze, Frontier), mostly at secondary airports. Suggests the effect of single-carrier dominance depends on the type of carrier. To be tested across all full-year routes, not just the extremes. (Tested in the next two entries.)

Added each route’s largest carrier and type from 2026 Q1 (the carrier changed across quarters for 16% of full-year routes, so a single quarter was used as the rule). All 854 full-year routes have a carrier. The 160 routes not present in 2026 Q1 have a blank carrier and are all in Limited data. Row count and position counts unchanged after the change.

Carrier type vs competition (854 full-year routes): Legacy-dominated routes have a median gap of \+4.1% vs −8.0% for Low-cost-dominated, a 12.1 point difference. Dominance adds about 3.4 points for Legacy routes (+4.1% vs \+0.7% Competitive) and almost nothing for Low-cost (−8.0% vs −8.9%). Carrier type separates prices more than single-carrier dominance does. Hubs weren’t measured directly, so the hub explanation is based on the top 10 routes, not tested.

Robustness by distance band: among Dominated routes, Legacy has a higher median gap than Low-cost in all 4 bands (7.5 to 17.2 points apart). Among Competitive routes, Legacy is higher in 3 of 4 bands. The exception (under 500 miles) has only 7 Low-cost routes, too few to draw from. Thinnest Dominated group: Low-cost 1,500+ miles with 18 routes.

## Step 10: Build the Chicago airport view
Built mart\_chicago\_airports: Table 1a rows involving O’Hare or Midway, flipped so the Chicago airport is always in one column and the destination in another. 2,806 rows (ORD 1,422, MDW 1,384). 1 row has no carrier (a Midway row with 0 passengers, from the Table 1a nulls). No regional carrier codes appear on Chicago routes.

Excluded 8 Chicago airport rows with 0 passengers per day from the comparison (rounded down from less than 1 passenger a day). One of them, Midway to Jackson WY, was Midway’s only row for that city, so Midway serves 76 destination cities, not 77\.

O’Hare vs Midway (last 4 quarters): compared the same destination cities from each airport, since the two airports serve different route mixes. Fares are passenger-weighted per airport and destination city. 76 cities are served from both. O’Hare is more expensive in 70 of 76 (92%), with a median difference of \+\$31.64 (+14.5%) per ticket.

Robustness: limited to the 56 cities where both airports have all 4 quarters. O’Hare is higher in 53 (95%), median \+\$32.97 (+14.5%). Nearly the same as the full comparison, so seasonal differences between the airports don’t explain the gap.

Chicago vs national (full-year routes): Chicago’s median price gap is \+5.1% vs −1.0% for all other routes. 11 of 57 Chicago routes are Above benchmark and only 2 Below, while nationally Above and Below are about even (129 vs 139). Most Chicago routes (46 of 57\) are Competitive, yet still priced above benchmark (+5.1%), similar to Dominated Chicago routes (+5.7%). Likely reason: O’Hare is a hub for two legacy airlines, United and American. Among Chicago’s full-year routes, United is the largest carrier on 36 and American on 12, so competition there is mostly legacy vs legacy, which the carrier-type finding suggests doesn’t lower fares the way low-cost competition does. On the same destinations, O’Hare is 14.5% more expensive than Midway, where Southwest is the largest carrier. (Tested in the next entry.)

Chicago by carrier type: legacy-led Chicago routes (52, mostly United and American) have a median gap of \+5.1%, while Southwest-led routes (5) are at −6.7%. Supports the dual-hub explanation, but the low-cost group is too small to rely on alone.

## Step 11: Answer the four sub-questions 
Reran the quick findings on int\_route\_quarter. Both comparisons (Dominated vs Competitive, Low-cost present vs not) match 03\_quick\_findings exactly, row counts and passenger-weighted fares. Confirms the view preserves the data and the earlier figures.

Reconciled: the quick findings showed Dominated routes higher only in the 500 to 1,499 mile bands, while the route-level peer groups showed Dominated higher in all bands. The quick findings weight by passengers, so busy routes count more. Since low-cost-dominated routes price well below legacy-dominated ones, high-traffic low-cost routes likely pull the weighted Dominated average down in the shortest and longest bands. Both methods agree that carrier type matters more than dominance alone.

### Which routes have the highest fare per mile, by distance band?  
Portland, OR to Seattle, WA has the highest fare per mile, showing up 7 times in the top 10 across different quarters. Short routes cost over three times more per mile than long ones (51¢ vs 15¢), mostly because fixed per-flight costs are spread over fewer miles. But a high fare per mile doesn’t mean a route is overpriced. Portland to Seattle is within 2.2% of its benchmark, while Atlanta to Charlotte is the most overpriced full-year route at \+63.5%.

### Do routes dominated by one carrier have higher fares than competitive routes?  
Dominated routes cost about 8% to 9% more on mid-distance routes (500 to 1,499 miles), but 5.4% less on routes under 500 miles and only 0.3% more on routes over 1,500 miles. What matters more is the type of airline. Routes led by legacy airlines sit above the benchmark and routes led by low-cost airlines sit below it, on both dominated routes (+4.1% vs −8.0%) and competitive routes (+0.7% vs −8.9%).

### When a low-cost carrier has a meaningful share on a route, how much lower is the average fare?  
Routes where a low-cost carrier has a meaningful share (10% or more) have 5% to 13% lower average fares in every band. When Southwest and JetBlue are counted as legacy instead, the gap is 8% to 16%, so the pattern holds either way.

### How do Chicago routes compare to the national benchmark, and how does O’Hare compare to Midway?  
Chicago’s median price gap is \+5.1% vs −1.0% for all other routes. O’Hare is more expensive than Midway for 92% of destination cities (70 of 76), with a median difference of \+\$31.64 (14.5%) per ticket.

## Step 12: Excel workbook (in progress)

## Step 13: Tableau dashboard (in progress)

## Step 14: Write-up (README) and GitHub (in progress)

## LIMITS  
- Fares are quarterly averages per market, not ticket-level prices. I can say where fares are high, not how any airline sets them.  
- Markets are directionless, so traffic in both directions is added together. Chicago to Miami and Miami to Chicago are one row.  
- Only the top 1,000 city-pair markets per quarter are included, so smaller markets aren’t covered.  
-  Fares are not adjusted for inflation.  
- All findings are comparisons, not proof of cause. For example, routes with low-cost carriers have lower fares, but this data can’t show the carrier caused it.  
- Carrier type labels are a judgment call (Southwest and JetBlue as low-cost). Results were tested both ways.  
- Each route’s largest carrier comes from 2026 Q1 only. It changed across quarters for 16% of full-year routes.  
- Hubs weren’t measured directly. The hub explanation comes from which routes ranked highest.  
- 306 routes with fewer than 4 quarters are labeled Limited data and not scored as Above or Below.  
- In Table 1, Chicago combines O’Hare and Midway into one market, so the Chicago vs national comparison blends both airports.  
- Medians use BigQuery’s approximate percentiles, which can differ slightly from exact values.
