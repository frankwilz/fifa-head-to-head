# Esports Earnings v0: https://www.esportsearnings.com/apidocs
# Keys are sent over HTTPS using curl's standard input, never command arguments.

earnings_method_params <- list(
  LookupPlayerById = "playerid",
  LookupPlayerTournaments = c("playerid", "offset"),
  LookupHighestEarningPlayers = "offset",
  LookupGameById = "gameid",
  LookupHighestEarningPlayersByGame = c("gameid", "offset"),
  LookupRecentTournaments = "offset",
  LookupTournamentById = "tournamentid",
  LookupTournamentResultsByTournamentId = "tournamentid"
)

.earnings_state <- new.env(parent = emptyenv())
.earnings_state$last_request <- -Inf

validate_earnings_job <- function(method, params = list()) {
  if (length(method) != 1L || is.na(method) ||
      !method %in% names(earnings_method_params)) {
    stop("Unsupported Esports Earnings method.", call. = FALSE)
  }
  if (!is.list(params) || (length(params) &&
      (is.null(names(params)) || anyDuplicated(names(params))))) {
    stop("Parameters must be a uniquely named list.", call. = FALSE)
  }
  allowed <- earnings_method_params[[method]]
  if (any(!names(params) %in% allowed)) {
    stop("Unsupported parameter for this method.", call. = FALSE)
  }
  required <- setdiff(allowed, "offset")
  if (length(setdiff(required, names(params)))) {
    stop("Required numeric ID is missing.", call. = FALSE)
  }
  if ("offset" %in% allowed && !"offset" %in% names(params)) {
    params$offset <- "0"
  }
  params <- lapply(params, function(value) {
    if (length(value) != 1L || is.na(value) ||
        !grepl("^[0-9]+$", as.character(value))) {
      stop("API IDs and offsets must be nonnegative integer strings.", call. = FALSE)
    }
    as.character(value)
  })
  params[sort(names(params))]
}

earnings_cache_path <- function(method, params, cache_dir) {
  params <- validate_earnings_job(method, params)
  suffix <- paste(vapply(names(params), function(n) {
    paste(n, params[[n]], sep = "-")
  }, character(1)), collapse = "_")
  file.path(cache_dir, paste0(method, if (nzchar(suffix)) paste0("_", suffix), ".json"))
}

parse_earnings_json <- function(body) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Install jsonlite before importing API responses.", call. = FALSE)
  }
  parsed <- tryCatch(jsonlite::fromJSON(body, simplifyVector = FALSE),
                     error = function(e) NULL)
  if (is.null(parsed)) stop("API response is not valid JSON.", call. = FALSE)
  if (is.list(parsed) && "ErrorCode" %in% names(parsed)) {
    code <- parsed$ErrorCode
    code <- if (length(code) == 1L && !is.na(code) &&
                grepl("^[0-9]+$", as.character(code))) as.character(code) else "unknown"
    stop(paste("Esports Earnings API returned ErrorCode", code), call. = FALSE)
  }
  parsed
}

earnings_curl_transport <- function(method, params, api_key) {
  curl <- Sys.which("curl")
  if (!nzchar(curl)) stop("curl is required for live API requests.", call. = FALSE)
  query <- c(list(apikey = api_key, format = "json"), params)
  encoded <- vapply(query, utils::URLencode, character(1), reserved = TRUE)
  url <- paste0("https://api.esportsearnings.com/v0/", method, "?",
                paste(names(encoded), encoded, sep = "=", collapse = "&"))
  # Do not follow redirects or downgrade to HTTP. The config travels on stdin.
  body_path <- tempfile("earnings-response-")
  on.exit(unlink(body_path), add = TRUE)
  config <- paste0('url = "', url, '"\noutput = "',
                   gsub('"', '\\"', body_path, fixed = TRUE), '"\n')
  status <- tryCatch(
    suppressWarnings(system2(curl, c("--silent", "--show-error", "--fail-with-body",
      "--connect-timeout", "15", "--max-time", "60", "--proto", "=https",
      "--config", "-", "--write-out", shQuote("%{http_code}")),
      stdout = TRUE, stderr = FALSE, input = config)),
    error = function(e) NULL
  )
  # Deliberately never repeat curl diagnostics, request URLs or response bodies.
  if (is.null(status) || length(status) != 1L ||
      !grepl("^[0-9]{3}$", status)) {
    stop("API transport failed; no response was cached.", call. = FALSE)
  }
  list(status = as.integer(status), body = if (file.exists(body_path)) {
    paste(readLines(body_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else "")
}

earnings_request <- function(method, params = list(),
                             cache_dir = "data/raw/esports-earnings",
                             refresh = FALSE,
                             api_key = Sys.getenv("ESPORTS_EARNINGS_API_KEY"),
                             transport = earnings_curl_transport,
                             clock = function() as.numeric(Sys.time()),
                             sleeper = Sys.sleep,
                             state = .earnings_state) {
  params <- validate_earnings_job(method, params)
  path <- earnings_cache_path(method, params, cache_dir)
  if (file.exists(path) && !refresh) {
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    return(list(data = parse_earnings_json(body), cached = TRUE, path = path,
                method = method, params = params))
  }
  if (length(api_key) != 1L || is.na(api_key) || !nzchar(api_key)) {
    stop("Set ESPORTS_EARNINGS_API_KEY locally before a live request.", call. = FALSE)
  }
  if (is.null(state$last_request)) state$last_request <- -Inf
  delay <- 1.05 - (clock() - state$last_request)
  if (is.finite(delay) && delay > 0) sleeper(delay)
  state$last_request <- clock()
  response <- tryCatch(transport(method, params, api_key), error = function(e) {
    stop("API transport failed; no response was cached.", call. = FALSE)
  })
  if (!is.list(response) || length(response$status) != 1L ||
      is.na(response$status) || response$status != 200L) {
    stop("API did not return HTTP 200; no response was cached.", call. = FALSE)
  }
  if (!is.character(response$body) || length(response$body) != 1L) {
    stop("API response body is missing.", call. = FALSE)
  }
  if (grepl(api_key, response$body, fixed = TRUE)) {
    stop("API response appears to contain the credential; it was not cached.", call. = FALSE)
  }
  parsed <- parse_earnings_json(response$body)
  # Cache successful responses only. No request URL or key is persisted.
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("response-", tmpdir = cache_dir)
  on.exit(unlink(tmp), add = TRUE)
  writeLines(response$body, tmp, useBytes = TRUE)
  if (!file.rename(tmp, path)) stop("Could not save API cache.", call. = FALSE)
  metadata <- list(method = method, params = params,
                   retrieved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
                   documentation = "https://www.esportsearnings.com/apidocs")
  jsonlite::write_json(metadata, paste0(path, ".metadata.json"), auto_unbox = TRUE,
                       pretty = TRUE)
  list(data = parsed, cached = FALSE, path = path, method = method, params = params)
}

# Explicit pagination is bounded: callers must choose how many 100-row pages.
earnings_pages <- function(method, params = list(), max_pages = 1L, ...) {
  params <- validate_earnings_job(method, params)
  if (!"offset" %in% names(params)) {
    stop("This API method does not support pagination.", call. = FALSE)
  }
  if (length(max_pages) != 1L || is.na(max_pages) || max_pages < 1 ||
      max_pages != as.integer(max_pages)) stop("max_pages must be positive.", call. = FALSE)
  start <- as.numeric(params$offset)
  pages <- list()
  for (i in seq_len(max_pages)) {
    params$offset <- format(start + (i - 1L) * 100, scientific = FALSE, trim = TRUE)
    page <- earnings_request(method, params, ...)
    pages[[length(pages) + 1L]] <- page
    if (length(page$data) < 100L) break
  }
  pages
}
