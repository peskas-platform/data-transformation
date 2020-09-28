#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

# Pub sub message reference: https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage

library(plumber)

#* @apiTitle Peskas data transformation API * Transform data from Storage to an
#analytics BigQuery table so that records can be processed and validated prior
#to analytics

# Load functions
purrr::walk(list.files(here::here("R"), full.names = T), source)
params <- yaml::read_yaml("params.yaml")

#' Transform data
#' @post /transform-data-pubsub
#' @param message a pub/sub message
function(message=NULL){

  # If message has not been properly parsed, address that
  if (class(message) == "character") {
    message <- jsonlite::fromJSON(message)
  }

  # Only continue if object has been created or overwritten
  if (message$attributes$eventType == "OBJECT_DELETE") {
    message("Notification of object deleted received")
    return(TRUE)
  }

  # Check that we know about that dataset
  this_bucket_datasets <- purrr::keep(
    .x = params$datasets,
    .p = ~ .$bucket==message$attributes$bucketId)
  if (length(this_bucket_datasets) == 0)
    stop("This bucket is not supported for auto-transformation")

  googleCloudRunner::cr_plumber_pubsub(message, transform_data)
}
