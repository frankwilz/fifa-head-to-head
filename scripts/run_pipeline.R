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
source("config/project.R"); source("R/data.R"); source("R/analysis.R"); source("R/report.R"); source("R/metadata.R"); source("R/status.R")
cutoff_text <- value("--cutoff",as.character(project_config$cutoff))
cutoff <- as.Date(cutoff_text,format="%Y-%m-%d")
if (is.na(cutoff) || format(cutoff,"%Y-%m-%d") != cutoff_text) stop("Invalid cutoff; use YYYY-MM-DD")
input_dir <- value("--input-dir","")
public <- !nzchar(input_dir)
base_dir <- value("--output-dir",if (public) "." else "data/input/analysis")
out <- file.path(base_dir,"results"); clean <- file.path(base_dir,"data","clean")
report <- file.path(base_dir,"reports","analysis-notes.md")
dir.create(out,recursive=TRUE,showWarnings=FALSE);dir.create(clean,recursive=TRUE,showWarnings=FALSE)
if (public) {
  paths <- file.path("data/raw",c("public_matches.csv","public_players.csv","public_earnings.csv"))
  m <- read_project_csv(paths[1],names(read.csv("data/examples/matches.csv"))[1:14])
  p <- read_project_csv(paths[2],names(read.csv("data/examples/players.csv")))
  e <- read_project_csv(paths[3],names(read.csv("data/examples/earnings.csv")))
  metadata_paths <- file.path("data/raw",c("tournaments.csv","profile_attributes.csv"))
  read_optional <- function(path) if(file.exists(path)) read.csv(path,colClasses="character",na.strings=c("","NA")) else NULL
  enriched <- enrich_metadata(m,p,read_optional(metadata_paths[1]),read_optional(metadata_paths[2]),cutoff)
  inputs <- validate_inputs(enriched$matches,enriched$players,e,cutoff,project_config$editions)
  inputs$issues <- rbind(inputs$issues,enriched$issues)
  paths <- c(paths,metadata_paths[file.exists(metadata_paths)])
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
unlink(file.path(major_dir,c("metrics.csv","rankings.csv","correlations.csv","rank-comparison.csv","rank-correlations.csv")))
if (nrow(major)) {
  s <- analyze_networks(major,inputs$players,inputs$earnings,cutoff)
  for (name in c("metrics","rankings","correlations"))
    utils::write.csv(s[[name]],file.path(major_dir,paste0(name,".csv")),row.names=FALSE,na="")
  comparison <- compare_sensitivity(a,s)
  utils::write.csv(comparison$ranks,file.path(major_dir,"rank-comparison.csv"),row.names=FALSE,na="")
  utils::write.csv(comparison$correlations,file.path(major_dir,"rank-correlations.csv"),row.names=FALSE,na="")
  sensitivity_status <- if (nrow(major)==nrow(inputs$matches)) "All observed fixtures are world/major events; no domestic-event contrast is available." else paste0("World/major subset exported with common-player rank comparisons (",nrow(major)," of ",nrow(inputs$matches)," fixtures retained).")
} else sensitivity_status <- "No reviewed event-scope classification is available for a world/major subset."
utils::write.csv(data.frame(status=sensitivity_status),file.path(major_dir,"status.csv"),row.names=FALSE)
availability <- coverage_summary(inputs,a,project_config$editions)
utils::write.csv(availability,file.path(out,"availability.csv"),row.names=FALSE,na="")
write_figures(a,file.path(out,"figures"))
write_analysis_notes(a,inputs,cutoff,project_config$editions,report,
  if (public) "checked-in public cohort" else "user-supplied canonical CSVs",sensitivity_status,availability)
manifest <- data.frame(key=c("cutoff","input_mode","R","igraph","jsonlite",paste0("md5:",basename(paths))),
  value=c(as.character(cutoff),if(public)"public" else "custom",R.version.string,
    as.character(packageVersion("igraph")),as.character(packageVersion("jsonlite")),unname(tools::md5sum(paths))))
utils::write.csv(manifest,file.path(out,"run-manifest.csv"),row.names=FALSE)
writeLines(sub("[[:space:]]+$","",capture.output(sessionInfo())),file.path(out,"session-info.txt"))
cat("Validated ",nrow(inputs$matches)," matches; generated ",nrow(a$metrics)," network scopes.\nAnalysis notes: ",report,"\n",sep="")
