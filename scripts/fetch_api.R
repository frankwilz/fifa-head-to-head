#!/usr/bin/env Rscript
# Run from the repository root. Default operation is a no-network dry run.
source("R/api_clients.R")
args <- commandArgs(trailingOnly = TRUE)
live <- "--live" %in% args
refresh <- "--refresh" %in% args
paths <- args[!args %in% c("--live", "--refresh")]
if (length(paths) > 1L) stop("Usage: Rscript scripts/fetch_api.R [jobs.csv] [--live] [--refresh]", call. = FALSE)
if (live && !length(paths)) stop("Live requests require an explicit reviewed jobs CSV.", call. = FALSE)
jobs_path <- if (length(paths)) paths else "config/api-jobs.example.csv"
jobs <- read.csv(jobs_path, stringsAsFactors = FALSE, colClasses = "character",
                 na.strings = c("", "NA"))
required <- c("method", "playerid", "gameid", "tournamentid", "offset")
if (!all(required %in% names(jobs))) stop("Jobs CSV columns must match config/api-jobs.example.csv.", call. = FALSE)
plans <- lapply(seq_len(nrow(jobs)), function(i) {
  params <- as.list(jobs[i, setdiff(required, "method"), drop = FALSE])
  params <- params[!vapply(params, function(v) is.na(v) || !nzchar(v), logical(1))]
  list(method = jobs$method[[i]], params = validate_earnings_job(jobs$method[[i]], params))
})
cat(if (live) "Live mode; successful responses will be cached locally.\n" else
    "DRY RUN: no API keys read and no network requests made.\n")
for (plan in plans) {
  cat(plan$method, paste(names(plan$params), unlist(plan$params), sep = "=", collapse = " "), "\n")
  if (live) {
    result <- earnings_request(plan$method, plan$params, refresh = refresh)
    cat(if (result$cached) "  reused cache\n" else "  cached response\n")
  }
}
if (!live) cat("Edit a copy with verified source IDs; add --live only after setting the local environment key.\n")
