options(repos = c(CRAN = "https://cloud.r-project.org"))
required <- c("igraph", "jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
cat("Dependencies ready. Run Rscript scripts/run_pipeline.R from the repository root.\n")
