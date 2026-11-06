compare_sensitivity <- function(full,subset) {
  common <- merge(full$rankings[,c("scope","player_id","handle","pagerank")],
                  subset$rankings[,c("scope","player_id","pagerank")],
                  by=c("scope","player_id"),suffixes=c("_all","_major"))
  common$rank_all_common <- numeric(nrow(common));common$rank_major_common <- numeric(nrow(common))
  comparisons <- analysis_empty_correlations()
  for (scope in unique(common$scope)) {
    at <- which(common$scope==scope)
    common$rank_all_common[at] <- rank(-analysis_pagerank_tie_score(common$pagerank_all[at]),ties.method="average")
    common$rank_major_common[at] <- rank(-analysis_pagerank_tie_score(common$pagerank_major[at]),ties.method="average")
    comparisons <- rbind(comparisons,analysis_spearman(scope,"all_vs_world_major_pagerank_common_players",
      analysis_pagerank_tie_score(common$pagerank_all[at]),analysis_pagerank_tie_score(common$pagerank_major[at])))
  }
  common$major_minus_all_common_rank <- common$rank_major_common-common$rank_all_common
  common <- common[order(common$scope,common$rank_major_common,common$player_id),,drop=FALSE]
  list(ranks=common,correlations=comparisons)
}

coverage_summary <- function(inputs,a,editions) {
  r <- a$rankings[a$rankings$scope=="combined",,drop=FALSE]
  money <- a$correlations[a$correlations$scope=="combined" & a$correlations$comparison=="pagerank_vs_earnings",,drop=FALSE]
  edition_money <- a$correlations[a$correlations$scope!="combined" & a$correlations$comparison=="pagerank_vs_earnings",,drop=FALSE]
  observed <- length(unique(inputs$matches$game_edition))
  major <- sum(inputs$matches$tier %in% c("world","major"))
  domestic <- sum(inputs$matches$tier %in% "regional")
  data.frame(feature=c("edition_observations","career_earnings_comparison","edition_earnings_comparisons","event_scope_sensitivity","country_attributes","exact_match_dates","full_historical_corpus","LPDB_live_collection"),
    status=c(if(observed==length(editions))"available" else "partial",
      if(nrow(money) && money$status=="computed")"available" else "insufficient_data",
      if(sum(edition_money$status=="computed")==length(editions))"available" else "partial",
      if(major>0 && domestic>0)"available" else "insufficient_data",
      if(all(!is.na(r$country)))"available" else "partial",
      if(all(!is.na(inputs$matches$date)))"available" else "partial",
      "partial","requires_approved_access"),
    evidence=c(paste0(observed,"/",length(editions)," editions represented; not complete populations"),
      paste0(if(nrow(money))money$n_complete else 0," matched players; provider-recorded totals"),
      paste0(sum(edition_money$status=="computed"),"/",length(editions)," edition comparisons have >=3 nonconstant matched pairs"),
      paste0(major," world/major and ",domestic," domestic fixtures; research classification"),
      paste0(sum(!is.na(r$country)),"/",nrow(r)," active players with sourced country codes"),
      paste0(sum(!is.na(inputs$matches$date)),"/",nrow(inputs$matches)," exact days; remaining event-end bounds preserved"),
      "Selective official-event cohort; all editions represented does not imply complete coverage",
      "Offline approved-export path and earnings normalization work; no Liquipedia credential supplied"),stringsAsFactors=FALSE)
}
