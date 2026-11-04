# Run from the repository root. Public default inputs and all computation are offline.
args <- commandArgs(trailingOnly=TRUE)
value <- function(key, fallback) {
  hit <- args[startsWith(args,paste0(key,"="))]
  if (length(hit)>1L) stop("Duplicate argument: ",key)
  if (length(hit)) substring(hit,nchar(key)+2L) else fallback
}
known <- c("--input-dir=","--output-dir=","--cutoff=")
if (length(args) && any(!vapply(args,function(a) any(startsWith(a,known)),logical(1))))
  stop("Usage: Rscript scripts/run_pipeline.R [--input-dir=DIR] [--output-dir=DIR] [--cutoff=YYYY-MM-DD]")
source("config/project.R"); source("R/data.R"); source("R/analysis.R"); source("R/report.R")
cutoff_text <- value("--cutoff",as.character(project_config$cutoff))
cutoff <- as.Date(cutoff_text,format="%Y-%m-%d")
if (is.na(cutoff) || format(cutoff,"%Y-%m-%d") != cutoff_text) stop("Invalid cutoff; use YYYY-MM-DD")
input_dir <- value("--input-dir","")
public <- !nzchar(input_dir)
base_dir <- value("--output-dir",if (public) "." else "data/input/analysis")
out <- file.path(base_dir,"results"); clean <- file.path(base_dir,"data","clean")
report <- file.path(base_dir,"reports","mid-project-report.md")
dir.create(out,recursive=TRUE,showWarnings=FALSE);dir.create(clean,recursive=TRUE,showWarnings=FALSE)
if (public) {
  paths <- file.path("data/raw",c("public_matches.csv","public_players.csv","public_earnings.csv"))
  m <- read_project_csv(paths[1],names(read.csv("data/examples/matches.csv"))[1:14])
  p <- read_project_csv(paths[2],names(read.csv("data/examples/players.csv")))
  e <- read_project_csv(paths[3],names(read.csv("data/examples/earnings.csv")))
  inputs <- validate_inputs(m,p,e,cutoff,project_config$editions)
} else {
  paths <- file.path(input_dir,c("matches.csv","players.csv","earnings.csv"))
  inputs <- load_inputs(input_dir,cutoff,project_config$editions)
}
utils::write.csv(inputs$issues,file.path(out,"quality-issues.csv"),row.names=FALSE,na="")
if (inputs$has_errors) stop("Data validation failed. Review ",file.path(out,"quality-issues.csv"),"; previous results may be stale.")
if (!nrow(inputs$matches)) stop("No eligible completed 1v1 matches at the cutoff; previous results may be stale.")
for (name in c("matches","players","earnings"))
  utils::write.csv(inputs[[name]],file.path(clean,paste0(name,".csv")),row.names=FALSE,na="")
a <- analyze_networks(inputs$matches,inputs$players,inputs$earnings,cutoff)
for (name in c("metrics","rankings","correlations","degree_distribution","random_baseline"))
  utils::write.csv(a[[name]],file.path(out,paste0(gsub("_","-",name),".csv")),row.names=FALSE,na="")
dir.create(file.path(out,"graphs"),showWarnings=FALSE)
for (scope in names(a$graphs)) for (kind in c("win","played")) {
  graph <- a$graphs[[scope]][[kind]]
  stem <- file.path(out,"graphs",paste0(scope,"-",kind))
  igraph::write_graph(graph,paste0(stem,".graphml"),format="graphml")
  utils::write.csv(igraph::as_data_frame(graph,what="edges"),paste0(stem,"-edges.csv"),row.names=FALSE,na="")
}
major <- inputs$matches[which(inputs$matches$tier %in% project_config$major_tiers),,drop=FALSE]
major_dir <- file.path(out,"major-tier-sensitivity");dir.create(major_dir,showWarnings=FALSE)
unlink(file.path(major_dir,c("metrics.csv","rankings.csv","correlations.csv")))
if (nrow(major)) {
  s <- analyze_networks(major,inputs$players,inputs$earnings,cutoff)
  for (name in c("metrics","rankings","correlations"))
    utils::write.csv(s[[name]],file.path(major_dir,paste0(name,".csv")),row.names=FALSE,na="")
  sensitivity_status <- if (nrow(major)==nrow(inputs$matches)) "All rows have major-tier labels, so filtering cannot assess lower-tier coverage." else "Major-tier subset exported; inspect its coverage before comparing ranks."
} else sensitivity_status <- "Unavailable: no verified provider tier classifications."
utils::write.csv(data.frame(status=sensitivity_status),file.path(major_dir,"status.csv"),row.names=FALSE)
write_figures(a,file.path(out,"figures"))
write_midproject_report(a,inputs,cutoff,project_config$editions,report,
  if (public) "checked-in public cohort" else "user-supplied canonical CSVs",sensitivity_status)
manifest <- data.frame(key=c("cutoff","input_mode","R","igraph","jsonlite",paste0("md5:",basename(paths))),
  value=c(as.character(cutoff),if(public)"public" else "custom",R.version.string,
    as.character(packageVersion("igraph")),as.character(packageVersion("jsonlite")),unname(tools::md5sum(paths))))
utils::write.csv(manifest,file.path(out,"run-manifest.csv"),row.names=FALSE)
writeLines(sub("[[:space:]]+$","",capture.output(sessionInfo())),file.path(out,"session-info.txt"))
cat("Validated ",nrow(inputs$matches)," matches; generated ",nrow(a$metrics)," network scopes.\nReport: ",report,"\n",sep="")
