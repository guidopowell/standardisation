#' @title Standardisation externe
#'
#' @description   Cette fonction applique une standardisation externe à des données agrégées, 
#' prenant comme référence un fichier de données pop_ref réprésentant la population du Québec 
#' stratifiée par âge et sexe, à de différentes années et niveaux géographiques. 
#' La standardisation externe doit être directe.
#'
#' @param donnees Un dataframe contenant les données à analyser.
#' @param unite Un champ dans le dataframe qui indique l'unité d'analyse (par exemple, la région ou l'année).
#' @param age_cat Un champ dans le dataframe qui indique les groupes d'âge.
#' @param age_cat_mins Un vecteur contenant les âges minimaux de chaque groupe d'âge. Cet argument sert à grouper la variable d'âge des données externe de référence. 
#' @param age_filtre_max Une valeur numérique indiquant le filtre d'âge maximum exclusif, Inf par défaut.
#' @param sexe Un champ dans le dataframe qui indique le sexe de chaque individu. Les valeurs de cette variable doivent être "M" et "F". Facultatif.
#' @param numerateur Un champ dans le dataframe qui représente le numérateur de la mesure de taux.
#' @param denominateur Un champ dans le dataframe qui représente le dénominateur de la mesure de taux.
#' @param ref_externe_annee Un champ dans le dataframe qui indique l'année de référence externe.
#' @param ref_externe_code Un champ dans le dataframe qui indique le code de référence externe.
#' @param multiplicateur Un nombre par lequel les taux standardisés sont multipliés (par exemple, 1000 pour obtenir des taux pour 1000 personnes).
#'
#' @return Une liste contenant deux éléments : "Resultat" (un dataframe contenant les résultats de la standardisation) 
#'         et "Details" (un dataframe contenant les données agrégées utilisées pour effectuer la standardisation).

#' @keywords internal
#' @encoding UTF-8
#' @import tidyverse PHEindicatormethods rlang
#' @export
#' @examples
#' \dontrun{
#' # Exemple d'utilisation de la fonction standardisation_externe
#'
#' # Créer un dataframe exemple
#' donnees <- data.frame(
#'   expand.grid(region =c("Région 1", "Région 2"),
#'               groupe_age =c("20-29", "30-39", "40-49", "50-59", "60-69", "70-79"),
#'               sexe = c("F", "M")),
#'   numerateur = rpois(24, 10),
#'   denominateur = rpois(24, 200)
#' )
#' 
#' # Utiliser la fonction standardisation_externe
#' resultat <- standardisation_externe(
#'   donnees = donnees,
#'   unite = "region",
#'   age_cat = "groupe_age",
#'   age_cat_mins = c(20, 30, 40, 50, 60, 70),
#'   numerateur = "numerateur",
#'   denominateur = "denominateur",
#'   ref_externe_annee = 2022,
#'   ref_externe_code = "99",
#'   multiplicateur = 1000
#' )
#' 
#' # Afficher les résultats
#' print(resultat$Resultat)
#' }

standardisation_externe<- function(donnees,
                           unite,
                           age_cat,
                           age_cat_mins=NULL, 
                           age_filtre_max=Inf,
                           sexe=NULL, 
                           numerateur, 
                           denominateur,
                           ref_externe_annee=2022,
                           ref_externe_code="99",
                           multiplicateur=1){
  
  
  
  options(dplyr.summarise.inform = FALSE)
  
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#  
  ########### ASSIGNEMENTS DE VARIABLES ###########
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  if(is.null(donnees)){stop("L'argument `donnees` ne peut pas être NULL")}
  
  #assigner les colonnes
  if(is.null(unite)){stop("L'argument `unite` ne peut pas être NULL")
  }else if(!unite %in% colnames(donnees)){stop(paste0("\nLa colonne ",unite," n'est pas retrouvée dans le tableau de données"))
  }else{donnees$unite<-donnees[[unite]]}
  
  
  #groupes d'âges données
  if(is.null(age_cat)){
    stop("L'argument `age_cat` ne peut pas être NULL")
   }else if(!age_cat %in% colnames(donnees)){
     stop(paste0("\nLa colonne ",age_cat," n'est pas retrouvée dans le tableau de données"))
   }else if (is.numeric(donnees[[age_cat]])) {
    # Si "age_cat_mins" n'est pas fourni, renvoyer une erreur
    stop("\nLa variable `age_cat` doit représenter des groupes d'âge, pas un vecteur numérique.")
  }else if (length(unique(donnees[[age_cat]])) > 25) {
    stop("\nLa variable `age_cat` semble être une variable continu d'âge (plus de 25 valeurs) mais en format non-numérique. Veuillez la transformer en numérique, sinon elle sera interpretée comme un variable déjà catégorisée")
  }
  else{donnees$AGE_CAT<-donnees[[age_cat]]}

  if (is.null(age_cat_mins)) stop("\nL'argument `age_cat_mins` ne doit pas être NULL")

  if(length(unique(donnees$AGE_CAT)) != length(age_cat_mins)) {
    stop("\nLe nombre de groupes d'âges de la population d'analyse diffère de celui de la population externe.
                \n\nVérifiez que `age_cat_mins` corresponde bien aux valeurs de la variable `age`.
                \nOu vérifier qu'il y a des cas dans les données pour chaque groupe d'âge de `age_cat_mins` .")
  }

  if( !is.null(age_filtre_max) & max(age_cat_mins)>=age_filtre_max){stop("\nLa valeur de 'age_filtre_max' ne doit pas être plus petite ou égale à la valeur maximale de 'age_cat_mins'.")}

  #sexe
  if(!is.null(sexe)){
    if(!sexe %in% colnames(donnees)){stop(paste0("\nLa colonne ",sexe," n'est pas retrouvée dans le tableau de données"))
      # Vérifier que les valeurs de la variable sexe correspondent aux données externes
    }else if(!identical(sort(unique(donnees$sexe)),
                        sort(unique(pop_ref$sexe)))){
      stop("\nLes valeurs de la variables sexe doivent correspondre à celles du tableau de données externe : c('M','F').")
    }else{donnees$sexe<-donnees[[sexe]]}
  }


  if(is.null(numerateur)){stop("L'argument `numerateur` ne peut pas être NULL")
  }else if(!numerateur %in% colnames(donnees)){stop(paste0("\nLa colonne ",numerateur," n'est pas retrouvée dans le tableau de données"))
  }else{donnees$numerateur<-donnees[[numerateur]]}

  if(is.null(denominateur)){stop("L'argument `denominateur` ne peut pas être NULL")
  }else if(!denominateur %in% colnames(donnees)){stop(paste0("\nLa colonne ",denominateur," n'est pas retrouvée dans le tableau de données"))
  }else{donnees$denominateur<-donnees[[denominateur]]}


  #variables d'analyse et ajustement
  vars<-c("unite", "AGE_CAT", if(!is.null(sexe)) "sexe")


  # Vérifier les conditions pour les populations externes et denom_externe
  if (!ref_externe_code %in%  unique(pop_ref$code)) {
    stop("La valeur de `ref_externe_code` doit être  une valeur présente dans pop_ref$code.\n Par exemple '99' pour l'ensemble du Québec, '06' pour le RSS de Montréal.")
  }

  
  #refus de NA
  if(donnees %>%
     ungroup %>%
     select(all_of(vars),numerateur, denominateur) %>% 
     is.na %>% any){stop("\nLes données ne doivent pas avoir de valeurs NA")}
  
  
  
  #verifier si le nombre de rangées suggère une variable de stratification omise  
  if(nrow(donnees %>% ungroup %>% expand(!!!syms(vars))) < nrow(donnees)){
    stop("\nLe nombre de lignes de 'donnees' est supérieur à ce qui est attendu.Les données fournies ne doivent pas contenir de niveaux autre que  celles résultant de l'agrégation par les strates spécifiées: ",
         paste(capture.output(print(c({{unite}},{{age_cat}},{{sexe}}))),collapse="\n"))
  }
  
  

  # Créer des catégories d'âge pour la population externe
  pop_ref <- pop_ref %>%
    mutate(AGE_CAT = cut(age, c(age_cat_mins, age_filtre_max),
                         right = FALSE) %>% as.character) %>%
    drop_na(AGE_CAT)


  # Correspondance des catégories d'âge entre les données et la population externe
  map_age <- data.frame(age_donnees = unique(donnees$AGE_CAT) %>% sort,
                        age_ext = unique(pop_ref$AGE_CAT) %>% sort)

  # Mettre à jour les catégories d'âge de la population externe en fonction des données
  pop_ref <- pop_ref %>% inner_join(map_age, by = c("AGE_CAT" = "age_ext")) %>%
    suppressMessages() %>%
    mutate(AGE_CAT = age_donnees) %>%
    select(-age_donnees)

  # Avertir l'utilisateur que les groupes d'âge sont supposés équivalents et dans le même ordre
  warning("\nLes groupes d'âge de la population d'analyse sont assumés comme étant équivalents et dans la même ordre que ceux de la population externe de référence.\nSinon, veuillez modifier les valeurs de vos groupes d'âge\n\n",
          paste(capture.output(print(data.frame(`Âge données` = unique(donnees$AGE_CAT) %>% sort,
                                                `Âge externe` = unique(map_age$age_ext) %>% sort))), collapse = "\n"), "\n")




  #-----------------------------------------------#
  #-----------------------------------------------#
  ################# TAUX BRUTS ####################
  #-----------------------------------------------#
  #-----------------------------------------------#

  # Enlever les lignes avec une valeur manquante pour la variable portant sur les régions.
  ind_group<-donnees %>%
    ungroup %>%
    select(all_of(vars),numerateur, denominateur) 


  #
  #-----------------------------------------------#
  #-----------------------------------------------#
  ############### TAUX REFERENCE  #################
  #-----------------------------------------------#
  #-----------------------------------------------#


  # #Agrégation de la population de référence
  ind_ref <-
    # Pour la méthode directe, on a seulement besoin du dénominateur de référence
    pop_ref %>%
    filter(annee %in% ref_externe_annee,
           code %in% ref_externe_code) %>%
    # Grouper les données en fonction des variables (à l'exception de l'unité)
    group_by(across(all_of(vars[-1]))) %>%
    # Calculer le dénominateur de référence
    summarize(denom_ref = sum(pop))


  #-----------------------------------------------#
  #-----------------------------------------------#
  ########  REJOINDRE BRUT ET REFERENCE ###########
  #-----------------------------------------------#
  #-----------------------------------------------#

  # #Join  avec référence
  n_ind<-ind_group %>%
    inner_join(ind_ref) %>%
    group_by(unite) %>%
    suppressMessages()

  # Vérifier si le dénominateur est égal à zéro pour une ou plusieurs strates
  if (any(n_ind$denominateur==0)) {
    stop("\nUne ou plusieurs strates n'ont pas de population (dénominateur manquant). Veuillez modifier le découpage de groupes d'âges ou le choix de variables.", "\n\n",
         paste(capture.output(print(as.data.frame(n_ind[n_ind$denominateur==0,]))),collapse="\n"),"\n")
  }



  # # #-----------------------------------------------#
  # # #-----------------------------------------------#
  # # ##############  STANDARDISATION #################
  # # #-----------------------------------------------#
  # # #-----------------------------------------------#


  #Effectuer la standardisation directe.
  resultats_std<-phe_dsr(data = n_ind, x = numerateur,
                         n = denominateur, stdpop = denom_ref,type="standard",
                         stdpoptype = "field", multiplier = multiplicateur)
  # Renommer les colonnes et calculer la valeur brute
  result<-resultats_std %>%
    rename(n=total_count, pop=total_pop, valeur_ajustee=value,IC_bas=lowercl, IC_haut=uppercl) %>%
    mutate(valeur_brute=multiplicateur*(n/pop),.before=valeur_ajustee)

  colnames(result)[1]<-{{unite}}

  # Avertir si le nombre d'observations est inférieur à 10 pour certaines unités
  if(any(result$n<10)) warning("\nLe taux ajusté n'est pas calculé pour les unités ayant < 10 observations")

  #Réassigner les noms de colonnes originaux
  colnames(n_ind)[1]<-{{unite}}
  colnames(n_ind)[2]<-{{age_cat}}
  if(!is.null(sexe))colnames(n_ind)[3]<-{{sexe}}
  

  #Sortie de résultats d'ajustement et tableau des données agrégés
  list("Resultat"=result,
       "Details"=n_ind )

}





