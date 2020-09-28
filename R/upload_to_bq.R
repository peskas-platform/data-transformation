
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
