# Two isolated public-data runs verify exports, report counts and determinism.
rscript <- file.path(R.home("bin"),"Rscript")
first <- tempfile("fifah2h-run1-"); second <- tempfile("fifah2h-run2-")
for (path in c(first,second)) {
  status <- system2(rscript,c("scripts/run_pipeline.R",shQuote(paste0("--output-dir=",path))),stdout=FALSE)
  if (status != 0) stop("Isolated pipeline failed")
}
metrics <- read.csv(file.path(first,"results/metrics.csv"))
raw <- read.csv("data/raw/public_matches.csv")
stopifnot(metrics$matches[metrics$scope=="combined"]==nrow(raw),
          nrow(metrics)==length(unique(raw$game_edition))+1L)
for (scope in metrics$scope) {
  for (kind in c("win","played")) {
    graph <- igraph::read_graph(file.path(first,"results/graphs",paste0(scope,"-",kind,".graphml")),format="graphml")
    edges <- read.csv(file.path(first,"results/graphs",paste0(scope,"-",kind,"-edges.csv")))
    stopifnot(igraph::ecount(graph)==nrow(edges))
  }
}
files <- list.files(first,recursive=TRUE)
stopifnot(identical(files,list.files(second,recursive=TRUE)))
one <- unname(tools::md5sum(file.path(first,files)))
two <- unname(tools::md5sum(file.path(second,files)))
stopifnot(identical(one,two))
report <- readLines(file.path(first,"reports/analysis-notes.md"))
stopifnot(any(grepl(paste0(nrow(raw)," source-backed"),report)))
unlink(c(first,second),recursive=TRUE)
cat("Pipeline integration and reproducibility checks passed.\n")
