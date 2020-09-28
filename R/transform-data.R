


transform_data <- function(x){

  # If message has not been properly parsed, address that
  if (class(x) == "character") {
    x <- jsonlite::fromJSON(x)
  }

  params <- yaml::read_yaml("params.yaml")

  cat(as.character(list(x = x)))

  # Identify and validate dataset
  this_dataset <- purrr::keep(
    .x = params$datasets,
    .p = ~ grepl(.$name, x$name) & .$bucket == .$bucket)
  if (length(this_dataset) == 0)
    stop("This object is not supported for auto-transformation")
  if (length(this_dataset) > 1)
    stop("There is than one specification for this transformation. Contact the administrator")
  this_dataset <- this_dataset[[1]]

  # If we're supposed to ignore it
  if (!is.null(this_dataset$ignore)){
    if (this_dataset$ignore) {
      warning("The API has been configured to ignore this file")
      return(TRUE)
    }
  }

  # Build URI
  this_dataset$source_uri <- paste0("gs://", x$bucket, "/", x$name)
  this_dataset$name <- x$name

  if (!is.null(this_dataset$bigquery$schema_path)){
    this_schema <- bigrquery::as_bq_fields(
      jsonlite::read_json(this_dataset$bigquery$schema_path)
    )
  } else {
    this_schema <- NULL
  }

  cat(as.character(list(this_dataset = this_dataset)))
  upload_to_bq(this_dataset)
}

