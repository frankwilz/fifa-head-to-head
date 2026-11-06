# The win graph sends prestige from each loser to the opponent who beat them.
# A directed edge's weight counts decisive match records, not goal margin.
# PageRank scores remain unrounded in exported tables. Ranking and Spearman
# comparisons use 12 significant digits so solver roundoff (for example, 1e-17
# differences between symmetric nodes) cannot create artificial rank differences.

analysis_pagerank_tie_score <- function(x) signif(x, digits = 12L)

analysis_is_draw <- function(matches) {
  if (!"decision" %in% names(matches)) return(rep(FALSE, nrow(matches)))
  !is.na(matches$decision) & tolower(trimws(as.character(matches$decision))) == "draw"
}

analysis_empty_rankings <- function() {
  data.frame(
    scope = character(), player_id = character(), handle = character(),
    country = character(), region = character(), pagerank = numeric(),
    pagerank_rank = numeric(), wins = numeric(), losses = numeric(), draws = numeric(),
    matches_played = numeric(), win_rate = numeric(), opponents = numeric(),
    opponents_beaten = numeric(), opponents_lost_to = numeric(),
    wins_rank = numeric(), earnings_usd = numeric(), earnings_as_of = character(), earnings_measurement = character(),
    earnings_coverage_status = character(), earnings_source_url = character(),
    earnings_rank = numeric(), pagerank_rank_earnings_subset = numeric(), pagerank_minus_wins_rank = numeric(),
    pagerank_minus_earnings_rank = numeric(), stringsAsFactors = FALSE
  )
}

analysis_empty_metrics <- function() {
  data.frame(
    scope = character(), nodes = integer(), matches = integer(), decisive_matches = integer(), draw_matches = integer(),
    win_edges = integer(), played_edges = integer(), density_win = numeric(),
    density_played = numeric(), mean_degree_played = numeric(),
    mean_in_degree = numeric(), mean_out_degree = numeric(), mean_wins = numeric(),
    mean_matches_played = numeric(), weak_components_win = integer(),
    strong_components_win = integer(), components_played = integer(),
    giant_component_nodes = integer(), giant_component_fraction = numeric(),
    transitivity_played = numeric(), stringsAsFactors = FALSE
  )
}

analysis_empty_correlations <- function() {
  data.frame(scope = character(), comparison = character(), n_complete = integer(),
             spearman_rho = numeric(), status = character(), stringsAsFactors = FALSE)
}

analysis_empty_distribution <- function() {
  data.frame(scope = character(), degree = numeric(), players = integer(),
             proportion = numeric(), stringsAsFactors = FALSE)
}

analysis_empty_random <- function() {
  data.frame(
    scope = character(), model = character(), replicates = integer(), seed = integer(),
    nodes = integer(), played_edges = integer(), observed_giant_fraction = numeric(),
    random_giant_mean = numeric(), random_giant_q025 = numeric(),
    random_giant_q975 = numeric(), observed_transitivity = numeric(),
    random_transitivity_finite_replicates = integer(), random_transitivity_mean = numeric(), random_transitivity_q025 = numeric(),
    random_transitivity_q975 = numeric(), stringsAsFactors = FALSE
  )
}

analysis_spearman <- function(scope, comparison, x, y) {
  keep <- is.finite(x) & is.finite(y)
  x <- x[keep]
  y <- y[keep]
  status <- if (length(x) < 3L) {
    "insufficient_complete_pairs"
  } else if (length(unique(x)) < 2L || length(unique(y)) < 2L) {
    "constant_variable"
  } else {
    "computed"
  }
  data.frame(scope = scope, comparison = comparison, n_complete = length(x),
             spearman_rho = if (status == "computed") stats::cor(x, y, method = "spearman") else NA_real_,
             status = status, stringsAsFactors = FALSE)
}

# Retain the most recent eligible earnings observation for this scope. Career
# totals are compared only with the combined network; edition totals only with
# that edition. Missing observations remain NA, including in ranking.
analysis_earnings <- function(ids, scope, earnings, cutoff) {
  result <- data.frame(player_id = ids, earnings_usd = NA_real_,
                       earnings_as_of = NA_character_, earnings_measurement = NA_character_,
                       earnings_coverage_status = NA_character_, earnings_source_url = NA_character_, stringsAsFactors = FALSE)
  if (is.null(earnings) || nrow(earnings) == 0L) return(result)
  required <- c("player_id", "scope", "game_edition", "earnings_usd", "as_of", "source_url")
  if (!all(required %in% names(earnings))) stop("Earnings table is missing required columns.")
  dates <- as.Date(as.character(earnings$as_of))
  allowed <- !is.na(dates) & dates <= cutoff
  if (scope == "combined") {
    allowed <- allowed & !is.na(earnings$scope) & earnings$scope == "career"
  } else {
    allowed <- allowed & !is.na(earnings$scope) & earnings$scope == "edition" &
      !is.na(earnings$game_edition) & earnings$game_edition == scope
  }
  eligible <- earnings[which(allowed), , drop = FALSE]
  if (nrow(eligible) == 0L) return(result)
  eligible$as_of <- as.Date(as.character(eligible$as_of))
  eligible <- eligible[order(eligible$player_id, eligible$as_of, decreasing = TRUE), , drop = FALSE]
  # Multiple different values for one player on the same observation date must
  # be resolved during cleaning rather than selected by input row order.
  observation_key <- paste(eligible$player_id, eligible$as_of, sep = "\r")
  if (anyDuplicated(observation_key)) stop("Duplicate earnings observations; normalize before analysis.")
  eligible <- eligible[!duplicated(eligible$player_id), , drop = FALSE]
  values <- suppressWarnings(as.numeric(as.character(eligible$earnings_usd)))
  if (any(!is.finite(values) | values < 0)) stop("Earnings values must be finite and nonnegative.")
  at <- match(ids, eligible$player_id)
  result$earnings_usd <- values[at]
  result$earnings_as_of <- as.character(eligible$as_of[at])
  result$earnings_source_url <- eligible$source_url[at]
  result$earnings_measurement <- if ("measurement" %in% names(eligible)) eligible$measurement[at] else ifelse(is.na(at), NA_character_, "provider_recorded_total")
  result$earnings_coverage_status <- if ("coverage_status" %in% names(eligible)) eligible$coverage_status[at] else ifelse(is.na(at), NA_character_, "completeness_unverified")
  result
}

analysis_graphs <- function(matches, players) {
  ids <- sort(unique(c(matches$player1_id, matches$player2_id)))
  vertices <- data.frame(name = ids, players[match(ids, players$player_id),
                                           setdiff(names(players), "player_id"), drop = FALSE],
                         stringsAsFactors = FALSE)
  decisive <- matches[!analysis_is_draw(matches), , drop = FALSE]
  win_edges <- if (nrow(decisive)) {
    stats::aggregate(list(weight = rep.int(1L, nrow(decisive))),
                     list(from = decisive$loser_id, to = decisive$winner_id), sum)
  } else {
    data.frame(from = character(), to = character(), weight = numeric(), stringsAsFactors = FALSE)
  }
  played_edges <- stats::aggregate(list(weight = rep.int(1L, nrow(matches))),
    list(from = pmin(matches$player1_id, matches$player2_id),
         to = pmax(matches$player1_id, matches$player2_id)), sum)
  list(win = igraph::graph_from_data_frame(win_edges, directed = TRUE, vertices = vertices),
       played = igraph::graph_from_data_frame(played_edges, directed = FALSE, vertices = vertices))
}

analysis_random_baseline <- function(scope, played, replicates = 100L) {
  # Preserve the caller's RNG. G(n,m) fixes edge count, so its density and mean
  # degree equal the observed graph by construction; compare structure instead.
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  codepoints <- utf8ToInt(scope)
  seed <- as.integer(20261104 + sum(codepoints * seq_along(codepoints)))
  set.seed(seed)
  n <- igraph::vcount(played)
  m <- igraph::ecount(played)
  summaries <- replicate(replicates, {
    random <- igraph::sample_gnm(n, m, directed = FALSE, loops = FALSE)
    c(giant = max(igraph::components(random)$csize) / n,
      transitivity = igraph::transitivity(random, type = "global", isolates = "NaN"))
  })
  describe <- function(x) {
    x <- x[is.finite(x)]
    if (!length(x)) return(c(mean = NA_real_, q025 = NA_real_, q975 = NA_real_))
    c(mean = mean(x), q025 = unname(stats::quantile(x, .025)),
      q975 = unname(stats::quantile(x, .975)))
  }
  giant <- describe(summaries["giant", ])
  clustering <- describe(summaries["transitivity", ])
  data.frame(scope = scope, model = "G(n,m), undirected, no loops", replicates = replicates,
    seed = seed, nodes = n, played_edges = m,
    observed_giant_fraction = max(igraph::components(played)$csize) / n,
    random_giant_mean = giant["mean"], random_giant_q025 = giant["q025"],
    random_giant_q975 = giant["q975"],
    observed_transitivity = igraph::transitivity(played, type = "global", isolates = "NaN"),
    random_transitivity_finite_replicates = sum(is.finite(summaries["transitivity", ])),
    random_transitivity_mean = clustering["mean"],
    random_transitivity_q025 = clustering["q025"], random_transitivity_q975 = clustering["q975"],
    row.names = NULL, stringsAsFactors = FALSE)
}

analyze_networks <- function(matches, players, earnings = NULL, cutoff = as.Date("2026-11-06")) {
  if (!requireNamespace("igraph", quietly = TRUE)) stop("Install igraph before running analysis.")
  cutoff <- as.Date(cutoff)
  if (length(cutoff) != 1L || is.na(cutoff)) stop("cutoff must be one valid date.")
  required_matches <- c("match_id", "date", "game_edition", "tournament_id", "player1_id",
    "player2_id", "winner_id", "loser_id", "platform", "tier", "source_url")
  if (!all(required_matches %in% names(matches))) stop("Matches table is missing required columns.")
  if (!all(c("player_id", "handle", "country", "region") %in% names(players))) {
    stop("Players table is missing required columns.")
  }
  if (anyNA(players$player_id) || anyDuplicated(players$player_id)) stop("Player IDs must be unique and nonmissing.")
  dates <- as.Date(as.character(matches$date))
  # When a source reports the result but not its match day, the event's end
  # provides a conservative eligibility boundary. Do not overwrite match dates
  # or represent the event end as an observed date of play.
  if ("event_end_date" %in% names(matches)) {
    unknown <- is.na(dates)
    dates[unknown] <- as.Date(as.character(matches$event_end_date[unknown]))
  }
  matches <- matches[which(!is.na(dates) & dates <= cutoff), , drop = FALSE]
  result <- list(graphs = list(), metrics = analysis_empty_metrics(),
    rankings = analysis_empty_rankings(), correlations = analysis_empty_correlations(),
    degree_distribution = analysis_empty_distribution(), random_baseline = analysis_empty_random())
  if (!nrow(matches)) return(result)
  ids <- c(matches$player1_id, matches$player2_id)
  if (anyNA(ids) || any(!ids %in% players$player_id)) stop("Every match participant must have a player record.")
  if (any(matches$player1_id == matches$player2_id)) {
    stop("Self matches cannot be analyzed.")
  }
  is_draw <- analysis_is_draw(matches)
  decisive <- matches[!is_draw, , drop = FALSE]
  valid_outcomes <- (decisive$winner_id == decisive$player1_id & decisive$loser_id == decisive$player2_id) |
    (decisive$winner_id == decisive$player2_id & decisive$loser_id == decisive$player1_id)
  if (anyNA(valid_outcomes) || any(!valid_outcomes)) stop("Winner and loser must be the recorded participants for decisive matches.")
  if (any(is_draw & ((!is.na(matches$winner_id) & matches$winner_id != "") |
                     (!is.na(matches$loser_id) & matches$loser_id != "")))) {
    stop("Draws cannot have a winner or loser.")
  }
  if (anyNA(matches$game_edition) || any(matches$game_edition == "") || any(matches$game_edition == "combined")) {
    stop("Each match needs a game edition; combined is reserved for the pooled scope.")
  }
  scopes <- c("combined", sort(unique(matches$game_edition)))
  for (scope in scopes) {
    selected <- if (scope == "combined") matches else matches[matches$game_edition == scope, , drop = FALSE]
    graphs <- analysis_graphs(selected, players)
    result$graphs[[scope]] <- graphs
    win <- graphs$win
    played <- graphs$played
    n <- igraph::vcount(win)
    in_degree <- igraph::degree(win, mode = "in", loops = FALSE)
    out_degree <- igraph::degree(win, mode = "out", loops = FALSE)
    opponents <- igraph::degree(played, loops = FALSE)
    wins <- igraph::strength(win, mode = "in", loops = FALSE, weights = igraph::E(win)$weight)
    losses <- igraph::strength(win, mode = "out", loops = FALSE, weights = igraph::E(win)$weight)
    matches_played <- igraph::strength(played, loops = FALSE, weights = igraph::E(played)$weight)
    draws <- matches_played - wins - losses
    pagerank <- igraph::page_rank(win, directed = TRUE, damping = .85,
                                  weights = igraph::E(win)$weight)$vector
    pagerank_for_rank <- analysis_pagerank_tie_score(pagerank)
    components <- igraph::components(played)
    giant <- max(components$csize)
    result$metrics <- rbind(result$metrics, data.frame(
      scope = scope, nodes = n, matches = nrow(selected), decisive_matches = sum(!analysis_is_draw(selected)),
      draw_matches = sum(analysis_is_draw(selected)), win_edges = igraph::ecount(win),
      played_edges = igraph::ecount(played), density_win = igraph::edge_density(win, loops = FALSE),
      density_played = igraph::edge_density(played, loops = FALSE), mean_degree_played = mean(opponents),
      mean_in_degree = mean(in_degree), mean_out_degree = mean(out_degree), mean_wins = mean(wins),
      mean_matches_played = mean(matches_played),
      weak_components_win = igraph::components(win, mode = "weak")$no,
      strong_components_win = igraph::components(win, mode = "strong")$no,
      components_played = components$no, giant_component_nodes = giant,
      giant_component_fraction = giant / n,
      transitivity_played = igraph::transitivity(played, type = "global", isolates = "NaN"),
      stringsAsFactors = FALSE))
    ids <- igraph::V(win)$name
    attributes <- players[match(ids, players$player_id), , drop = FALSE]
    money <- analysis_earnings(ids, scope, earnings, cutoff)
    ranking <- data.frame(scope = scope, player_id = ids, handle = attributes$handle,
      country = attributes$country, region = attributes$region, pagerank = unname(pagerank),
      pagerank_rank = rank(-pagerank_for_rank, ties.method = "average"), wins = unname(wins), losses = unname(losses),
      draws = unname(draws), matches_played = unname(matches_played), win_rate = unname(wins / matches_played),
      opponents = unname(opponents), opponents_beaten = unname(in_degree), opponents_lost_to = unname(out_degree),
      wins_rank = rank(-wins, ties.method = "average"), earnings_usd = money$earnings_usd,
      earnings_as_of = money$earnings_as_of, earnings_measurement = money$earnings_measurement,
      earnings_coverage_status = money$earnings_coverage_status, earnings_source_url = money$earnings_source_url,
      earnings_rank = rank(-money$earnings_usd, ties.method = "average", na.last = "keep"),
      pagerank_rank_earnings_subset = rank(ifelse(is.na(money$earnings_usd), NA_real_, -pagerank_for_rank),
                                          ties.method = "average", na.last = "keep"),
      stringsAsFactors = FALSE)
    ranking$pagerank_minus_wins_rank <- ranking$pagerank_rank - ranking$wins_rank
    ranking$pagerank_minus_earnings_rank <- ranking$pagerank_rank_earnings_subset - ranking$earnings_rank
    ranking <- ranking[order(ranking$pagerank_rank, ranking$player_id), , drop = FALSE]
    rownames(ranking) <- NULL
    result$rankings <- rbind(result$rankings, ranking)
    result$correlations <- rbind(result$correlations,
      analysis_spearman(scope, "pagerank_vs_wins", analysis_pagerank_tie_score(ranking$pagerank), ranking$wins),
      analysis_spearman(scope, "pagerank_vs_earnings", analysis_pagerank_tie_score(ranking$pagerank), ranking$earnings_usd))
    distribution <- as.data.frame(table(opponents), stringsAsFactors = FALSE)
    result$degree_distribution <- rbind(result$degree_distribution, data.frame(
      scope = scope, degree = as.numeric(distribution$opponents), players = distribution$Freq,
      proportion = distribution$Freq / n, stringsAsFactors = FALSE))
    result$random_baseline <- rbind(result$random_baseline, analysis_random_baseline(scope, played))
  }
  rownames(result$metrics) <- NULL
  rownames(result$correlations) <- NULL
  rownames(result$degree_distribution) <- NULL
  rownames(result$random_baseline) <- NULL
  result
}
