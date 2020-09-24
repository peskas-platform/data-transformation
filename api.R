library(plumber)

#* @apiTitle Pekas data transformation API

#' Transform KOBO survey data
#' @post /transform-kobo
#' @param message a pub/sub message
function(message=NULL){
  googleCloudRunner::cr_plumber_pubsub(message, transform_kobo)
}


#' Receive pub/sub message
#' @post /transform-pelagic
#' @param message a pub/sub message
function(message=NULL){
  googleCloudRunner::cr_plumber_pubsub(message, transform_pelagic)
}

transform_kobo <- function(x){
  list(msg = x)
}

transform_pelagic <- function(x){
  list(msg = x)
}
