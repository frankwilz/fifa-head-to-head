# Run from the repository root: Rscript tests/test_communities.R
source("R/analysis.R")
source("R/communities.R")

assert_true <- function(ok, message) if (!isTRUE(ok)) stop(message)
players <- data.frame(player_id = LETTERS[1:6], handle = paste0("Player", LETTERS[1:6]),
                      country = NA_character_, region = NA_character_, stringsAsFactors = FALSE)
make_matches <- function(p1, p2) {
  data.frame(match_id = paste0("m", seq_along(p1)), date = "2024-07-13", game_edition = "FC24",
    tournament_id = "test", player1_id = p1, player2_id = p2, winner_id = p1, loser_id = p2,
    platform = "PS5", tier = "major", source_url = "https://example.invalid/test-fixture",
    stringsAsFactors = FALSE)
}

# Two triangles (A-B-C and D-E-F) joined by one C-D fixture: two communities.
two_groups <- make_matches(c("A", "A", "B", "D", "D", "E", "C"), c("B", "C", "C", "E", "F", "F", "D"))
played <- analysis_graphs(two_groups, players)$played
result <- analysis_communities("FC24", played)
m <- result$membership
group <- setNames(m$community, m$player_id)
assert_true(length(unique(group[c("A", "B", "C")])) == 1L, "A, B and C should share a community.")
assert_true(length(unique(group[c("D", "E", "F")])) == 1L, "D, E and F should share a community.")
assert_true(group[["A"]] != group[["D"]], "The two triangles should be separate communities.")
assert_true(result$summary$communities == 2L && result$summary$largest_community == 3L, "Summary counts are wrong.")
assert_true(identical(m$community_size, c(3L, 3L, 3L, 3L, 3L, 3L)), "Community sizes are wrong.")
# Equal sizes: the community containing the smallest player_id (A) is labelled 1.
assert_true(group[["A"]] == 1L, "Labels should be ordered by size, then smallest player_id.")
expected_q <- igraph::modularity(played, m$community, weights = igraph::E(played)$weight)
assert_true(isTRUE(all.equal(result$summary$modularity, expected_q)) && expected_q > 0.3,
            "Modularity should match igraph and show clear structure.")

# Reproducible, and the caller's random stream is left untouched.
set.seed(1); before <- runif(1); set.seed(1)
again <- analysis_communities("FC24", played)
assert_true(identical(runif(1), before), "Community detection must restore the caller's RNG state.")
assert_true(identical(again, result), "Repeated runs should give identical results.")

# Repeated fixtures carry weight: many B-D meetings pull B and D together.
heavy <- make_matches(c("A", "A", "B", "D", "D", "E", "C", rep("B", 6)),
                      c("B", "C", "C", "E", "F", "F", "D", rep("D", 6)))
weighted <- analysis_communities("FC24", analysis_graphs(heavy, players)$played)$membership
assert_true(with(weighted, community[player_id == "B"] == community[player_id == "D"]),
            "Fixture weights should influence community assignment.")

# The directed win network is rejected rather than silently analysed.
win <- analysis_graphs(two_groups, players)$win
assert_true(inherits(try(analysis_communities("FC24", win), silent = TRUE), "try-error"),
            "Directed graphs should be rejected.")

# A graph with players but no fixtures has no structure to report.
lonely <- igraph::make_empty_graph(3, directed = FALSE)
igraph::V(lonely)$name <- c("X", "Y", "Z")
empty <- analysis_communities("none", lonely)
assert_true(empty$summary$communities == 3L && is.na(empty$summary$modularity), "Edgeless graph handling is wrong.")

cat("Community detection tests passed: two-group recovery, labels, modularity, reproducibility, weights, edge cases.\n")
