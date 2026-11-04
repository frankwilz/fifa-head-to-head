# Data coverage and provenance

Snapshot: **2026-11-04**. The checked-in public cohort contains **49 real 1v1 results and 38 players**, transcribed from official EA/FC Pro reports. It is a reproducible starter cohort for validating network construction and RQ1 calculations. It is not the complete FIFA 18–FC 26 research dataset.

| Edition | Event coverage | Results | Date precision |
| --- | --- | ---: | --- |
| FIFA18 | World Championship Xbox semifinal and grand final | 2 | Exact finals-day date: 2018-08-04 |
| FIFA19 | World Championship PlayStation semifinal and grand final | 2 | Exact finals-day date: 2019-08-04 |
| FIFA22 | World Championship grand final only | 1 | Exact final date: 2022-07-17 |
| FIFA23 | World Championship semifinals and final | 3 | Exact finals-day date: 2023-07-19 |
| FC24 | World Championship quarterfinals, semifinals, final | 7 | Exact finals-day date: 2024-07-13 |
| FC25 | World Championship selected R16, all quarterfinals/semifinals/final | 11 | Exact match day unconfirmed; event ends 2025-08-10 |
| FC26 | World Championship R24, R16, quarterfinals, semifinals, final | 23 | Exact match day unknown; event ends 2026-07-26 |

The cohort has at least one result for **7 of the 9 proposed editions**. FIFA20 and FIFA21 have no observations here. An observed edition is not a completed edition: all included events are incomplete, and FIFA22 has only its final. Group/league phases, earlier rounds, some reported events, and third-place matches are absent. FC25 includes four of eight Round-of-16 fixtures whose opponent pairs and scores are explicit in the source; it does not contain the complete bracket. Selection favors the championship path and players who reached later rounds. Rankings describe only the observed cohort; they cannot establish global or career player strength or changes across editions. A missing World Cup or a cancelled event must not be treated as proof that no professional matches occurred in that edition.

## Match records

Raw rows live in `data/raw/public_matches.csv`; each has its own official `source_url`. Recent-event evidence includes [EA's FC24 finals report](https://www.fcpro.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-finals-results) and [EA's FC26 event review](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-26-review). Stable `match_id` values distinguish event and bracket position. These IDs are local curation IDs, not provider API IDs. No unverified extra matches described only in passing were added.

For FC24, the report's July 13 date is corroborated by the dated official posts embedded in [EA's contemporaneous finals-goals article](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-finals-top-5-goals). For FC26, the exact `date` is blank for all 23 rows. `event_end_date=2026-07-26` comes from the [official EWC event record](https://ewc-web.prod.esf-systems.com/en/competitions/2026/eafc), with `date_precision=event_end`. FC25 likewise has blank exact match dates and an event-end bound of 2025-08-10 from Appendix J4.2 of [EA's official FC Pro25 rules](https://www.ea.com/games/ea-sports-fc/fc-pro/ea-sports-fc-pro-25-official-rules). Scheduled round dates alone are not treated as confirmation that every match occurred on schedule. These bounds support an as-of cutoff after the event; they must never be presented as exact match dates. At a cutoff inside either event, these rows cannot be assigned to a day without further evidence.

`score1` and `score2` are the reported match goal totals, including extra time where applicable. They are not penalty shootout totals. Seven rows have `decision=penalties`; these include:

- FC24 semifinal, Jafonso–Yuval: Yuval wins the shootout 8–7, but the report does not state the tied match score. Both goal-score cells remain empty.
- FC26 quarterfinal, Alihanlion–RvPLegend10: match ends 6–6; RvPLegend10 wins the shootout 5–4. The goal-score cells remain 6–6 and the explicit winner resolves the result.

The other five penalty rows are FIFA19 MoAuba–nicolas99fc (5–5 aggregate), FIFA22 Umut–nicolas99fc (0–0 aggregate), and all three FIFA23 semifinals/final. [The official FIFA23 report](https://www.fifa.gg/news/manubachoore-claims-the-fifae-world-champion-title) states a 3–3 final and penalty wins by ManuBachoore over Obrun2002 and Mark11 over PHzin, but no semifinal aggregate totals; those totals remain empty. Thus three fixtures in the full cohort lack goal scores.

All other rows use `decision=score`. A tie resolved by penalties is a decisive match for the win network, and contributes one loser-to-winner edge. The observational unit is a **reported head-to-head bracket fixture or series**, not necessarily an individual leg: FIFA18/19/22/23 two-legged ties count once using aggregate totals, whereas recent single-game fixtures count once. Do not count these rows as the number of individual video-game legs played. No separate leg-level rows duplicate an aggregate result. Historical evidence is [FIFA18](https://inside.fifa.com/news/msdossary-crowned-fifa-eworld-cup-champion), [FIFA19](https://inside.fifa.com/news/moauba-becomes-first-german-to-win-fifa-eworld-cup), and [FIFA22](https://www.fifa.com/en/articles/umut-crowned-world-champion-fifae-world-cup-2022); FC25 outcomes come from [EA's review](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-2025-review). Raw `platform` and `tier` are empty because the selected official reports do not supply a consistent classification; do not silently call these Liquipedia S-Tier or impute a player's console from the event.

## Player identities and missing attributes

`data/raw/public_players.csv` uses stable ASCII IDs. Vejrgang and Anders Vejrgang map to `player_anders_vejrgang`; HezerS/HHezerS, Abu Makkah/AbuMakkah, and Emre Yilmaz/EmreYilmaz are similarly unified across editions. Obrun/Obrun2002 uses `player_obrun`; ManuBachoore retains the same ID across FIFA23/FC25/FC26. No name-based earnings join has been attempted. Club affiliations are not treated as nationality. Country uses ISO two-letter codes only when an official report explicitly states nationality or national-team representation: 15 of 38 players have a country, while all region values remain unknown. Competitive regions need their own sourced, time-aware mapping before RQ2/RQ4 work. Source links establish reported handles; those with an empty country do not assert one.

## Earnings and RQ1 limits

`data/raw/public_earnings.csv` intentionally contains only its schema. There are **zero verified earnings observations**, so PageRank-versus-career-earnings correlation cannot yet be reported. Live public-profile checks on 2026-11-04 returned HTTP200 for Vejrgang and ManuBachoore, but their tables stopped at early2025; ManuBachoore's profile lacked the FC25 World Championship result already established by EA's official event review. The pages therefore did not establish a sufficiently current career snapshot. Cached search extracts for other players were also not imported. These are explicit exclusions for temporal incompleteness, not zero earnings. See the source register for the inspected profiles. An event prize is not career earnings, and a game-specific earnings list is not interchangeable with all-game career totals. Once collected, retain each observation's `scope`, `game_edition`, `as_of`, currency-normalized USD value, provider player ID mapping, and source URL. RQ1's PageRank-versus-win-count comparison can run on this starter cohort, with the sampling limitation visible.

## Expanding the corpus

[Liquipedia's current API terms](https://liquipedia.net/api-terms-of-use) permit API access under their conditions and prohibit automated access to rendered HTML pages. The proposal's `rvest` HTML fallback should therefore be replaced with an approved API export, permitted MediaWiki API access, or manual curation. Cache API responses and preserve required attribution/licensing. LPDB access and exact request/response documentation require approval; no application was submitted here. Its [API overview](https://liquipedia.net/api) lists educational free-access eligibility, an open-source-code requirement, and generally limited duration.

The [Esports Earnings API](https://www.esportsearnings.com/apidocs) requires a personal key and agreement to its developer terms. Its documented maximum is one call per second, with cached results and explicit API error checks. No credential was supplied and no earnings request was made. Keys belong in local ignored credentials, never CSVs or commits.

Before research conclusions or the mid-project submission: acquire and audit the broader match corpus, verify provider identity joins, collect properly scoped earnings as of a known date, fill edition coverage, and quantify missing platform/region/tier attributes. `data/raw/sources.csv` records source purpose, retrieval date, and the limits of each imported subset.
