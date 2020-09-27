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

#* @apiTitle Pekas data transformation API
#*

# Load functions
purrr::walk(list.files(here::here("R"), full.names = T), source)
params <- yaml::read_yaml("params.yaml")

#'
#' @post /transform-pelagic-pubsub
#' @param message a pub/sub message
function(message=NULL){
  googleCloudRunner::cr_plumber_pubsub(message, transform_kobo)
}


#' Transform KOBO survey data
#' @post /transform-timor-pubsub
#' @param message a pub/sub message
function(message=NULL){

  # If message has not been properly parsed, address that
  if (class(message) == "character") {
    message <- jsonlite::fromJSON(message)
  }

  # Only continue if object has been created or overwritten
  if (message$attributes$eventType != "OBJECT_FINALIZE") {
    return(TRUE)
  }

  this_bucket_datasets <- purrr::keep(params$datasets, ~ .$bucket==message$attributes$bucketId)

  if (length(this_bucket_datasets) == 0)
    stop("This bucket is not supported for auto-transformation")

  googleCloudRunner::cr_plumber_pubsub(message, transform_data)

}



