# Competitive FIFA Head to Head Network

Network Science Progress Report  6 November 2026

Group members: Frank Williams and AbdulHaady Oludare

## 1 Work completed

Following the proposal's October 27 to November 5 milestone, we assembled and validated 129 competitive 1v1 fixtures involving 81 players across all nine editions from FIFA 18 to EA Sports FC 26. We built weighted directed win networks, with edges from loser to winner, and undirected played networks for each edition and the pooled sample. We calculated degree, density, connected components and weighted PageRank on the win network with damping 0.85 [1]. Clean CSV files, GraphML networks, figures and reproducible R scripts are complete.

Because approved Liquipedia access was unavailable, we used official EA, FIFA, UEFA and Premier League results instead [2, 3]. We resolved player aliases and standardized the observation as one source-listed fixture or series, counting a multi-leg tie once. We also collected 48 career and 222 edition earnings measurements from live public profiles on November 6 [4]. These are explicitly provider-recorded totals. Data validation and repeatability checks pass in R 4.4.2 with igraph 2.2.2.

## 2 Preliminary results

The pooled played network is connected and has an average of 3.01 distinct opponents per player. In the pooled directed win network, the highest PageRank players are Shellzz, RvPLegend10, Nassada, Vejrgang and Ollelito, in that order. Table 1 reports the main descriptive and RQ1 results.

**Table 1  Results for the observed pooled sample**

| Measure | Result |
| --- | --- |
| Players and recorded fixtures | 81 and 129 |
| Directed win links and undirected played links | 124 and 122 |
| Played network density and mean degree | 0.0377 and 3.01 |
| PageRank versus wins | 0.970  (n = 81) |
| PageRank versus recorded career earnings | 0.287  (n = 48) |
| All events versus world and major events | 0.976  (n = 38) |

The final three rows report Spearman rank correlations; n is the number of matched players. The sensitivity subset contains world championships and the eChampions League; ranking agreement uses only the 38 shared players.

PageRank closely tracks win counts but has a weaker association with recorded career earnings. The world and major event subset retains 51 fixtures and excludes 43 players, including six of the full sample's top ten. Its high correlation therefore describes agreement among the retained players, rather than stability of the complete ranking. All nine edition-specific earnings comparisons also compute, but their matched samples range from 3 to 11 players. These results are exploratory and do not establish a global strongest-player ranking.

## 3 Challenges encountered

Coverage is uneven: the FIFA 21 ePremier League event supplies 71 of 129 fixtures (55%), while several editions contain only a few late-stage results. Domestic-event filtering also changes edition composition, so it cannot isolate a pure tournament-tier effect. We address this by reporting scope, sample sizes and sensitivity results, and by prioritizing broader event collection.

Player aliases and incomplete provider records complicate joins. We retain source URLs and stable IDs, exclude unresolved identities, and leave absent earnings missing rather than assigning zero. Known missing prizes are not added to potentially overlapping totals. For 34 fixtures without an exact day, sourced event-end dates provide conservative cutoff bounds. Country information is available for 50 of 81 players; country flags alone do not establish competitive qualifying regions. Approved bulk access and better metadata remain data-collection bottlenecks.

## 4 Remaining work and timeline

Essential outstanding work is to expand and audit match coverage, resolve remaining identities, source time-aware region and platform attributes, and complete the tournament-placement benchmark promised for RQ1. The earnings comparison is implemented, while the broader strength-ranking question remains provisional. The next stages follow the original proposal:

| Target dates | Work to complete |
| --- | --- |
| Nov 7-10 | Extend and audit available match data; reconcile aliases, placements and metadata. If bulk access is delayed, retain a clearly defined event cohort and its coverage limits. |
| Nov 11-20 | Analyze communities and assortativity (RQ2), triads against 1,000 random-outcome simulations (RQ3), and betweenness with cross-region win rates (RQ4). |
| Nov 21-27 | Run degree, betweenness and random player-removal experiments (RQ5); prepare the final figures. |
| Nov 28-Dec 2 | Write the final report and record the video presentation, ready for the December 3 presentation. |

Before interpreting regional structure or player strength, we will check how results change with event coverage and missing attributes. The current data and scripts provide a reproducible baseline for those analyses.

## Sources and supporting evidence

[1] igraph development team. [The Page Rank algorithm](https://r.igraph.org/reference/page_rank.html). Implementation documentation.

[2] Premier League. 2020/21 ePL results: [Xbox](https://www.premierleague.com/en/news/2075924), [PS4](https://www.premierleague.com/en/news/2076123) and [finals](https://www.premierleague.com/en/news/2077050) (March 23, 24 and 26, 2021).

[3] EA. [FC Pro World Championship 26 Review](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-26-review). Representative official match source.

[4] Esports Earnings. Player-profile snapshots retrieved November 6, 2026; examples: [Vejrgang](https://www.esportsearnings.com/players/111288-anders-vejrgang) and [ManuBachoore](https://www.esportsearnings.com/players/110315-manubachoore-manuel-bachoore).

Complete source registers, cleaned data, analysis outputs and input hashes are retained in the project repository. This progress report reflects evidence available on November 6, 2026.
