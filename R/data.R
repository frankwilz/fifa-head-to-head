read_project_csv <- function(path, required) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  x <- utils::read.csv(path, colClasses = "character", na.strings = c("", "NA"),
                       check.names = FALSE, stringsAsFactors = FALSE)
  if (anyDuplicated(names(x))) stop(basename(path), ": duplicate column names", call. = FALSE)
  missing <- setdiff(required, names(x))
  if (length(missing)) stop(basename(path), ": missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  x[] <- lapply(x, function(v) { v <- trimws(v); v[v == ""] <- NA_character_; v })
  x
}

validate_inputs <- function(matches, players, earnings, cutoff, editions) {
  if (!inherits(cutoff, "Date") || length(cutoff) != 1L || is.na(cutoff) ||
      !is.finite(as.numeric(cutoff))) {
    stop("Analysis cutoff must be one valid Date.", call. = FALSE)
  }
  if (!length(editions) || anyNA(editions) || any(!nzchar(editions))) {
    stop("Supported game editions must be nonempty strings.", call. = FALSE)
  }
  issues <- data.frame(table = character(), row = integer(), id = character(),
                       severity = character(), reason = character(), stringsAsFactors = FALSE)
  add <- function(table, rows, ids, severity, reason) {
    if (length(rows)) issues <<- rbind(issues, data.frame(table = table, row = rows,
      id = ids[rows], severity = severity, reason = reason, stringsAsFactors = FALSE))
  }
  date_safe <- function(x) suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  valid_date <- function(x) { d <- date_safe(x); !is.na(d) & format(d, "%Y-%m-%d") == x }
  blank <- function(x) is.na(x) | !nzchar(trimws(as.character(x)))
  sourced_url <- function(x) !is.na(x) & grepl("^https://[^/?#[:space:]]+([/?#][^[:space:]]*)?$", x)
  pids <- players$player_id
  add("players", which(blank(pids) | blank(players$handle)), pids, "error", "missing player_id or handle")
  add("players", which(duplicated(pids) | duplicated(pids, fromLast = TRUE)), pids, "error", "duplicate player_id")
  add("players", which(!sourced_url(players$source_url)), pids, "error", "players need HTTPS source URL")
  ids <- matches$match_id
  required <- c("match_id", "game_edition", "tournament_id", "player1_id", "player2_id", "source_url")
  for (nm in required) add("matches", which(blank(matches[[nm]])), ids, "error", paste("missing", nm))
  add("matches", which(!is.na(ids) & (duplicated(ids) | duplicated(ids, fromLast = TRUE))), ids, "error", "duplicate match_id; resolve at source")
  add("matches", which(!matches$game_edition %in% editions), ids, "error", "unsupported game edition")
  for (nm in c("player1_id", "player2_id"))
    add("matches", which(!is.na(matches[[nm]]) & !matches[[nm]] %in% pids), ids, "error", paste("unknown", nm))
  add("matches", which(!is.na(matches$player1_id) & matches$player1_id == matches$player2_id), ids, "error", "self match")
  excluded <- rep(FALSE, nrow(matches))
  if (!"match_format" %in% names(matches)) matches$match_format <- "1v1"
  not_1v1 <- is.na(matches$match_format) | matches$match_format != "1v1"
  is_draw <- matches$decision %in% "draw"
  decisive_decision <- matches$decision %in% c("score", "regulation", "aggregate", "extra_time", "penalties")
  no_result <- !(is_draw | decisive_decision) |
    decisive_decision & (blank(matches$winner_id) | blank(matches$loser_id))
  add("matches", which(not_1v1), ids, "excluded", "outside individual 1v1 scope")
  add("matches", which(no_result), ids, "excluded", "not a completed competitive result (scheduled/walkover/unresolved)")
  excluded <- not_1v1 | no_result
  completed <- !excluded
  invalid_pair <- completed & !is_draw & !(matches$winner_id == matches$player1_id & matches$loser_id == matches$player2_id |
                               matches$winner_id == matches$player2_id & matches$loser_id == matches$player1_id)
  add("matches", which(invalid_pair), ids, "error", "winner and loser must be the two distinct participants")
  add("matches", which(completed & is_draw &
    (!is.na(matches$winner_id) | !is.na(matches$loser_id))), ids, "error", "draw must have no winner or loser")
  if (!"event_end_date" %in% names(matches)) matches$event_end_date <- NA_character_
  if (!"date_precision" %in% names(matches)) matches$date_precision <- ifelse(is.na(matches$date), "event_end", "day")
  bad_date <- !is.na(matches$date) & !valid_date(matches$date)
  bad_end <- !is.na(matches$event_end_date) & !valid_date(matches$event_end_date)
  add("matches", which(bad_date | bad_end), ids, "error", "dates must be valid ISO YYYY-MM-DD")
  missing_date <- is.na(matches$date) & is.na(matches$event_end_date)
  add("matches", which(missing_date), ids, "error", "need exact date or sourced event end date")
  precision_ok <- ifelse(is.na(matches$date), matches$date_precision %in% "event_end",
                        matches$date_precision %in% "day")
  add("matches", which(!precision_ok), ids, "error", "date_precision must describe date or event_end fallback")
  reversed_dates <- !bad_date & !bad_end & !is.na(matches$date) &
    !is.na(matches$event_end_date) & date_safe(matches$date) > date_safe(matches$event_end_date)
  add("matches", which(reversed_dates), ids, "error", "match date is after event end date")
  known_date <- ifelse(is.na(matches$date), matches$event_end_date, matches$date)
  after_cutoff <- !is.na(date_safe(known_date)) & date_safe(known_date) > cutoff
  add("matches", which(after_cutoff), ids, "excluded", "after analysis cutoff")
  excluded <- excluded | after_cutoff
  add("matches", which(is.na(matches$date) & !missing_date), ids, "warning", "exact match day unknown; event end used only for cutoff")
  for (nm in c("score1", "score2")) {
    score <- suppressWarnings(as.numeric(matches[[nm]]))
    invalid <- !is.na(matches[[nm]]) & (!is.finite(score) | score < 0 | score != floor(score))
    add("matches", which(invalid), ids, "error", paste("invalid", nm))
  }
  s1 <- suppressWarnings(as.numeric(matches$score1)); s2 <- suppressWarnings(as.numeric(matches$score2))
  normal <- completed & matches$decision %in% c("score", "regulation", "aggregate", "extra_time") & !is.na(s1) & !is.na(s2)
  inconsistent <- normal & (s1 == s2 | s1 > s2 & matches$winner_id != matches$player1_id |
                            s2 > s1 & matches$winner_id != matches$player2_id)
  add("matches", which(inconsistent), ids, "error", "score disagrees with decisive winner")
  unequal_draw <- completed & is_draw & !is.na(s1) & !is.na(s2) & s1 != s2
  add("matches", which(unequal_draw), ids, "error", "draw scores must be equal when both are reported")
  add("matches", which(!sourced_url(matches$source_url)), ids, "error", "need HTTPS source URL")
  if (nrow(earnings)) {
    eids <- earnings$player_id
    add("earnings", which(is.na(eids) | !eids %in% pids), eids, "error", "unknown player_id")
    add("earnings", which(!earnings$scope %in% c("career", "edition")), eids, "error", "scope must be career or edition")
    add("earnings", which(earnings$scope == "edition" & !earnings$game_edition %in% editions), eids, "error", "edition earnings need valid edition")
    add("earnings", which(earnings$scope == "career" & !blank(earnings$game_edition)), eids, "error", "career earnings must leave game_edition empty")
    value <- suppressWarnings(as.numeric(earnings$earnings_usd))
    add("earnings", which(is.na(value) | value < 0 | !is.finite(value)), eids, "error", "earnings must be nonnegative finite USD")
    add("earnings", which(is.na(earnings$as_of) | !valid_date(earnings$as_of)), eids, "error", "earnings need valid as_of date")
    add("earnings", which(!sourced_url(earnings$source_url)), eids, "error", "earnings need HTTPS source URL")
    key <- paste(earnings$player_id, earnings$scope, ifelse(is.na(earnings$game_edition), "", earnings$game_edition), earnings$as_of)
    add("earnings", which(duplicated(key) | duplicated(key, fromLast = TRUE)), eids, "error", "duplicate earnings snapshot")
    earnings$earnings_usd <- value
    future_earnings <- !is.na(date_safe(earnings$as_of)) & date_safe(earnings$as_of) > cutoff
    add("earnings", which(future_earnings), eids, "excluded", "earnings snapshot after cutoff")
    earnings <- earnings[!future_earnings, , drop = FALSE]
  } else earnings$earnings_usd <- numeric()
  list(matches = matches[!excluded, , drop = FALSE], players = players, earnings = earnings,
       issues = issues, has_errors = any(issues$severity == "error"), input_matches = nrow(matches))
}

load_inputs <- function(input_dir, cutoff, editions) {
  m <- read_project_csv(file.path(input_dir, "matches.csv"), c("match_id", "date", "game_edition", "tournament_id", "player1_id", "player2_id", "winner_id", "loser_id", "platform", "tier", "score1", "score2", "decision", "source_url"))
  p <- read_project_csv(file.path(input_dir, "players.csv"), c("player_id", "handle", "country", "region", "source_url"))
  e <- read_project_csv(file.path(input_dir, "earnings.csv"), c("player_id", "scope", "game_edition", "earnings_usd", "as_of", "source_url"))
  validate_inputs(m, p, e, cutoff, editions)
}
