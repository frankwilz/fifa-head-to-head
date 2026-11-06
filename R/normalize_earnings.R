# Normalize reviewed API caches; no network or credentials are used here.
source("R/api_clients.R")

normalize_earnings_caches <- function(manifest, player_map, game_map=NULL) {
  need <- c("cache_file","method","provider_player_id","provider_game_id","as_of","source_url")
  if (anyDuplicated(names(manifest)) || !all(need %in% names(manifest))) stop("Cache manifest is missing required unique columns")
  if (anyDuplicated(names(player_map)) || !all(c("provider_player_id","player_id") %in% names(player_map))) stop("Player map is missing required unique columns")
  provider_id <- function(x) length(x)==1L && !is.na(x) &&
    is.atomic(x) && grepl("^[1-9][0-9]*$",as.character(x))
  if (anyNA(player_map$provider_player_id) || anyNA(player_map$player_id) ||
      any(!vapply(as.list(player_map$provider_player_id),provider_id,logical(1))) ||
      any(!nzchar(trimws(as.character(player_map$player_id)))) ||
      any(as.character(player_map$player_id)!=trimws(as.character(player_map$player_id))) ||
      anyDuplicated(player_map$provider_player_id) || anyDuplicated(player_map$player_id))
    stop("Player map must be an unambiguous one-to-one identity mapping")
  allowed <- c("LookupPlayerById","LookupHighestEarningPlayersByGame")
  output <- data.frame(player_id=character(),scope=character(),game_edition=character(),
    earnings_usd=numeric(),as_of=character(),source_url=character(),
    coverage_status=character(),measurement=character(),stringsAsFactors=FALSE)
  rejected <- data.frame(cache_file=character(),provider_player_id=character(),reason=character())
  for (i in seq_len(nrow(manifest))) {
    job <- manifest[i,,drop=FALSE]
    if (!job$method %in% allowed) stop("Unsupported earnings normalization method")
    d <- suppressWarnings(as.Date(job$as_of,format="%Y-%m-%d"))
    if (is.na(d) || format(d,"%Y-%m-%d") != job$as_of) stop("Manifest needs a valid snapshot as_of date")
    if (is.na(job$cache_file) || !nzchar(job$cache_file) || !file.exists(job$cache_file)) stop("Manifest cache file is missing")
    if (is.na(job$source_url) || grepl("[?#[:space:]]",job$source_url) ||
        !grepl("^https://www\\.esportsearnings\\.com/(players|games)/[1-9][0-9]*(-[^/?#[:space:]]+)?/?$",job$source_url))
      stop("Use a credential-free Esports Earnings player or game source URL without query or fragment")
    body <- tryCatch(paste(readLines(job$cache_file,warn=FALSE,encoding="UTF-8"),collapse="\n"),
      error=function(e) stop("Could not read manifest cache file",call.=FALSE))
    parsed <- parse_earnings_json(body)
    metadata_path <- paste0(job$cache_file,".metadata.json")
    cache_metadata <- if (file.exists(metadata_path)) parse_earnings_json(
      paste(readLines(metadata_path,warn=FALSE),collapse="\n")) else NULL
    if (!is.null(cache_metadata) && (!is.list(cache_metadata) || !is.list(cache_metadata$params) ||
        !identical(cache_metadata$method,as.character(job$method)))) stop("Cache metadata method disagrees with manifest")
    if (!is.null(cache_metadata)) {
      retrieved <- cache_metadata$retrieved_at_utc
      if (length(retrieved)!=1L || !is.character(retrieved) || is.na(retrieved) ||
          !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} ",retrieved) ||
          !identical(substr(retrieved,1,10),as.character(d)))
        stop("Live-cache snapshot as_of must match its recorded UTC retrieval date")
    }
    if (job$method=="LookupPlayerById") {
      if (!is.na(job$provider_game_id) && nzchar(job$provider_game_id)) stop("Career player lookup must not specify a game ID")
      id <- as.character(job$provider_player_id)
      if (!provider_id(id)) stop("Player lookup needs its reviewed provider ID")
      source_id <- sub("^https://www\\.esportsearnings\\.com/players/([0-9]+).*$","\\1",job$source_url)
      if (!identical(source_id,id)) stop("Player source URL disagrees with reviewed provider ID")
      if (!is.null(cache_metadata) && !identical(as.character(cache_metadata$params$playerid),id)) stop("Cached player ID disagrees with manifest")
      if (!is.list(parsed) || !"TotalUSDPrize" %in% names(parsed)) stop("Player response lacks TotalUSDPrize")
      records <- list(list(PlayerId=id,TotalUSDPrize=parsed$TotalUSDPrize))
      edition <- NA_character_; scope <- "career"
    } else {
      if (!is.na(job$provider_player_id) && nzchar(job$provider_player_id)) stop("Game ranking must not specify a single player ID")
      if (is.null(game_map) || !all(c("provider_game_id","game_edition") %in% names(game_map)) ||
          anyDuplicated(names(game_map)) || anyNA(game_map$provider_game_id) ||
          anyNA(game_map$game_edition) || any(!game_map$game_edition %in% c(paste0("FIFA",18:23),paste0("FC",24:26))) ||
          any(!vapply(as.list(game_map$provider_game_id),provider_id,logical(1))) ||
          anyDuplicated(game_map$provider_game_id) || anyDuplicated(game_map$game_edition)) stop("Need a unique game-edition map")
      if (!provider_id(job$provider_game_id)) stop("Game ranking needs its reviewed provider ID")
      source_id <- sub("^https://www\\.esportsearnings\\.com/games/([0-9]+).*$","\\1",job$source_url)
      if (!identical(source_id,as.character(job$provider_game_id))) stop("Game source URL disagrees with reviewed provider ID")
      if (!is.null(cache_metadata) && !identical(as.character(cache_metadata$params$gameid),as.character(job$provider_game_id))) stop("Cached game ID disagrees with manifest")
      index <- match(as.character(job$provider_game_id),as.character(game_map$provider_game_id))
      if (is.na(index)) stop("Game ID is not mapped to a verified edition")
      edition <- as.character(game_map$game_edition[index])
      if (is.na(edition) || !edition %in% c(paste0("FIFA",18:23),paste0("FC",24:26))) stop("Unsupported edition in game map")
      records <- parsed; scope <- "edition"
      if (!grepl("^\\s*\\[",body) || !is.list(records) || !is.null(names(records))) stop("Game ranking response must be an array of player rows")
    }
    for (record in records) {
      if (!is.list(record) || !all(c("PlayerId","TotalUSDPrize") %in% names(record))) stop("Earnings row lacks provider ID or USD total")
      if (!provider_id(record$PlayerId)) stop("Invalid provider player ID")
      id <- as.character(record$PlayerId)
      if (!provider_id(id)) stop("Invalid provider player ID")
      raw_amount <- record$TotalUSDPrize
      if (!is.atomic(raw_amount) || is.logical(raw_amount) || length(raw_amount)!=1L || is.na(raw_amount)) stop("Invalid reported USD earnings")
      amount <- suppressWarnings(as.numeric(raw_amount))
      if (length(amount)!=1L || !is.finite(amount) || amount<0) stop("Invalid reported USD earnings")
      at <- match(id,as.character(player_map$provider_player_id))
      if (is.na(at)) {
        rejected <- rbind(rejected,data.frame(cache_file=job$cache_file,provider_player_id=id,reason="unmapped identity"))
        next
      }
      coverage <- if ("coverage_status" %in% names(job) && !is.na(job$coverage_status) && nzchar(job$coverage_status)) job$coverage_status else "provider_recorded_completeness_unverified"
      output <- rbind(output,data.frame(player_id=player_map$player_id[at],scope=scope,game_edition=edition,
        earnings_usd=amount,as_of=as.character(d),source_url=job$source_url,
        coverage_status=coverage,measurement=paste0("provider_recorded_",scope,"_total"),stringsAsFactors=FALSE))
    }
  }
  key <- paste(output$player_id,output$scope,output$game_edition,output$as_of)
  if (anyDuplicated(key)) stop("Overlapping total snapshots; resolve duplicates instead of summing them")
  output <- output[order(output$player_id,output$scope,output$game_edition,output$as_of),,drop=FALSE]
  rownames(output) <- NULL
  list(earnings=output,rejected=rejected)
}
