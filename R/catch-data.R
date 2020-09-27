
upload_to_bq <- function(source_uri, format, project, location, dataset, table, overwrite = TRUE){

  bigrquery::bq_auth(path = "auth/data-transformation-secret.json")

  dataset_bq <- bigrquery::bq_dataset(project, dataset)

  if (!bigrquery::bq_dataset_exists(dataset_bq)) {
    bigrquery::bq_dataset_create(dataset_bq, location = location)
  }

  table_bq <- bigrquery::bq_table(project, dataset, table)

  if (!bigrquery::bq_table_exists(table_bq)) {
    bigrquery::bq_table_create(table_bq)
  }

  bigrquery::bq_table_load(
    table_bq,
    source_uris = source_uri,
    source_format = format,
    write_disposition = "WRITE_TRUNCATE")

}


transform_data <- function(x){
  # If message has not been properly parsed, address that
  if (class(x) == "character") {
    x <- jsonlite::fromJSON(x)
  }

  browser()
  this_dataset <- purrr::keep(params$datasets, ~ grepl(.$name, x$name) & .$bucket == .$bucket)

  if (length(this_dataset) == 0)
    stop("This bucket is not supported for auto-transformation")

  if (length(this_dataset) > 1)
    stop("There is than one specification for this transformation. Contact the administrator")

  this_dataset <- this_dataset[[1]]

  if (this_dataset$ingestion$type == "all-data") {
    upload_to_bq()
  }
}

