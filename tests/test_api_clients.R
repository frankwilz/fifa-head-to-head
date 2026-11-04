source("R/api_clients.R")
assert_error <- function(expr, contains = NULL) {
  message <- tryCatch({force(expr); NULL}, error = function(e) conditionMessage(e))
  stopifnot(!is.null(message))
  if (!is.null(contains)) stopifnot(grepl(contains, message, fixed = TRUE))
  invisible(message)
}
temp_cache <- tempfile("earnings-test-")
dir.create(temp_cache)
test_state <- new.env(parent = emptyenv())
test_state$last_request <- -Inf
test_clock <- 100
sleeps <- numeric()
calls <- 0L
transport <- function(method, params, api_key) {
  calls <<- calls + 1L
  list(status = 200L, body = '{"TotalUSDPrize":123.5,"CurrentHandle":"Example"}')
}
first <- earnings_request("LookupPlayerById", list(playerid = "123"),
  cache_dir = temp_cache, api_key = "test-secret", transport = transport,
  clock = function() test_clock, sleeper = function(x) { sleeps <<- c(sleeps, x); test_clock <<- test_clock + x }, state = test_state)
stopifnot(!first$cached, identical(first$data$TotalUSDPrize, 123.5), calls == 1L)
second <- earnings_request("LookupPlayerById", list(playerid = "123"),
  cache_dir = temp_cache, api_key = "", transport = function(...) stop("must not run"))
stopifnot(second$cached, calls == 1L)
invisible(earnings_request("LookupPlayerById", list(playerid = "124"),
  cache_dir = temp_cache, api_key = "test-secret", transport = transport,
  clock = function() test_clock, sleeper = function(x) { sleeps <<- c(sleeps, x); test_clock <<- test_clock + x }, state = test_state))
stopifnot(length(sleeps) == 1L, sleeps[[1]] >= 1)
cache_text <- paste(unlist(lapply(list.files(temp_cache, full.names = TRUE), readLines)), collapse = "\n")
stopifnot(!grepl("test-secret", cache_text, fixed = TRUE))
assert_error(earnings_request("LookupPlayerById", list(playerid = "x")), "integer")
assert_error(earnings_request("LookupPlayerById", list(playerid = "1", apikey = "bad")), "Unsupported parameter")
assert_error(earnings_request("Unknown", list()), "Unsupported")
assert_error(earnings_request("LookupPlayerById", list(playerid = "999"), cache_dir = temp_cache, api_key = ""), "Set ESPORTS")
error_message <- assert_error(earnings_request("LookupPlayerById", list(playerid = "999"),
  cache_dir = temp_cache, api_key = "test-secret", transport = function(...) stop("https://example?apikey=test-secret"),
  state = new.env(), sleeper = function(...) NULL), "transport failed")
stopifnot(!grepl("test-secret", error_message, fixed = TRUE))
assert_error(earnings_request("LookupPlayerById", list(playerid = "999"),
  cache_dir = temp_cache, api_key = "test-secret", transport = function(...) list(status = 403L, body = "secret"),
  state = new.env(), sleeper = function(...) NULL), "HTTP 200")
assert_error(earnings_request("LookupPlayerById", list(playerid = "999"),
  cache_dir = temp_cache, api_key = "test-secret", transport = function(...) list(status = 200L, body = '{"ErrorCode":1010}'),
  state = new.env(), sleeper = function(...) NULL), "ErrorCode 1010")
assert_error(earnings_request("LookupPlayerById", list(playerid = "999"),
  cache_dir = temp_cache, api_key = "test-secret", transport = function(...) list(status = 200L, body = '{"echo":"test-secret"}'),
  state = new.env(), sleeper = function(...) NULL), "credential")
stopifnot(!file.exists(earnings_cache_path("LookupPlayerById", list(playerid = "999"), temp_cache)))
assert_error(parse_earnings_json("invalid"), "not valid JSON")
offsets <- character()
pages <- earnings_pages("LookupPlayerTournaments", list(playerid = "5"), max_pages = 3,
  cache_dir = temp_cache, api_key = "test-secret",
  transport = function(method, params, api_key) {
    offsets <<- c(offsets, params$offset)
    body <- if (params$offset == "0") jsonlite::toJSON(rep(list(list(TournamentName = "T")), 100), auto_unbox = TRUE) else "[]"
    list(status = 200L, body = as.character(body))
  }, state = new.env(), sleeper = function(...) NULL)
stopifnot(identical(offsets, c("0", "100")), length(pages) == 2L)
unlink(temp_cache, recursive = TRUE)
cat("API client tests passed (mock transport only).\n")
