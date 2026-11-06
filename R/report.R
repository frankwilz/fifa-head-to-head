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

write_analysis_notes <- function(a, inputs, cutoff, editions, report_path, input_label, sensitivity_status, availability) {
  m <- a$metrics; r <- a$rankings; cohort <- r[r$scope=="combined",,drop=FALSE]
  top <- leading_rankings(cohort)[,c("handle","pagerank_rank","pagerank","wins","losses","opponents")]
  coverage <- data.frame(game_edition=editions,
    matches=vapply(editions,function(e) sum(inputs$matches$game_edition==e),integer(1)))
  careers <- cohort[is.finite(cohort$earnings_usd),,drop=FALSE]
  gap <- careers[order(-abs(careers$pagerank_minus_earnings_rank),careers$handle),,drop=FALSE]
  gap <- head(gap[,c("handle","earnings_usd","pagerank_rank_earnings_subset","earnings_rank","pagerank_minus_earnings_rank")],10)
  money <- a$correlations[a$correlations$scope=="combined" & a$correlations$comparison=="pagerank_vs_earnings",,drop=FALSE]
  best <- cohort$handle[which.min(cohort$pagerank_rank)]
  text <- c(
    "# Competitive FIFA analysis notes", "",
    paste0("Evidence cutoff: **",cutoff,"** (America/Vancouver). Report due **November 6, 2026**. Research draft; not submitted."), "",
    "## Results and current status", "",
    paste0("The R workflow validates ",nrow(inputs$matches)," source-backed head-to-head fixtures involving ",nrow(cohort)," players across ",sum(coverage$matches>0)," of ",length(editions)," proposed editions. Input: ",input_label,". Official world, continental and domestic events are represented. All editions having observations does not imply complete historical coverage."), "",
    paste0("Within the observed combined network, **",best,"** has the largest weighted PageRank. This is a sample-dependent ranking, affected by event selection, bracket progression and unequal coverage across editions; it cannot establish the strongest professional globally."), "",
    if(nrow(money) && money$status=="computed") paste0("RQ1's combined comparison with provider-recorded career earnings now computes: **Spearman rho = ",format(round(money$spearman_rho,4),nsmall=4),"**, using **",money$n_complete," matched players**. Provider totals are incomplete observations, not verified complete actual career earnings. The per-edition comparison statuses are reported below.") else "The combined earnings comparison has insufficient matched nonconstant observations; see its explicit status below.", "",
    "## Availability and data quality", "",
    markdown_table(availability), "",
    markdown_table(coverage), "",
    paste0("The input includes ",sum(inputs$earnings$scope=="career")," career and ",sum(inputs$earnings$scope=="edition")," edition earnings snapshots. Of the combined network's ",nrow(cohort)," players, ",nrow(careers)," have matched career measurements. Unlisted player/game observations remain missing, never zero. ",sum(is.na(inputs$matches$date))," fixtures retain unknown exact match days and use sourced event-end bounds only for cutoff eligibility."), "",
    paste0("Validation recorded ",sum(inputs$issues$severity=="error")," errors, ",sum(inputs$issues$severity=="excluded")," exclusion notices and ",sum(inputs$issues$severity=="warning")," uncertainty warnings. Counts refer to notices rather than necessarily distinct rows. Clean CSVs preserve IDs and sources; results/quality-issues.csv records the notices."), "",
    "The earnings estimand is now explicitly the amount the provider reports at retrieval. Earlier exclusions treated incomplete profiles as unusable for any comparison. That was unnecessarily restrictive for a comparison with provider-recorded totals. The revised analysis does not claim that missing tournaments have been repaired, add known prizes onto potentially overlapping totals, or backdate November 6 observations into the November 4 snapshot. See docs/earnings-provenance.md for retrieval evidence, aliases and identity exclusions.", "",
    "## Network construction and descriptive metrics", "",
    "One completed source-listed 1v1 bracket fixture or series contributes one played-edge unit; historical multi-leg ties count once as aggregate series. A decisive fixture creates a loser-to-winner edge. Repeated opponents accumulate edge weight. Completed draws enter the played network only. Penalty winners are explicit; shootout scores are not goal totals. Only participating players enter a scope. Combined and edition networks are exported as GraphML and edge CSVs.", "",
    markdown_table(m[,c("scope","nodes","matches","win_edges","played_edges","density_played","mean_degree_played","components_played","giant_component_fraction")]), "",
    "In-degree counts distinct opponents beaten, incoming strength counts won fixtures, played degree counts distinct opponents, and played strength counts fixtures. Low degree can reflect knockout format and omitted stages; it does not alone demonstrate regional isolation.", "",
    "## RQ1: rankings and recorded earnings", "",
    "Weighted PageRank uses damping 0.85. Average ranks handle ties after scores are rounded to 12 significant digits for ranking/correlation only; raw PageRank is retained. Negative rank gaps indicate a better PageRank position than the comparison rank. Earnings rank gaps use the identical matched player subset. Combined graphs use career totals; edition graphs use only the corresponding game's reported totals. Each snapshot must be dated no later than the cutoff.", "",
    markdown_table(top), "",
    markdown_table(a$correlations), "",
    "Largest absolute differences between PageRank and provider-recorded career-earnings ranks (within the matched subset):", "",
    markdown_table(gap), "",
    "Career totals may include games or competition formats absent from this 1v1 network. Provider pages omit known tournaments, and players with recorded earnings are not a random subset. Edition totals are separate measurements and absent game rows are not inferred as zero. Correlations describe the observed data; no causal interpretation or statistical-significance claim is made.", "",
    "## Event-scope sensitivity and random reference graphs", "",
    paste0("Event-scope sensitivity: ",sensitivity_status), "",
    "`research_event_scope_v1` classifies world championships as world, the international eChampions League as major, and domestic ePremier League events as regional. These are research categories, not official or Liquipedia tier labels. The world/major subset, full-sample comparison ranks and correlations are exported under results/major-tier-sensitivity/. Rank changes are calculated on the same shared players, so simply removing players does not mechanically improve everyone else's comparison rank. Since domestic records are concentrated in FIFA20/21, this sensitivity also changes edition coverage; it cannot isolate a pure tournament-tier effect. Small cups and open qualifiers remain underrepresented.", "",
    "For each scope, 100 seeded undirected G(n,m) graphs retain the observed player and played-edge counts. Density and mean degree match by construction, so comparison uses giant-component fraction and global transitivity. Simulation 2.5%–97.5% intervals are null-model reference ranges, not population confidence intervals. Undefined transitivity is retained as undefined, with finite replicate counts exported.", "",
    markdown_table(a$random_baseline[,c("scope","observed_giant_fraction","random_giant_mean","random_giant_q025","random_giant_q975","observed_transitivity","random_transitivity_mean")]), "",
    "## Figures and reproducibility", "",
    "Run `Rscript scripts/run_pipeline.R` from the repository root and `Rscript scripts/test.R` for checks. The default run is offline. API cache normalization is executable through scripts/normalize_earnings.R; live earnings requests still require a local key. Approved Liquipedia exports can use the canonical CSV path. results/run-manifest.csv records the cutoff, input hashes and dependency versions; results/session-info.txt records the R environment.", "",
    "![Leading PageRank scores](../results/figures/pagerank-top10.png)", "",
    "![PageRank and recorded career earnings](../results/figures/pagerank-vs-earnings.png)", "",
    "![Observed played network](../results/figures/played-network.png)", "",
    "![Opponent-degree distribution](../results/figures/degree-distribution.png)", "",
    "## Remaining work", "",
    "Broader event collection and identity audits remain necessary for global conclusions. Platform and country provenance have been improved, but competitive qualifying region must be sourced separately; a country flag is not proof of a player's circuit region. Tournament-placement comparisons are not implemented yet. API access credentials and an approved LPDB schema remain external prerequisites for large-scale collection, not for reproducing the checked-in results.", "",
    "The November 6 deliverable contains descriptive analysis and RQ1 results with explicit sampling limits. November 7–20 covers communities/assortativity (RQ2), triads (RQ3) and bridges (RQ4); November 21–27 covers robustness (RQ5); November 28–December 2 covers the final report and video, for the December 3 presentation. No submission or access application was sent.", "",
    "## Sources", "",
    "Match evidence: data/raw/sources.csv, data/raw/match_sources_expansion.csv and docs/match-expansion.md. Earnings snapshots and identity decisions: data/raw/earnings_sources.csv and docs/earnings-provenance.md. Event classifications and platform sources: data/raw/tournaments.csv. These registers link the official competition reports and provider profiles used by each record.", "",
    "Methods and access documentation: [igraph PageRank](https://r.igraph.org/reference/page_rank.html), [Esports Earnings API](https://www.esportsearnings.com/apidocs), [Liquipedia API](https://liquipedia.net/api) and [API terms](https://liquipedia.net/api-terms-of-use)."
  )
  dir.create(dirname(report_path),recursive=TRUE,showWarnings=FALSE)
  writeLines(text,report_path)
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
  money <- r[is.finite(r$earnings_usd),,drop=FALSE]
  png(file.path(output_dir,"pagerank-vs-earnings.png"),width=1500,height=1100,res=160)
  par(mar=c(5,5,5,2))
  if(nrow(money)) {
    plot(money$earnings_usd+1,money$pagerank,log="x",pch=19,col="#147d92",
      xlab="Provider-recorded career earnings + $1 (USD; logarithmic scale)",ylab="Weighted PageRank",
      main="PageRank and recorded career earnings")
    label <- order(money$pagerank,decreasing=TRUE)[seq_len(min(5L,nrow(money)))]
    text(money$earnings_usd[label]+1,money$pagerank[label],labels=money$handle[label],pos=3,cex=.7)
    mtext(paste0(nrow(money)," matched players; incomplete provider coverage; observational comparison"),side=3,line=.5,cex=.8)
  } else { plot.new();text(.5,.5,"No matched career-earnings observations at this cutoff") }
  dev.off()

}
