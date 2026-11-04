for (f in c("tests/test_data.R", "tests/test_analysis.R", "tests/test_api_clients.R", "tests/test_pipeline.R")) {
  status <- system2(file.path(R.home("bin"), "Rscript"), f)
  if (status != 0) stop("Failed: ", f)
}
cat("All project tests passed.\n")
