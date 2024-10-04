#' Print method for "agregation" class
#' 
#' @param x an object of class "agregation"
#' 
#' @export print.agregation
#' @export

print.agregation<-function(x){
  print(x$df)
}