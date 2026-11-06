# Earnings measurements and provenance

Snapshot retrieved **2026-11-06**. The public profiles support **provider-recorded earnings**, a usable comparison variable with documented coverage limits. They do not establish complete actual lifetime earnings. An earlier decision to leave every earnings value unavailable because some tournament results were missing was too restrictive: a provider's reported total remains an observable measurement even when the database is incomplete.

## Files and coverage

| File | Contents |
| --- | --- |
| `data/raw/public_earnings.csv` | 48 career observations and 222 edition observations, 270 measurements total |
| `data/raw/earnings_sources.csv` | 48 verified profile identities, public URLs, server response dates, titles, reported tournament counts, latest recorded year, and source HTML SHA-256 |
| `data/raw/profile_attributes.csv` | 48 source-backed provider country flags, with profile URL and retrieval date |

There are earnings observations for **48 of the current 81 graph players**, including **34 of the original 38 players**. The additional 14 are Damie, Diogo Mendes, EthxnH, Gorilla, HashtagShawrey, Jayden Groden, NiKSNEB, Ollelito, Shellzz, Stingrayjnr, Stokes, Tass, Tom Leese, and Venny. The original cohort's unverified players are Jafonso, LuukWijdeveld, Nassada, and Alihanlion. Public searches did not resolve a matching provider profile for them; unrelated similarly named profiles were excluded. Other unmatched players in the expanded graph remain missing pending identity verification. Missing values mean **unobserved**, not zero.

Each profile was retrieved by an ordinary HTTPS GET, without credentials or a third-party API key. Every accepted response was HTTP 200 with a server `Date` on 2026-11-06, between **20:32:53 and 20:38:09 UTC**. Requests were paced; no blocked response or access protection was bypassed. Search/index pages supplied candidate profile URLs, while the imported amounts came from the directly retrieved profile HTML. Raw HTML and response headers remain intermediate evidence outside the repository under the chat's `work/earnings-nov6/` directory; the committed source register retains URLs, dates, and content hashes. The profile pages are public source material, not project instructions.

## Measurement definitions

`scope=career` records the profile's **Total Prize Money Earned** amount in USD, across all games and tournaments included by that provider. `game_edition` is empty for career observations. `measurement=provider_recorded_career_total` and `coverage_status=provider_recorded_incomplete` make the interpretation explicit. Career totals may include titles before FIFA18, and may include national-team or club events outside the graph's 1v1 sample. This is the requested career comparison, rather than earnings from only the observed match fixtures.

`scope=edition` records the **Total Results** amount for the named title in the profile's **Earnings By Game** table. It is separate from calendar-year totals, online-only winnings, tournament prizes, and team totals. Only titles actually listed by the provider were imported. The edition code map is FIFA18–FIFA23 for FIFA 18–23 and FC24–FC26 for EA Sports FC 24–26. `measurement=provider_recorded_edition_total` distinguishes these observations. An absent game row was not converted to zero.

| Edition | Players with a listed earnings total |
| --- | ---: |
| FIFA18 | 11 |
| FIFA19 | 17 |
| FIFA20 | 21 |
| FIFA21 | 28 |
| FIFA22 | 34 |
| FIFA23 | 39 |
| FC24 | 39 |
| FC25 | 28 |
| FC26 | 5 |

A focused FIFA20 follow-up verified [Alex “Shawrey” Shaw](https://www.esportsearnings.com/players/57103-shawrey-alex-shaw), whose alternate ID is Hashtag Shawrey, and [Owen “Venny” Venn](https://www.esportsearnings.com/players/57203-venny-owen-venn). Both profiles explicitly list a FIFA20 total. No matching provider profile was established for Callum Moore or Kyle Hammond. Marc Marley has two separate provider profiles with the same real name and an unresolved duplication risk, so neither was merged into this snapshot. Jamboo's provider page has unresolved name/country metadata discrepancies and was also left unmatched pending review.

These are counts across the collected graph-player profiles, not necessarily the number of players appearing in each edition's graph. Analysis must join earnings to the relevant graph's players and report its resulting sample size.

`as_of=2026-11-06` means the **retrieval date of the displayed provider snapshot**. It does not mean every tournament ending by that date is present. It must not be used to create a historical earnings snapshot for an earlier analysis cutoff. A report dated before November 6 needs an earlier documented observation or a properly reconstructed historical result ledger.

## Incompleteness and identity checks

The current provider records visibly omit some results. For example, [ManuBachoore's profile](https://www.esportsearnings.com/players/110315-manubachoore-manuel-bachoore) lacks the FC25 World Championship result described in [EA's official review](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-world-championship-2025-review). His displayed total is retained as a provider measurement; the missing event prize is **not** manually added to it. Such an adjustment could double-count other records or combine incompatible scope and dates. The source register's `latest_recorded_year` is an audit aid, not proof that the provider covers all tournaments in that year. Only five inspected profiles listed any 2026 results.

Profile identities were matched using reported handles, alternate IDs, real names, and FIFA/EA FC context. Stable local IDs preserve aliases including Vejrgang/Anders Vejrgang, Matias/Bonanno, AboMakkah/AbuMakkah, Mo_aubameyang/MoAuba, RvPLegend/RvPLegend10, levyfinn02/levyfinn, KARIMISBACK/Karimisbak, Samugamer_07/Samugamer, and YuvalBeli/Yuval. The similarly named Fortnite player Phzin was excluded; the selected FIFA player's profile identifies Paulo Henrique Chaves.

[Harry Hesketh's provider profile](https://www.esportsearnings.com/players/38683-harry-hesketh) combines a FIFA biography with Call of Duty Challengers results and an Aphelion Esports affiliation. This raises an unresolved identity-conflation concern. Its career total and attributes were excluded rather than silently correcting the provider record or accepting an ambiguous total. This is distinct from ordinary missing tournament coverage.

Country observations are the provider's displayed country flags. They are useful sourced attributes, but do not prove historical residence, citizenship at each match, or eligibility in a competitive qualifying region. In particular, Karimisbak's provider flag is Italy. Do not derive a historical competitive region from the flag without a separately documented mapping and its limitations. Existing better-supported country observations should be reconciled by provenance rather than overwritten automatically.

## Valid use in RQ1

The earnings comparison can now run on matched observations, reporting **PageRank versus provider-recorded career earnings** for the combined graph and **PageRank versus provider-recorded edition earnings** within an edition. State the matched player count, excluded/missing players, snapshot date, and incomplete provider coverage. Use pairwise complete observations and average ranks for ties. Small edition samples, especially FC26, need explicit sample sizes and cautious interpretation.

The match sample favors selected tournaments and late knockout rounds, while earnings accumulate over a much broader career or title history. Neither correlation nor a rank discrepancy establishes a causal effect, a definitive global ranking, or the true completeness of either source. The code should preserve missing values, not manufacture full coverage merely to produce a correlation.

Checks passed for unique player/scope/edition/date keys, known graph-player IDs, nonnegative USD values, valid scope/edition pairing, source-response dates, and ISO two-letter country formatting. For each player, the sum of imported edition totals does not exceed the reported all-game career total beyond a small rounding allowance. Raw matches and player identity files were not changed by this earnings import.
