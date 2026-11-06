#!/usr/bin/env Rscript
# Explicit reviewed local files only. Nothing is downloaded or published.
source("R/normalize_earnings.R")
args <- commandArgs(trailingOnly=TRUE)
if (!length(args) || "--help" %in% args) {
  cat("Usage: Rscript scripts/normalize_earnings.R MANIFEST.csv PLAYER_MAP.csv OUTPUT.csv [GAME_MAP.csv]\n")
  quit(status=if(length(args)) 0 else 1)
}
if (!length(args) %in% c(3L,4L)) stop("Expected manifest, player map, output, optional game map")
read <- function(p) read.csv(p,colClasses="character",na.strings=c("","NA"),check.names=FALSE)
normalized <- normalize_earnings_caches(read(args[1]),read(args[2]),if(length(args)==4L) read(args[4]) else NULL)
dir.create(dirname(args[3]),recursive=TRUE,showWarnings=FALSE)
write.csv(normalized$earnings,args[3],row.names=FALSE,na="")
write.csv(normalized$rejected,paste0(args[3],".rejected.csv"),row.names=FALSE,na="")
cat("Wrote ",nrow(normalized$earnings)," earnings snapshots; ",nrow(normalized$rejected)," unmapped rows need identity review.\n",sep="")
