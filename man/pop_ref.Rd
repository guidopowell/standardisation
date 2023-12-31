% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pop_ref.R
\docType{data}
\name{pop_ref}
\alias{pop_ref}
\title{Données de la population Québecoise}
\format{
Un object de classe \code{"tibble"};
}
\source{
\href{https://publications.msss.gouv.qc.ca/msss/document-001617/}{Publication MSSS}
}
\usage{
data(pop_ref)
}
\description{
Données tirées des estimations et projections du ministère de la santé et des
services sociaux de population par territoire sociosanitaire (Québec, RSS,
RTS, et RLS), par âge et par sexe pour les années 1996-2021 (estimations) et
2022-2041 (projections).
}
\examples{
data(pop_ref)
with(pop_ref,
    weighted.mean(age[geo=="Québec" &annee==2019],
                  w=pop[pop_ref$geo=="Québec" & annee==2019]))
}
\keyword{datasets}
