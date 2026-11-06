# Data coverage and provenance

Evidence cutoff: **November 6, 2026**. The public cohort contains **129 source-backed 1v1 fixtures and 81 players**, with all nine planned editions represented. It is a selective research sample, not a census of competitive FIFA/EA FC.

| Edition | Observed fixtures | Coverage |
| --- | ---: | --- |
| FIFA18 | 2 | World Championship Xbox semifinal and grand final |
| FIFA19 | 2 | World Championship PlayStation semifinal and grand final |
| FIFA20 | 7 | ePremier League closing finals-day bracket |
| FIFA21 | 71 | Complete ePremier League finals event: both console group stages, quarterfinals and finals day |
| FIFA22 | 3 | World final plus two eChampions League results |
| FIFA23 | 3 | World semifinals and final |
| FC24 | 7 | World quarterfinals through final |
| FC25 | 11 | Four Round-of-16 fixtures plus quarterfinals, semifinals and final |
| FC26 | 23 | World Round-of-24 through final |

All nine editions now have observations. Most included events remain incomplete, while FIFA21 includes one complete domestic finals event rather than all professional play in that edition. Small cups and open qualifiers remain underrepresented. Event/edition coverage differs substantially, so pooled rankings and comparisons cannot establish a definitive global strongest-player ordering.

## Match evidence and unit of observation

Original official EA/FIFA evidence is registered in `data/raw/sources.csv`. The FIFA20/21/22 expansion has explicit source-listed outcomes, exact dates, and transcription/identity decisions in [match-expansion.md](match-expansion.md) and `data/raw/match_sources_expansion.csv`. Every raw match retains its own source URL. Stable IDs distinguish genuine rematches from duplicates.

One record is one reported head-to-head bracket fixture or series, which may aggregate multiple legs. Do not count records as individual video-game legs. Penalty-decided fixtures retain the winner and actual reported goal aggregate; shootout scores are not goals. Unknown goal totals remain empty. FIFA22 eChampions League goal accounting differs between official recaps, so those two added outcomes retain the reported winner without inventing a reconciled score.

Ninety-five fixtures have an exact source-supported match date. FC25's 11 and FC26's 23 records retain an empty exact day and a conservative event-end bound (2025-08-10 and 2026-07-26). At a cutoff inside either event, unknown-day records cannot be assigned to a day without further evidence. Event end dates are eligibility bounds, never imputed exact match dates.

## Event scope and platforms

`data/raw/tournaments.csv` applies `research_event_scope_v1`: world championships are `world`, the international eChampions League is `major`, and domestic ePremier League events are `regional`. These are study classifications, not official or Liquipedia tiers. There are 51 world/major fixtures and 78 domestic fixtures, enabling the previously missing sensitivity run. Because domestic observations concentrate in FIFA20/21, filtering also changes edition composition; the resulting difference is not an isolated causal effect of tier.

Platforms explicitly reported in league results stay on individual fixtures, including cross-console finals. FC25/FC26 World Championship PlayStation 5 metadata comes from the linked official competition rules. Unknown platforms are retained as unknown. `tier_source_url`, `platform_source_url` and `tier_scheme` preserve enrichment provenance in the clean data. Source observations are never silently overwritten by conflicting metadata.

## Earnings and player attributes

Live November 6 profile snapshots now support **provider-recorded career and edition earnings**. [earnings-provenance.md](earnings-provenance.md) and `data/raw/earnings_sources.csv` specify the matched identities, retrieval evidence, exclusions, amounts and incompleteness. The November 4 decision to exclude all provider totals because some tournaments were missing was too restrictive for this revised, explicitly provider-recorded comparison. The new snapshot is not backdated into the prior analysis.

These totals are observations of what the provider reports, not repaired or verified complete lifetime earnings. Known omitted prizes are not added onto potentially overlapping totals. Career and edition totals are separate scopes. Missing player/game records remain missing, never zero. `results/correlations.csv` reports the actual matched sample sizes after joining to each graph, and `results/availability.csv` records current feature coverage.

Stable ASCII player IDs preserve aliases across editions. Country flags from verified provider profiles are added only when the raw country is unknown; their source URL and snapshot date are retained. Conflicting source observations create a warning and preserve the original. Country flags do not establish historical residence, citizenship at each match, or a competitive qualifying region. Competitive-region fields remain unknown until a separate time-aware coding is sourced.

## Access and reproducibility

The default run is offline and needs no keys. The project now includes tested API-cache normalization into canonical earnings CSVs as well as cached/throttled fetch preparation. Live Esports Earnings API access still requires a local key; large-scale LPDB collection requires approved access and a verified schema. Current source-access details and commands are in [api-access.md](api-access.md). No key application or message was submitted.

The saved report and outputs use November 6 as their cutoff. Input hashes and dependency versions are recorded in `results/run-manifest.csv`. `results/availability.csv` distinguishes available computations from partial data coverage and external access prerequisites.
