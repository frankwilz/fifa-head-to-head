leading_rankings <- function(r, n=10L) {
  r <- r[order(r$pagerank_rank,r$handle),,drop=FALSE]
  if (nrow(r)<=n) return(r)
  r[r$pagerank_rank<=r$pagerank_rank[n],,drop=FALSE]
}

markdown_table <- function(x, digits=4) {
  if (!nrow(x)) return("No observations available.")
  y <- as.data.frame(lapply(x, function(v) {
    if (is.numeric(v)) v <- ifelse(is.finite(v), format(round(v, digits), trim=TRUE, scientific=FALSE), "unavailable")
    v <- as.character(v); v[is.na(v)] <- "unknown"; gsub("|", "\\|", v, fixed=TRUE)
  }), stringsAsFactors=FALSE)
  paste(c(paste0("| ", paste(names(y), collapse=" | "), " |"),
          paste0("| ", paste(rep("---", ncol(y)), collapse=" | "), " |"),
          apply(y, 1, function(v) paste0("| ", paste(v, collapse=" | "), " |"))), collapse="\n")
}

write_midproject_report <- function(a, inputs, cutoff, editions, report_path, input_label, sensitivity_status) {
  m <- a$metrics; r <- a$rankings; cohort <- r[r$scope=="combined",,drop=FALSE]
  top <- leading_rankings(cohort)[,c("handle","pagerank_rank","pagerank","wins","losses","opponents")]
  coverage <- data.frame(game_edition=editions,
    matches=vapply(editions, function(e) sum(inputs$matches$game_edition==e), integer(1)))
  n_edition <- sum(coverage$matches>0)
  major <- sum(!is.na(inputs$matches$tier) & inputs$matches$tier %in% c("world","major","S","A"))
  exact_unknown <- sum(is.na(inputs$matches$date))
  sources <- sort(unique(inputs$matches$source_url))
  best <- cohort$handle[which.min(cohort$pagerank_rank)]
  text <- c(
    "# Who Really Beats Whom: mid-project report draft", "",
    paste0("Analysis cutoff: **",cutoff,"** (America/Vancouver). Target report date: **November 6, 2026**."), "",
    "## Current result and status", "",
    paste0("The executable R workflow validates and analyzes ",nrow(inputs$matches)," source-backed match records involving ",nrow(cohort)," players across ",n_edition," of the ",length(editions)," planned editions. Input: ",input_label,". These are a convenience sample of major championship results, with edition-specific omissions recorded in docs/data-coverage.md. They establish that the analysis works; they do not establish a global professional ranking."), "",
    paste0("Within the observed combined network, **",best,"** has the largest weighted PageRank. This position depends on the selected events, opponents and omitted rounds. It must not be interpreted as the strongest FIFA professional over 2017–2026."), "",
    "The current milestone's computation is implemented. Full data collection and the empirical PageRank-versus-career-earnings comparison remain incomplete. The API clients are prepared, but no keys were supplied and no API key application was submitted. RQ2–RQ5 are future milestones.", "",
    "## Data and quality", "",
    markdown_table(coverage), "",
    paste0("There are ",nrow(inputs$earnings)," eligible earnings snapshot rows. Unknown earnings stay missing. ",exact_unknown," match records lack an exact match day; their sourced event end dates are used only to confirm that the event finished by the cutoff. They retain their original missing exact dates. The public cohort omits group/league stages and regional or lower-tier events; this creates strong selection bias toward championship progression."), "",
    paste0("Validation recorded ",sum(inputs$issues$severity=="error")," errors, ",sum(inputs$issues$severity=="excluded")," exclusion notices and ",sum(inputs$issues$severity=="warning")," uncertainty warnings. Notices count issues rather than necessarily distinct rows. See results/quality-issues.csv. IDs and source URLs are preserved in clean CSVs."), "",
    "## Network construction and descriptive metrics", "",
    "Each decisive completed 1v1 series/tie contributes one directed loser-to-winner edge, weighted by repeated wins over that opponent. The undirected played network counts all completed fixtures between each pair, including draws. Draws do not create win-network edges. Penalty-decided ties have an explicit winner; shootout scores are not goal totals. Vertices are the players participating in the selected scope. A pooled graph and a separate graph for each observed edition are exported as GraphML and edge CSVs.", "",
    markdown_table(m[,c("scope","nodes","matches","win_edges","played_edges","density_played","mean_degree_played","components_played","giant_component_fraction")]), "",
    "In-degree counts distinct opponents beaten; incoming strength counts won ties. Total played degree counts distinct opponents, whereas weighted played degree counts all ties. A low degree in this sample is partly induced by knockout format and omitted rounds, so it is insufficient evidence for regional isolation.", "",
    "## RQ1: ranking by defeated opponents", "",
    "Weighted directed PageRank uses damping 0.85. Average ranks handle ties after PageRank is rounded to 12 significant digits for ranking and Spearman comparisons only; raw scores are retained. Smaller rank numbers are better. Rank gaps are PageRank rank minus the comparison rank, so negative gaps indicate a better PageRank position. Earnings gaps compare the same subset of players with available earnings. Combined graphs use career totals and edition graphs use edition totals, with the latest snapshot no later than the cutoff.", "",
    markdown_table(top), "",
    markdown_table(a$correlations), "",
    "No global or career inference is supported by this sample. Missing earnings, insufficient complete pairs, and constant inputs have explicit unavailable statuses. A Spearman coefficient is descriptive here; the workflow does not claim statistical significance or causal player quality. Tournament placements are not yet imported, and the current career-earnings comparison cannot be completed without verified observations.", "",
    "## Random-network and coverage checks", "",
    "For each scope, 100 reproducible undirected G(n,m) graphs retain the observed number of players and played edges. Their mean degree and density equal the observation by construction. The structural comparison therefore uses giant-component fraction and global transitivity. The 2.5%–97.5% simulation interval is a null-model reference range, not a confidence interval for the FIFA population. Some sparse simulated graphs have undefined transitivity; the finite replicate count is exported.", "",
    markdown_table(a$random_baseline[,c("scope","observed_giant_fraction","random_giant_mean","random_giant_q025","random_giant_q975","observed_transitivity","random_transitivity_mean")]), "",
    paste0("Tier sensitivity: ",sensitivity_status," Eligible major-tier rows: ",major,". The current public records have no consistent provider tier classification; an unknown tier is not recoded as lower tier. With no lower-tier observations, the proposal's with/without-lower-tier comparison remains pending."), "",
    "## Figures and reproducibility", "",
    "The pipeline generates `results/figures/pagerank-top10.png`, `played-network.png`, and `degree-distribution.png`, plus scope-specific metrics, rankings, correlation statuses, random baselines and graph exports. Re-run `Rscript scripts/run_pipeline.R` from the repository root; run `Rscript scripts/test.R` for validation. `results/run-manifest.csv` records the cutoff, input hashes and dependency versions. `results/session-info.txt` records the R environment.", "",
    "![PageRank in the observed cohort](../results/figures/pagerank-top10.png)", "",
    "![Observed played network](../results/figures/played-network.png)", "",
    "![Observed opponent-degree distribution](../results/figures/degree-distribution.png)", "",
    "## Work required before submission and later analysis", "",
    "1. Obtain approved access or curated exports; collect the missing editions, regional qualifiers and omitted stages; resolve cross-source aliases and duplicate series.",
    "2. Join properly scoped and dated career/edition earnings and tournament placements; audit region, platform and tournament-tier coverage.",
    "3. Rerun and review RQ1 against the broader corpus, quantify coverage and revise this draft's conclusions before the November 6 submission.",
    "4. November 7–20: communities/assortativity (RQ2), triad null models (RQ3), and bridge analysis (RQ4). November 21–27: robustness (RQ5). November 28–December 2: final report and video, for the December 3 presentation.", "",
    "## Match sources", "",
    vapply(sources, function(u) paste0("- [Official result source](",u,")"), character(1)), "",
    "Source-specific curation and metadata provenance: `data/raw/sources.csv` and `docs/data-coverage.md`. Provider documentation: [Esports Earnings API](https://www.esportsearnings.com/apidocs), [Liquipedia API](https://liquipedia.net/api), [Liquipedia API terms](https://liquipedia.net/api-terms-of-use). Method reference: [igraph PageRank](https://r.igraph.org/reference/page_rank.html)."
  )
  dir.create(dirname(report_path), recursive=TRUE, showWarnings=FALSE)
  writeLines(text, report_path)
}

write_figures <- function(a, output_dir) {
  dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  r <- a$rankings[a$rankings$scope=="combined",,drop=FALSE]
  top <- leading_rankings(r)
  png(file.path(output_dir,"pagerank-top10.png"),width=1600,height=1050,res=160)
  par(mar=c(5,10,5,2)); barplot(rev(top$pagerank),names.arg=rev(top$handle),horiz=TRUE,
    las=1,col="#147d92",border=NA,xlab="Weighted PageRank",main="Observed cohort: leading PageRank scores")
  mtext("First 10 positions with boundary ties; source-covered results only",side=3,line=.4,cex=.8)
  dev.off()
  g <- a$graphs$combined$played
  set.seed(20261104)
  layout <- igraph::layout_with_fr(g,weights=NA)
  png(file.path(output_dir,"played-network.png"),width=1800,height=1300,res=160)
  par(mar=c(2,2,5,2))
  pr <- r$pagerank[match(igraph::V(g)$name,r$player_id)]
  igraph::plot.igraph(g,layout=layout,vertex.label=ifelse(igraph::V(g)$name %in% top$player_id,igraph::V(g)$handle,NA),
    vertex.size=5+15*sqrt(pr/max(pr)),vertex.color="#9dd9df",vertex.frame.color="#147d92",
    vertex.label.cex=.85,vertex.label.color="#17334b",vertex.label.dist=1.4,
    edge.color="#93a6b2",edge.width=1+log1p(igraph::E(g)$weight),
    main="Observed head-to-head played network")
  mtext("Node size reflects PageRank; leading ranks labeled; edges count observed series/ties",side=3,line=.5,cex=.85)
  dev.off()
  d <- a$degree_distribution[a$degree_distribution$scope=="combined",,drop=FALSE]
  png(file.path(output_dir,"degree-distribution.png"),width=1500,height=1000,res=160)
  par(mar=c(5,5,4,2)); barplot(d$players,names.arg=d$degree,col="#147d92",border=NA,
    xlab="Distinct opponents played",ylab="Players",main="Observed opponent-degree distribution")
  dev.off()
}
