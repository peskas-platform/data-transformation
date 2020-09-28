# This script is used to populate the BigQuery tables for incremental datasets
# the first time. Afterwards the API (when called by pub/sub) will append the
# corresponding files when corresponding

purrr::walk(list.files(here::here("R"), full.names = T), source)
params <- yaml::read_yaml("params.yaml")

incremental_datasets <- purrr::keep(
  .x = params$datasets,
  .p = ~ .$bigquery$write_disposition == "WRITE_APPEND")

googleCloudStorageR::gcs_auth(json_file = Sys.getenv('GCS_AUTH_FILE'))

create_incremental_bq <- function(incremental_dataset){
  incremental_files <- googleCloudStorageR::gcs_list_objects(
    bucket = incremental_dataset$bucket,
    prefix = incremental_dataset$name)$name

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

  purrr::map(all_file_params, upload_to_bq)

}

purrr::map(incremental_datasets, create_incremental_bq)
