#' Données de la population Québecoise
#'
#' Données tirées des estimations et projections du ministère de la santé et des
#' services sociaux de population par territoire sociosanitaire (Québec, RSS,
#' RTS, et RLS), par âge et par sexe pour les années 1996-2021 (estimations) et
#' 2022-2041 (projections). 
#' 
#' @docType data
#'
#' @usage data(pop_ref)
#'
#' @format Un object de classe \code{"tibble"};
#'
#' @keywords datasets
#'
#' @source \href{https://publications.msss.gouv.qc.ca/msss/document-001617/}{Publication MSSS}
#'
#' @examples
#' data(pop_ref)
#'with(pop_ref,
#'     weighted.mean(age[geo=="Québec" &annee==2019],
#'                   w=pop[pop_ref$geo=="Québec" & annee==2019]))
"pop_ref"