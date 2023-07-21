#' Données simulées de patients COVID-19 au Québec
#'
#' Données simulées basées sur les distribution d'âge, de sexe, et de décès par 
#' région RSS d'un échantillon de 10% des patients hospitalisés pour la COVID-19
#' au Québec de 2020 à 2022. 
#'
#' @docType data
#'
#' @usage data(donnees_sim)
#'
#' @format Un object de classe \code{"tibble"};
#'
#' @keywords datasets
#'
#'
#' @examples
#' data(donnees_sim)
#' table(donnees_sim$deces)
"donnees_sim"