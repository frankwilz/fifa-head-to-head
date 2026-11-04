# API access and data imports

No account applications or API calls have been submitted for this project. The checked-in pipeline runs without credentials on the attributed public sample. Full historical collection remains pending.

## Esports Earnings

The [official v0 documentation](https://www.esportsearnings.com/apidocs) requires a registered API key and agreement to its development terms. It specifies a maximum of one request per second and local caching. IDs come from source URLs; never infer IDs by matching handles alone. Documentation reviewed November 4, 2026.

`R/api_clients.R` implements eight documented player, game and individual-tournament methods. Requests use HTTPS only; the legacy HTTP examples in the documentation are not used. If HTTPS fails, the client stops. `LookupHighestEarningPlayersByGame` reports game-specific totals; `LookupPlayerById` reports career totals across all games, which must not be mislabeled as FIFA-only earnings.

From the repository root:

```sh
Rscript scripts/fetch_api.R
cp config/api-jobs.example.csv config/api-jobs.local.csv
# Edit this local CSV to contain reviewed player/game/tournament IDs.
# Set ESPORTS_EARNINGS_API_KEY in your shell or local environment manager.
Rscript scripts/fetch_api.R config/api-jobs.local.csv
Rscript scripts/fetch_api.R config/api-jobs.local.csv --live
```

The first two script invocations print a request plan and make no network requests. Live mode requires an explicit jobs file and a local environment key. It reuses cached successes unless `--refresh` is supplied. Run one fetch process at a time: the 1.05 second throttle is shared within one R process, not across concurrent processes. There are no automatic retries; inspect failures before retrying.

The job columns are `method,playerid,gameid,tournamentid,offset`. Leave irrelevant fields blank; methods and parameter combinations are checked before a request. Offset defaults to zero for list methods. To collect subsequent pages, add explicit rows with offsets 100, 200, and so on after reviewing prior coverage. Programmatic `earnings_pages(method, params, max_pages=...)` provides bounded pagination and stops on a page shorter than 100 records. Its default is one page.

Successful raw responses and retrieval metadata are stored under `data/raw/esports-earnings/`. Error bodies, keys and request URLs are never written by this client. The API key is supplied to curl through standard input, not command arguments. Keep `.env`, local jobs, raw caches and credentials out of Git. API cache files are inputs for review, not automatically normalized analysis tables.

Normalize reviewed earnings into ignored `data/input/earnings.csv` with columns `player_id,scope,game_edition,earnings_usd,as_of,source_url`. Preserve the source's scope (`career` or `edition`), verify game and player identity, retain the retrieval/as-of date, and never use a later snapshot for the November 4 cutoff. Missing earnings stay missing. A current career total is not a historical snapshot. If converting `LookupPlayerTournaments` results, use the documented `Prize`, `ExchangeRate` and `TeamPlayers` fields carefully and explicitly filter `GameId`; do not sum mixed currencies or assign team totals to each player. Do not include unknown-player placeholders. Placements and prize records alone are not head-to-head match records.

## Liquipedia

[Liquipedia's API access page](https://liquipedia.net/api) is the access entry point. The API overview and terms were reviewed through publicly indexed official documentation; direct access to some pages returned HTTP 403. No authenticated LPDB endpoint or query schema has been verified. Current [API terms](https://liquipedia.net/api-terms-of-use) prohibit automated access to rendered HTML. Educational access lists time-limited and open-source-code conditions; the repository has not yet selected an open-source license. No bypass or HTML scraping client is included. Confirm the access offer, license, rate limits and attribution requirements with the provider before collection.

Request approved educational access yourself if appropriate, retain the applicable terms, attribution requirements and versioned API schema, then supply an authorized export. Keep the original export under ignored `data/raw/private/` with its retrieval date and source. Map it into the canonical schema described in `docs/data-dictionary.md`, verifying that rows represent professional **1v1** matches. One row should represent one resolved competitive match/series; do not count both an aggregate series and its legs. Resolve aliases to stable `player_id` values, retain original source IDs in the raw export, preserve decisions by penalties without inventing regulation scores, and exclude unresolved/tied matches from the win network. Imports should pass the project's validation before analysis. Put reviewed canonical tables in `data/input/` and run `Rscript scripts/run_pipeline.R --input-dir=data/input`; writing to `data/clean/` directly would be overwritten by the default public-data run.

Full FIFA 18 through FC 26 coverage and earnings comparisons remain pending approved data collection and reconciliation. The API preparation is executable infrastructure, not evidence that that collection has occurred.
