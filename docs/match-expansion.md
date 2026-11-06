# Public match expansion — 6 November 2026

The added cohort contains 80 real results from official competition organisers: seven FIFA20 ePremier League finals-day series, all 71 series of the FIFA21 ePremier League finals event, and two FIFA22 eChampions League results. The combined public input now has 129 results and 81 players across all nine proposed editions. Representation of an edition does not imply complete historical coverage.

## Evidence and transcription

| Source | Added records | Date | Coverage |
| --- | ---: | --- | --- |
| [Premier League: 2019/20 champion](https://www.premierleague.com/en/news/1786632) | 7 | 2020-08-28 | Complete closing finals-day bracket; earlier rounds remain absent |
| [Premier League: FIFA21 Xbox results](https://www.premierleague.com/en/news/2075924) | 32 | 2021-03-23 | Four groups of seven series, then four quarterfinals |
| [Premier League: FIFA21 PS4 results](https://www.premierleague.com/en/news/2076123) | 32 | 2021-03-24 | Four groups of seven series, then four quarterfinals |
| [Premier League: FIFA21 finals day](https://www.premierleague.com/en/news/2077050) | 7 | 2021-03-26 | Four semifinals, two console finals, one cross-console grand final |
| [UEFA: Stockholm finals recap](https://www.uefa.com/uefachampionsleague/news/0275-1540e9292923-a32a5d102020-1000--stars-shine-as-echampions-league-finals-wow-stockholm/) | 1 | 2022-05-27 | Nicolas99FC's explicit victory over Tekkz |
| [EA: Nicolas99fc career recap](https://www.ea.com/games/ea-sports-fc/fc-pro/news/fc-pro-open-or-how-to-watch-match-week-6) | 1 | 2022-05-27 | eChampions League final victory over Matias Bonanno |

These are manually transcribed source-listed results. The companion `data/raw/match_sources_expansion.csv` records URLs, retrieval date, coverage, and interpretation notes. No results were inferred from tournament placement. The source order of group fixtures is preserved in match IDs (`group_a_1` through `group_a_7`, and likewise for groups B–D). This distinguishes genuine rematches of the same opponents from duplicate records.

The FIFA21 full finals event comprises 28 group fixtures plus four quarterfinals per console, four semifinals, two console finals, and the grand final: `32 + 32 + 7 = 71`. Each player represents one club on one console. These remain individual 1v1 results; club representation does not turn them into team matches.

## Sampling and identity decisions

- A result is one source-listed competitive series or aggregate tie, not one video-game leg. The FIFA20/21 multi-leg ties each contribute one edge-weight unit. The cross-console finals are marked `cross-console`, while other ePL fixtures use the explicitly reported PlayStation 4 or Xbox One platform.
- Equal goal aggregates followed by an explicit penalty winner remain decisive results with `decision=penalties`. Shootout totals are not entered as goal scores. For example, the FIFA21 grand final retains 6–6 goals with Shellzz as winner; the 4–2 shootout is recorded in the source manifest only.
- FIFA22 goal totals are left blank: the UEFA final recap and EA retrospective use conflicting goal accounting. Both identify the final winner. The final championship tie is counted once. Unnamed opponents and the celebrity Icon Face Off exhibition are excluded.
- All added dates are source-supported exact days; original event-end-only dates elsewhere in the dataset remain unchanged.
- `regional` means a national league event in this study, including the domestic ePL finals. `major` means the international marquee eChampions League event. These labels are research classifications, not imported official or Liquipedia tiers. They permit a limited world/major-versus-domestic sensitivity comparison; they do not establish coverage of small regional cups or open qualifiers.
- Legal names in official results resolve aliases: Hashtag Tom/HashtagTom_ → `player_tom_leese`; MarcMarleyyy → `player_marc_marley`; Hammond/SAF Hammond → `player_kyle_hammond`; FalconsDiogo → `player_diogo_mendes`; SAF Dragon → `player_dragon`; NKSNB → `player_niksneb`; Matias/MatiasBonanno99 → existing `player_bonanno`; Fnatic Tekkz → existing `player_tekkz`. Other source handles remain visible in `public_players.csv`.
- Residence eligibility and a represented club are insufficient evidence of nationality or competitive region. New country/region cells remain unknown rather than being guessed.

## Remaining coverage limits

FIFA20 has only the closing ePL bracket, and FIFA22 has three results total when combined with the existing world final. The complete FIFA21 finals event is one domestic competition, not a census of that edition. Regional events have now been observed, but small-cup and qualifier coverage is still absent. The results support an executable coverage-sensitive analysis; global strongest-player conclusions still require broader match collection.
