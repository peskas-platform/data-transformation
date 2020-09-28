
upload_to_bq <- function(this_data, ...){

  cat(Sys.getenv('GCS_AUTH_FILE'))
  # Authenticate to big query
  bigrquery::bq_auth(path = Sys.getenv('GCS_AUTH_FILE'))

  # Check if dataset exists
  dataset_bq <- bigrquery::bq_dataset(project = this_data$project,
                                      dataset = this_data$bigquery$dataset)
  if (!bigrquery::bq_dataset_exists(dataset_bq)) {
    bigrquery::bq_dataset_create(x = dataset_bq,
                                 location = this_data$bigquery$location)
  }

  table_bq <- bigrquery::bq_table(project = this_data$project,
                                  dataset = this_data$bigquery$dataset,
                                  table = this_data$bigquery$table)

  # If we are downloading the data first for some pre-processing
  if (this_data$bigquery$mode == "download-first"){
    # Login to cloud storage
    googleCloudStorageR::gcs_auth(json_file = Sys.getenv('GCS_AUTH_FILE'))

    # Workflow for csv data
    if(this_data$source_format == "CSV"){

      # Download csv data
      values_path <- tempfile(fileext = ".csv")
      values_path <- basename(values_path)
      # Make sure file is deleted
      on.exit(file.remove(values_path))

      googleCloudStorageR::gcs_get_object(object_name = this_data$name,
                                          bucket = this_data$bucket,
                                          saveToDisk = values_path)
      cat("downloaded data\n")
      # Clean column names
      values <- readr::read_csv(values_path, guess_max = 10000,
                                col_types = this_data$col_types)
      values <- janitor::clean_names(values)
      cat("cleaned colnames\n")
      # Upload data
      bigrquery::bq_table_upload(
        table_bq,
        values,
        write_disposition = this_data$bigquery$write_disposition,
        create_disposition = this_data$bigquery$create_disposition,
        quiet = TRUE)
      cat("uploaded data\n")

    } else {
      "Don't know how to process that type of data"
    }
  } else if (this_data$bigquery$mode == "direct") {

    bigrquery::bq_table_load(
      x = table_bq,
      source_uris = this_data$source_uri,
      source_format = this_data$source_format,
      write_disposition = this_data$bigquery$write_disposition,
      create_disposition = this_data$bigquery$create_disposition,
      nskip = this_data$bigquery$nskip)
  }
}


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

