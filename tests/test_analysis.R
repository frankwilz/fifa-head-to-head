# Run from the repository root: Rscript tests/test_analysis.R
source("R/analysis.R")

players <- data.frame(player_id = LETTERS[1:6], handle = paste0("Player", LETTERS[1:6]),
                      country = NA_character_, region = NA_character_, stringsAsFactors = FALSE)
make_matches <- function(winners, losers, editions = rep("FC24", length(winners)),
                         dates = rep("2024-07-13", length(winners))) {
  data.frame(match_id = paste0("m", seq_along(winners)), date = dates, game_edition = editions,
    tournament_id = "test", player1_id = winners, player2_id = losers,
    winner_id = winners, loser_id = losers, platform = "PS5", tier = "major",
    source_url = "https://example.invalid/test-fixture", stringsAsFactors = FALSE)
}
assert_equal <- function(actual, expected, message) {
  if (!isTRUE(all.equal(unname(actual), unname(expected), check.attributes = FALSE))) stop(message)
}
edge_weight <- function(graph, from, to) {
  edges <- igraph::as_data_frame(graph, what = "edges")
  edges$weight[edges$from == from & edges$to == to]
}

# A clean champion must receive incoming edges and the highest PageRank. This
# catches the easy-to-miss winner->loser reversal with no dependence on row order.
star <- analyze_networks(make_matches(rep("A", 3), c("B", "C", "D")), players)
ranked <- star$rankings[star$rankings$scope == "combined", ]
stopifnot(ranked$player_id[1] == "A", ranked$wins[1] == 3,
          ranked$opponents_beaten[1] == 3, ranked$losses[1] == 0,
          ranked$opponents_lost_to[1] == 0, ranked$win_rate[1] == 1)
assert_equal(edge_weight(star$graphs$combined$win, "B", "A"), 1, "Edges must point loser to winner.")
assert_equal(sum(ranked$pagerank), 1, "PageRank must be normalized.")

# Repeated victories aggregate to a directed weight; the reverse result is a
# separate directed edge but still part of the same undirected played edge.
repeated <- make_matches(c("A", "A", "A", "B", "B"), c("B", "B", "B", "A", "C"))
out <- analyze_networks(repeated, players)
assert_equal(edge_weight(out$graphs$combined$win, "B", "A"), 3, "Repeated wins were not aggregated.")
assert_equal(edge_weight(out$graphs$combined$win, "A", "B"), 1, "Reciprocal results were lost.")
assert_equal(edge_weight(out$graphs$combined$played, "A", "B"), 4, "Played weights must count both directions.")
a <- out$rankings[out$rankings$scope == "combined" & out$rankings$player_id == "A", ]
stopifnot(a$wins == 3, a$opponents_beaten == 1, a$matches_played == 4, a$opponents == 1)
metrics <- out$metrics[out$metrics$scope == "combined", ]
stopifnot(metrics$nodes == 3, metrics$matches == 5, metrics$win_edges == 3, metrics$played_edges == 2)
assert_equal(metrics$mean_degree_played, 4 / 3, "Mean played degree must count distinct opponents.")
assert_equal(metrics$density_win, 3 / 6, "Directed density denominator is wrong.")
assert_equal(metrics$density_played, 2 / 3, "Undirected density denominator is wrong.")
stopifnot(all(is.na(out$rankings$earnings_usd)), all(is.na(out$rankings$earnings_rank)))

# Completed draws contribute a played edge and an appearance for each player,
# without inventing a winner. Draw-only players remain valid active vertices.
draws_only <- make_matches("A", "B")
draws_only$decision <- "draw"
draws_only$winner_id <- NA_character_
draws_only$loser_id <- NA_character_
draw_result <- analyze_networks(draws_only, players)
stopifnot(igraph::vcount(draw_result$graphs$combined$win) == 2,
          igraph::ecount(draw_result$graphs$combined$win) == 0,
          igraph::ecount(draw_result$graphs$combined$played) == 1,
          all(draw_result$rankings$draws == 1), all(draw_result$rankings$wins == 0),
          all(draw_result$rankings$losses == 0), all(draw_result$rankings$matches_played == 1),
          all(draw_result$rankings$win_rate == 0), all(draw_result$rankings$pagerank == .5))
stopifnot(draw_result$metrics$draw_matches[draw_result$metrics$scope == "combined"] == 1,
          draw_result$metrics$decisive_matches[draw_result$metrics$scope == "combined"] == 0)
mixed <- make_matches(c("A", "B"), c("B", "C"))
mixed$decision <- c("score", "draw")
mixed$winner_id[2] <- NA_character_
mixed$loser_id[2] <- NA_character_
mixed_result <- analyze_networks(mixed, players)
stopifnot(igraph::ecount(mixed_result$graphs$combined$win) == 1,
          igraph::ecount(mixed_result$graphs$combined$played) == 2)
b <- mixed_result$rankings[mixed_result$rankings$scope == "combined" & mixed_result$rankings$player_id == "B", ]
stopifnot(b$matches_played == 2, b$losses == 1, b$draws == 1, b$wins == 0, b$win_rate == 0)
c <- mixed_result$rankings[mixed_result$rankings$scope == "combined" & mixed_result$rankings$player_id == "C", ]
stopifnot(c$opponents == 1, c$draws == 1, c$opponents_beaten == 0, c$opponents_lost_to == 0)

# Each edition has its own participant set. A metadata-only player F does not
# become an isolate; a future-dated match cannot leak into the cutoff analysis.
multi <- make_matches(c("A", "B", "D", "F"), c("B", "C", "E", "A"),
                      c("FC24", "FC24", "FC25", "FC26"),
                      c("2024-07-13", "2024-07-13", "2025-07-13", "2099-01-01"))
scoped <- analyze_networks(multi, players)
stopifnot(identical(names(scoped$graphs), c("combined", "FC24", "FC25")))
assert_equal(sort(igraph::V(scoped$graphs$FC24$win)$name), c("A", "B", "C"), "Edition membership leaked.")
stopifnot(!"F" %in% igraph::V(scoped$graphs$combined$played)$name)
pooled <- scoped$metrics[scoped$metrics$scope == "combined", ]
stopifnot(pooled$nodes == 5, pooled$components_played == 2, pooled$giant_component_nodes == 3)
assert_equal(pooled$giant_component_fraction, 3 / 5, "Disconnected giant fraction is wrong.")

# An undated match can be included once its event has ended, without asserting
# that the event-end date was its actual match date. Events ending after the
# cutoff stay excluded even if some matches might already have taken place.
undated <- make_matches(c("A", "B", "D"), c("B", "C", "E"),
                        c("FC24", "FC26", "FC26"), c("2024-07-13", NA, NA))
undated$event_end_date <- c("2024-07-13", "2026-07-26", "2099-01-01")
undated$date_precision <- c("exact", "event_end", "event_end")
with_end_dates <- analyze_networks(undated, players)
stopifnot(with_end_dates$metrics$matches[with_end_dates$metrics$scope == "combined"] == 2,
          with_end_dates$metrics$matches[with_end_dates$metrics$scope == "FC26"] == 1,
          is.na(undated$date[2]))
assert_equal(sort(igraph::V(with_end_dates$graphs$FC26$win)$name), c("B", "C"),
             "Event-end eligibility dropped a known result or admitted a future event.")

# Earnings use the latest pre-cutoff observation in the matching scope. A
# missing observation stays missing; future observations are not silently used.
earnings <- data.frame(player_id = c("A", "A", "A", "B", "C", "A", "B", "C"),
  scope = c(rep("career", 5), rep("edition", 3)), game_edition = c(rep("", 5), rep("FC24", 3)),
  earnings_usd = c(10, 30, 999, 20, 10, 300, 200, 100),
  as_of = c("2024-01-01", "2026-11-04", "2099-01-01", "2026-11-04", "2026-11-04", rep("2024-07-13", 3)),
  source_url = "https://example.invalid/test-fixture", stringsAsFactors = FALSE)
money <- analyze_networks(multi, players, earnings)
stopifnot(money$rankings$earnings_usd[money$rankings$scope == "combined" & money$rankings$player_id == "A"] == 30)
stopifnot(money$rankings$earnings_usd[money$rankings$scope == "FC24" & money$rankings$player_id == "A"] == 300)
stopifnot(all(is.na(money$rankings$earnings_usd[money$rankings$scope == "FC25"])))
stopifnot(all(is.na(money$rankings$earnings_usd[money$rankings$player_id == "D"])))
comparable <- money$rankings[money$rankings$scope == "combined" & !is.na(money$rankings$earnings_usd), ]
assert_equal(comparable$pagerank_rank_earnings_subset,
             rank(-analysis_pagerank_tie_score(comparable$pagerank), ties.method = "average"),
             "Earnings rank gaps must use the same player subset.")

# PRPACK can return a difference of 1e-17 for mathematically identical vertices
# in an 11-node cycle. Numerical noise must not break rank ties or manufacture a
# correlation with otherwise unrelated earnings.
ring_ids <- sprintf("p%02d", seq_len(11))
ring_players <- data.frame(player_id = ring_ids, handle = ring_ids,
                           country = NA_character_, region = NA_character_)
ring_matches <- make_matches(c(ring_ids[-1], ring_ids[1]), ring_ids)
ring_earnings <- data.frame(player_id = ring_ids, scope = "career", game_edition = "",
                            earnings_usd = seq_len(11), as_of = "2026-11-04",
                            source_url = "https://example.invalid/test-fixture")
ring_result <- analyze_networks(ring_matches, ring_players, ring_earnings)
ring_rankings <- ring_result$rankings[ring_result$rankings$scope == "combined", ]
stopifnot(all(ring_rankings$pagerank_rank == 6),
          all(ring_rankings$pagerank_rank_earnings_subset == 6))
ring_correlation <- ring_result$correlations[ring_result$correlations$scope == "combined" &
                                             ring_result$correlations$comparison == "pagerank_vs_earnings", ]
stopifnot(ring_correlation$status == "constant_variable", is.na(ring_correlation$spearman_rho))

# GraphML is the portable analysis output. Its roundtrip must preserve edge
# orientation, reciprocal pairs and repeated-match weights in both graph types.
graphml_file <- tempfile(fileext = ".graphml")
tryCatch({
  igraph::write_graph(out$graphs$combined$win, graphml_file, format = "graphml")
  win_roundtrip <- igraph::read_graph(graphml_file, format = "graphml")
  stopifnot(igraph::is_directed(win_roundtrip), igraph::vcount(win_roundtrip) == 3,
            igraph::ecount(win_roundtrip) == 3)
  assert_equal(edge_weight(win_roundtrip, "B", "A"), 3, "GraphML lost directed repeated wins.")
  assert_equal(edge_weight(win_roundtrip, "A", "B"), 1, "GraphML lost a reciprocal edge.")
  igraph::write_graph(out$graphs$combined$played, graphml_file, format = "graphml")
  played_roundtrip <- igraph::read_graph(graphml_file, format = "graphml")
  stopifnot(!igraph::is_directed(played_roundtrip), igraph::ecount(played_roundtrip) == 2)
  assert_equal(edge_weight(played_roundtrip, "A", "B"), 4, "GraphML lost undirected match counts.")
}, finally = unlink(graphml_file))

# Spearman values use pairwise complete ranks with ties; insufficient or
# constant inputs are explicitly distinguished instead of reporting zero.
corr <- analysis_spearman("test", "known", c(1, 2, 3, NA), c(30, 20, 10, 99))
stopifnot(corr$n_complete == 3, corr$spearman_rho == -1, corr$status == "computed")
stopifnot(analysis_spearman("t", "small", c(1, 2), c(1, 2))$status == "insufficient_complete_pairs")
stopifnot(analysis_spearman("t", "constant", c(1, 1, 1), c(1, 2, 3))$status == "constant_variable")
stopifnot(is.na(analysis_spearman("t", "missing", 1:3, rep(NA_real_, 3))$spearman_rho))

# The random baseline must be reproducible and must not perturb callers' RNG.
set.seed(73)
seed_before <- .Random.seed
random1 <- analysis_random_baseline("FC24", out$graphs$FC24$played)
stopifnot(identical(.Random.seed, seed_before))
random2 <- analysis_random_baseline("FC24", out$graphs$FC24$played)
stopifnot(identical(random1, random2), random1$nodes == 3, random1$played_edges == 2,
          random1$replicates == 100)

empty <- analyze_networks(multi[FALSE, ], players)
stopifnot(length(empty$graphs) == 0, nrow(empty$rankings) == 0,
          identical(names(empty$rankings), names(out$rankings)),
          identical(names(empty$metrics), names(out$metrics)))
bad <- make_matches("A", "B")
bad$loser_id <- "C"
stopifnot(inherits(tryCatch(analyze_networks(bad, players), error = identity), "error"))

cat("Analysis checks passed: direction, aggregation, scopes, earnings, correlations, numerical ties, GraphML, baseline, empty inputs.\n")
