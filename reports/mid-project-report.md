# Who Really Beats Whom: mid-project report draft

Analysis cutoff: **2026-11-04** (America/Vancouver). Target report date: **November 6, 2026**.

## Current result and status

The executable R workflow validates and analyzes 49 source-backed match records involving 38 players across 7 of the 9 planned editions. Input: checked-in public cohort. These are a convenience sample of major championship results, with edition-specific omissions recorded in docs/data-coverage.md. They establish that the analysis works; they do not establish a global professional ranking.

Within the observed combined network, **RvPLegend10** has the largest weighted PageRank. This position depends on the selected events, opponents and omitted rounds. It must not be interpreted as the strongest FIFA professional over 2017–2026.

The current milestone's computation is implemented. Full data collection and the empirical PageRank-versus-career-earnings comparison remain incomplete. The API clients are prepared, but no keys were supplied and no API key application was submitted. RQ2–RQ5 are future milestones.

## Data and quality

| game_edition | matches |
| --- | --- |
| FIFA18 | 2 |
| FIFA19 | 2 |
| FIFA20 | 0 |
| FIFA21 | 0 |
| FIFA22 | 1 |
| FIFA23 | 3 |
| FC24 | 7 |
| FC25 | 11 |
| FC26 | 23 |

There are 0 eligible earnings snapshot rows. Unknown earnings stay missing. 34 match records lack an exact match day; their sourced event end dates are used only to confirm that the event finished by the cutoff. They retain their original missing exact dates. The public cohort omits group/league stages and regional or lower-tier events; this creates strong selection bias toward championship progression.

Validation recorded 0 errors, 0 exclusion notices and 34 uncertainty warnings. Notices count issues rather than necessarily distinct rows. See results/quality-issues.csv. IDs and source URLs are preserved in clean CSVs.

## Network construction and descriptive metrics

Each decisive completed 1v1 series/tie contributes one directed loser-to-winner edge, weighted by repeated wins over that opponent. The undirected played network counts all completed fixtures between each pair, including draws. Draws do not create win-network edges. Penalty-decided ties have an explicit winner; shootout scores are not goal totals. Vertices are the players participating in the selected scope. A pooled graph and a separate graph for each observed edition are exported as GraphML and edge CSVs.

| scope | nodes | matches | win_edges | played_edges | density_played | mean_degree_played | components_played | giant_component_fraction |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| combined | 38 | 49 | 49 | 49 | 0.0697 | 2.5789 | 1 | 1 |
| FC24 | 8 | 7 | 7 | 7 | 0.2500 | 1.7500 | 1 | 1 |
| FC25 | 12 | 11 | 11 | 11 | 0.1667 | 1.8333 | 1 | 1 |
| FC26 | 24 | 23 | 23 | 23 | 0.0833 | 1.9167 | 1 | 1 |
| FIFA18 | 3 | 2 | 2 | 2 | 0.6667 | 1.3333 | 1 | 1 |
| FIFA19 | 3 | 2 | 2 | 2 | 0.6667 | 1.3333 | 1 | 1 |
| FIFA22 | 2 | 1 | 1 | 1 | 1.0000 | 1.0000 | 1 | 1 |
| FIFA23 | 4 | 3 | 3 | 3 | 0.5000 | 1.5000 | 1 | 1 |

In-degree counts distinct opponents beaten; incoming strength counts won ties. Total played degree counts distinct opponents, whereas weighted played degree counts all ties. A low degree in this sample is partly induced by knockout format and omitted rounds, so it is insufficient evidence for regional isolation.

## RQ1: ranking by defeated opponents

Weighted directed PageRank uses damping 0.85. Average ranks handle ties after PageRank is rounded to 12 significant digits for ranking and Spearman comparisons only; raw scores are retained. Smaller rank numbers are better. Rank gaps are PageRank rank minus the comparison rank, so negative gaps indicate a better PageRank position. Earnings gaps compare the same subset of players with available earnings. Combined graphs use career totals and edition graphs use edition totals, with the latest snapshot no later than the cutoff.

| handle | pagerank_rank | pagerank | wins | losses | opponents |
| --- | --- | --- | --- | --- | --- |
| RvPLegend10 | 1 | 0.1799 | 5 | 0 | 5 |
| Nassada | 2 | 0.1136 | 2 | 1 | 3 |
| Vejrgang | 3 | 0.1074 | 5 | 1 | 6 |
| ManuBachoore | 4 | 0.0694 | 5 | 1 | 6 |
| levyfinn | 5 | 0.0441 | 3 | 1 | 4 |
| Msdossary | 6 | 0.0304 | 3 | 2 | 5 |
| MoAuba | 7 | 0.0261 | 2 | 0 | 2 |
| Brice | 8 | 0.0245 | 3 | 1 | 4 |
| Yuval | 9 | 0.0244 | 2 | 1 | 3 |
| Alihanlion | 11 | 0.0220 | 1 | 1 | 2 |
| GuiBarros | 11 | 0.0220 | 1 | 1 | 2 |
| nicolas99fc | 11 | 0.0220 | 1 | 4 | 5 |

| scope | comparison | n_complete | spearman_rho | status |
| --- | --- | --- | --- | --- |
| combined | pagerank_vs_wins | 38 | 0.9502 | computed |
| combined | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FC24 | pagerank_vs_wins | 8 | 1.0000 | computed |
| FC24 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FC25 | pagerank_vs_wins | 12 | 0.9920 | computed |
| FC25 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FC26 | pagerank_vs_wins | 24 | 0.9795 | computed |
| FC26 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FIFA18 | pagerank_vs_wins | 3 | 1.0000 | computed |
| FIFA18 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FIFA19 | pagerank_vs_wins | 3 | 1.0000 | computed |
| FIFA19 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FIFA22 | pagerank_vs_wins | 2 | unavailable | insufficient_complete_pairs |
| FIFA22 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |
| FIFA23 | pagerank_vs_wins | 4 | 1.0000 | computed |
| FIFA23 | pagerank_vs_earnings | 0 | unavailable | insufficient_complete_pairs |

No global or career inference is supported by this sample. Missing earnings, insufficient complete pairs, and constant inputs have explicit unavailable statuses. A Spearman coefficient is descriptive here; the workflow does not claim statistical significance or causal player quality. Tournament placements are not yet imported, and the current career-earnings comparison cannot be completed without verified observations.

## Random-network and coverage checks

For each scope, 100 reproducible undirected G(n,m) graphs retain the observed number of players and played edges. Their mean degree and density equal the observation by construction. The structural comparison therefore uses giant-component fraction and global transitivity. The 2.5%–97.5% simulation interval is a null-model reference range, not a confidence interval for the FIFA population. Some sparse simulated graphs have undefined transitivity; the finite replicate count is exported.

| scope | observed_giant_fraction | random_giant_mean | random_giant_q025 | random_giant_q975 | observed_transitivity | random_transitivity_mean |
| --- | --- | --- | --- | --- | --- | --- |
| combined | 1 | 0.9250 | 0.8421 | 1.0000 | 0.0508 | 0.0639 |
| FC24 | 1 | 0.8638 | 0.6250 | 1.0000 | 0.0000 | 0.1625 |
| FC25 | 1 | 0.8192 | 0.5833 | 0.9604 | 0.0000 | 0.1524 |
| FC26 | 1 | 0.7904 | 0.6250 | 0.9167 | 0.0000 | 0.0605 |
| FIFA18 | 1 | 1.0000 | 1.0000 | 1.0000 | 0.0000 | 0.0000 |
| FIFA19 | 1 | 1.0000 | 1.0000 | 1.0000 | 0.0000 | 0.0000 |
| FIFA22 | 1 | 1.0000 | 1.0000 | 1.0000 | unavailable | unavailable |
| FIFA23 | 1 | 0.9400 | 0.7500 | 1.0000 | 0.0000 | 0.2400 |

Tier sensitivity: Unavailable: no verified provider tier classifications. Eligible major-tier rows: 0. The current public records have no consistent provider tier classification; an unknown tier is not recoded as lower tier. With no lower-tier observations, the proposal's with/without-lower-tier comparison remains pending.

## Figures and reproducibility

The pipeline generates `results/figures/pagerank-top10.png`, `played-network.png`, and `degree-distribution.png`, plus scope-specific metrics, rankings, correlation statuses, random baselines and graph exports. Re-run `Rscript scripts/run_pipeline.R` from the repository root; run `Rscript scripts/test.R` for validation. `results/run-manifest.csv` records the cutoff, input hashes and dependency versions. `results/session-info.txt` records the R environment.

![PageRank in the observed cohort](../results/figures/pagerank-top10.png)

![Observed played network](../results/figures/played-network.png)

![Observed opponent-degree distribution](../results/figures/degree-distribution.png)

## Work required before submission and later analysis

1. Obtain approved access or curated exports; collect the missing editions, regional qualifiers and omitted stages; resolve cross-source aliases and duplicate series.
2. Join properly scoped and dated career/edition earnings and tournament placements; audit region, platform and tournament-tier coverage.
3. Rerun and review RQ1 against the broader corpus, quantify coverage and revise this draft's conclusions before the November 6 submission.
4. November 7–20: communities/assortativity (RQ2), triad null models (RQ3), and bridge analysis (RQ4). November 21–27: robustness (RQ5). November 28–December 2: final report and video, for the December 3 presentation.

## Match sources

- [Official result source](https://inside.fifa.com/news/moauba-becomes-first-german-to-win-fifa-eworld-cup)
- [Official result source](https://inside.fifa.com/news/msdossary-crowned-fifa-eworld-cup-champion)
- [Official result source](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-2025-review)
- [Official result source](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-26-review)
- [Official result source](https://www.fcpro.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-finals-results)
- [Official result source](https://www.fifa.com/en/articles/umut-crowned-world-champion-fifae-world-cup-2022)
- [Official result source](https://www.fifa.gg/news/manubachoore-claims-the-fifae-world-champion-title)

Source-specific curation and metadata provenance: `data/raw/sources.csv` and `docs/data-coverage.md`. Provider documentation: [Esports Earnings API](https://www.esportsearnings.com/apidocs), [Liquipedia API](https://liquipedia.net/api), [Liquipedia API terms](https://liquipedia.net/api-terms-of-use). Method reference: [igraph PageRank](https://r.igraph.org/reference/page_rank.html).
