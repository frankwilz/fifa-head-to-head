# RQ2 building block: community detection on the undirected played network.
# Edge weights count fixtures between two players, so repeated meetings pull
# players into the same community. Louvain is randomized in igraph, so a fixed
# seed is used and the caller's RNG state is restored afterwards, as in
# analysis_random_baseline(). Community labels are renumbered by size (largest
# first, ties by smallest player_id) so labels are stable across runs.

analysis_communities <- function(scope, played, seed = 20261120L) {
  if (!requireNamespace("igraph", quietly = TRUE)) stop("Install igraph before running analysis.")
  if (igraph::is_directed(played)) stop("Community detection expects the undirected played network.")
  ids <- igraph::V(played)$name
  n <- length(ids)
  m <- igraph::ecount(played)
  if (n == 0L) {
    membership <- integer()
    modularity <- NA_real_
  } else if (m == 0L) {
    # No fixtures means no community structure: each player stands alone.
    membership <- seq_len(n)
    modularity <- NA_real_
  } else {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
      else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
    }, add = TRUE)
    set.seed(seed)
    weights <- igraph::E(played)$weight
    found <- igraph::cluster_louvain(played, weights = weights)
    membership <- as.integer(igraph::membership(found))
    modularity <- igraph::modularity(played, membership, weights = weights)
  }
  sizes <- tabulate(membership, nbins = if (n) max(membership) else 0L)
  first_id <- vapply(seq_along(sizes), function(k) min(ids[membership == k]), character(1))
  order_old <- order(-sizes, first_id)
  relabel <- integer(length(sizes))
  relabel[order_old] <- seq_along(order_old)
  community <- relabel[membership]
  community_size <- tabulate(community, nbins = length(sizes))[community]
  list(
    membership = data.frame(scope = rep(scope, n), player_id = ids, community = community,
                            community_size = community_size, stringsAsFactors = FALSE),
    summary = data.frame(scope = scope, method = "Louvain (igraph::cluster_louvain), fixture-weighted",
                         seed = as.integer(seed), nodes = n, played_edges = m,
                         communities = length(sizes),
                         largest_community = if (n) max(sizes) else 0L,
                         modularity = modularity, stringsAsFactors = FALSE)
  )
}
