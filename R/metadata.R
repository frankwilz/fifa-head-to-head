# Apply reviewed metadata without overwriting observations or inventing values.
enrich_metadata <- function(matches,players,tournaments=NULL,attributes=NULL,cutoff=NULL) {
  issues <- data.frame(table=character(),row=integer(),id=character(),severity=character(),reason=character())
  empty <- function(x) is.na(x) | !nzchar(trimws(x))
  https <- function(x) !empty(x) & grepl("^https://[^/?#[:space:]]+([/?#][^[:space:]]*)?$",x)
  if (!is.null(tournaments) && nrow(tournaments)) {
    required <- c("tournament_id","tier","tier_source_url","platform","platform_source_url","tier_scheme")
    if (!all(required %in% names(tournaments)) || any(empty(tournaments$tournament_id)) || anyDuplicated(tournaments$tournament_id)) stop("Tournament metadata needs unique IDs and provenance columns")
    if (any(!empty(tournaments$tier) & empty(tournaments$tier_scheme))) stop("Known tiers need an explicit classification scheme")
    at <- match(matches$tournament_id,tournaments$tournament_id)
    for (field in c("tier","platform")) {
      source <- tournaments[[paste0(field,"_source_url")]][at]
      candidate <- tournaments[[field]][at]
      known <- !empty(candidate)
      if (any(known & !https(source))) stop("Metadata values require HTTPS provenance")
      conflict <- known & !empty(matches[[field]]) & matches[[field]]!=candidate
      if (any(conflict)) stop("Conflicting tournament metadata for ",field)
      fill <- known & empty(matches[[field]])
      matches[[field]][fill] <- candidate[fill]
      column <- paste0(field,"_source_url")
      if (!column %in% names(matches)) matches[[column]] <- ifelse(empty(matches[[field]]),NA_character_,matches$source_url)
      matches[[column]][known] <- source[known]
    }
    if (!"tier_scheme" %in% names(matches)) matches$tier_scheme <- NA_character_
    known <- !empty(tournaments$tier_scheme[at])
    matches$tier_scheme[known] <- tournaments$tier_scheme[at][known]
  }
  if (!is.null(attributes) && nrow(attributes)) {
    if (!all(c("player_id","country","source_url","as_of") %in% names(attributes)) ||
        any(empty(attributes$player_id)) || anyDuplicated(attributes$player_id)) stop("Player attributes need unique IDs and provenance")
    dates <- suppressWarnings(as.Date(attributes$as_of,format="%Y-%m-%d"))
    if (anyNA(dates) || any(format(dates,"%Y-%m-%d")!=attributes$as_of)) stop("Player attributes need valid snapshot dates")
    if (!is.null(cutoff)) {
      if (!inherits(cutoff,"Date") || length(cutoff)!=1L || is.na(cutoff)) stop("Metadata cutoff must be one valid Date")
      attributes <- attributes[dates<=cutoff,,drop=FALSE]
    }
    at <- match(players$player_id,attributes$player_id)
    candidate <- attributes$country[at]; urls <- attributes$source_url[at]
    known <- !empty(candidate)
    if (any(known & (!grepl("^[A-Z]{2}$",candidate) | !https(urls)))) stop("Country enrichment needs ISO alpha-2 and HTTPS provenance")
    conflict <- known & !empty(players$country) & players$country!=candidate
    if (any(conflict)) issues <- rbind(issues,data.frame(table="players",row=which(conflict),id=players$player_id[conflict],severity="warning",reason="country sources disagree; retained original observation"))
    fill <- known & empty(players$country)
    players$country[fill] <- candidate[fill]
    if (!"country_source_url" %in% names(players)) players$country_source_url <- ifelse(empty(players$country),NA_character_,players$source_url)
    players$country_source_url[fill] <- urls[fill]
  }
  list(matches=matches,players=players,issues=issues)
}
