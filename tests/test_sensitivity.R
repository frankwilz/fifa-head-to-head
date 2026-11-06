source("R/analysis.R");source("R/status.R")
# An omitted player has top score in the full graph. Its removal must not
# mechanically shift all shared ranks by one in the reported comparison.
full <- list(rankings=data.frame(scope="combined",player_id=c("A","B","X"),handle=c("A","B","X"),pagerank=c(.2,.1,.7)))
subset <- list(rankings=data.frame(scope="combined",player_id=c("A","B"),pagerank=c(.6,.4)))
x <- compare_sensitivity(full,subset)
stopifnot(nrow(x$ranks)==2,all(x$ranks$major_minus_all_common_rank==0),x$correlations$status=="insufficient_complete_pairs")
cat("Sensitivity comparison tests passed.\n")
