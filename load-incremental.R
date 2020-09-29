# This script is used to populate the BigQuery tables for incremental datasets
# the first time. Afterwards the API (when called by pub/sub) will append the
# corresponding files when corresponding. It deletes the existing table first so
# use with caution. Note that this works in parallel and must be run from the
# container in .devcontainer (which includes furrr). It also requires
# environment variable to contain the location of the Google Authentication File

setwd(here::here())
message("Working directory:", getwd())

purrr::walk(list.files(here::here("R"), full.names = T), source)
params <- yaml::read_yaml("params.yaml")

incremental_datasets <- purrr::keep(
  .x = params$datasets,
  # This returns false even if the field is NULL
  .p = ~ "WRITE_APPEND" %in% .$bigquery$write_disposition)

googleCloudStorageR::gcs_auth(json_file = Sys.getenv('GCS_AUTH_FILE'))

# Deletes existing table, creates it again, determines all files that need to be
# appended, and appends all the files to the new table. Dataset must exist
create_incremental_bq <- function(incremental_dataset){

  # Get all files that need to be appended
  incremental_files <- googleCloudStorageR::gcs_list_objects(
    bucket = incremental_dataset$bucket,
    prefix = incremental_dataset$name)$name

  # Create parameters for all files
  construct_dataset_params <- function(file_name, data_params){
    data_params$name <- file_name
    data_params$source_uri <- paste0("gs://", data_params$bucket, "/",
                                     data_params$name)
    data_params$bigquery$create_disposition <- "CREATE_IF_NEEDED"
    data_params
  }
  all_file_params <- purrr::map(.x = incremental_files,
                                .f = construct_dataset_params,
                                data_params = incremental_dataset)

  options(bigrquery.quiet = FALSE)

  # Authenticate to big query
  bigrquery::bq_auth(path = Sys.getenv('GCS_AUTH_FILE'))
  this_table <- bigrquery::bq_table(
    project = incremental_dataset$project,
    dataset = incremental_dataset$bigquery$dataset,
    table = incremental_dataset$bigquery$table)
  if (bigrquery::bq_table_exists(this_table)) {
    bigrquery::bq_table_delete(this_table)
  }

  # Loop over data (file) parameters and appends all files to table. Creates the
  # table if needed
  purrr::walk(all_file_params, upload_to_bq, quiet = FALSE)

}

# Loop over each incremental dataset and create the table
purrr::walk(incremental_datasets, create_incremental_bq)
