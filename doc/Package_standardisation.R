## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = FALSE,error=T, warning=T,fig.align = "center") 


## ----echo=T, collapse=T-------------------------------------------------------
agr<-agregation(donnees = donnees_sim %>% filter(annee == "2022"), 
                   unite = "rss",
                   age = "age",
                   age_cat_mins = c(0,50,60,70),
                   type_num = "filtré",
                   num_filtre_expression = "deces == 'Oui' ",
                   type_denom = "total interne")

## ----echo=T, collapse=T-------------------------------------------------------
st_i<-standardisation_interne(donnees = agr,
                            unite   = "rss",
                            age_cat = "AGE_CAT" ,
                            numerateur = "num",
                            denominateur = "denom",
                            methode = "indirecte",
                            multiplicateur = 100)

## ----echo=T, collapse=T-------------------------------------------------------

st_i$Resultat

## ----echo=T, collapse=T-------------------------------------------------------

st_e<-standardisation_externe(donnees = agr,
                            unite   = "rss",
                            age_cat = "AGE_CAT" ,
                            age_cat_mins = c(0,50,60,70),
                            numerateur = "num",
                            denominateur = "denom",
                            ref_externe_annee = 2022,
                            ref_externe_code = "99",
                            multiplicateur = 100)

st_e$Resultat

## ----echo=T, collapse=T-------------------------------------------------------
#création de données avec zones 
donnees_regroup <- donnees_sim %>% filter(annee == 2021)
donnees_regroup <- donnees_regroup %>% 
  mutate(zone=case_when(rss_code %in% c("06","13") ~ "Mtl_Laval",
                        rss_code %in% c("03","12") ~ "C.N._Ch-Ap.",
                        T ~ rss_code))

#agrégation avec regroupement de dénominateurs externe
agr_avec_regroup<-agregation(donnees = donnees_regroup,
                   unite = "zone",
                   age="age",
                   age_cat_mins = c(0,75),
                   type_num= "filtré",
                   num_filtre_expression="deces == 'Oui' ",
                   type_denom="externe",
                   denom_externe_annee=2021,
                   denom_externe_geo="RSS",
                   denom_externe_type_unite= "Régional",
                   denom_externe_regroupement_unite=
                     list("Mtl_Laval"=c("06","13"),
                          "C.N._Ch-Ap." = c("03","12"))
)

print(agr_avec_regroup,n = Inf)

## ----echo=T, collapse=T-------------------------------------------------------
st_i<-standardisation_interne(donnees = agr,
                            unite   = "rss",
                            age_cat = "AGE_CAT" ,
                            numerateur = "num",
                            denominateur = "denom",
                            reference_unite = "06_Montréal",
                            methode = "indirecte",
                            multiplicateur = 100)

## ----echo=T, collapse=T-------------------------------------------------------

st_i$Resultat

## ----echo=T, collapse=T-------------------------------------------------------

agr_ext<-agregation(donnees = donnees_sim , 
                unite = "annee",
                age = "age",
                age_cat_mins = c(18,65,85),
                sexe="sexe",
                type_num = "filtré",
                num_filtre_expression = "deces == 'Oui' ",
                type_denom = "externe",
                denom_externe_type_unite = "Annuel")

print(agr_ext)

## ----echo=T, collapse=T-------------------------------------------------------

st_ext<-standardisation_externe(donnees = agr_ext,
                            unite   = "annee",
                            age_cat = "AGE_CAT" ,
                            age_cat_mins = c(18,65,85),
                            sexe="sexe",
                            numerateur = "num",
                            denominateur = "denom",
                            ref_externe_annee = 2022,
                            ref_externe_code = "99",
                            multiplicateur = 100000)

st_ext$Resultat

