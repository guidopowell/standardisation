#' @title Standardisation interne
#'
#' @description   Cette fonction applique une standardisation interne à des données agrégées. 
#' Dans le processus de standardisation, elle utilise soit la somme des données d'entrée comme population de référence
#' ou une unité spécifiée par `reference_unite`. La fonction ajuste pour des facteurs tels que le groupe d'âge, le sexe, et d'autres variables fournies
#' Les intervalles de confiance sont issues du package `PHEIndicatormethods`.
#' La standardisation interne peut-être directe ou indirecte. 
#' 
#'
#' @param donnees Un dataframe contenant les données. Les valeurs NA ne sont pas permises.
#' @param unite Une chaîne indiquant l'unité d'analyse.
#' @param age_cat Une chaîne indiquant la catégorie d'âge.
#' @param sexe Un champ dans le dataframe qui indique le sexe de chaque individu. Les valeurs de cette variable doivent être "M" et "F". Facultatif.
#' @param autres_vars Un vecteur optionnel d'autres variable(s) pour la stratification. Facultatif.
#' @param numerateur Un champ dans le dataframe qui représente le numérateur de la mesure de taux.
#' @param denominateur Un champ dans le dataframe qui représente le dénominateur de la mesure de taux.
#' @param reference_unite Une chaîne optionnelle indiquant l'unité de référence, NULL par défaut.
#' @param methode Une chaîne indiquant la méthode de standardisation ("directe" par défaut, ou "indirecte").
#' @param multiplicateur Un nombre par lequel les taux standardisés sont multipliés (par exemple, 1000 pour obtenir des taux pour 1000 personnes).
#'
#' @return Une liste avec deux éléments, "Resultat" et "Details". "Resultat" contient les résultats de 
#'         la standardisation, et "Details" contient le tableau de données agrégées.
#' @keywords internal
#' @encoding UTF-8
#' @import tidyverse PHEindicatormethods rlang
#' @export
#'
#' @examples
#' \dontrun{
#' # Exemple d'utilisation de la fonction standardisation_interne
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
#' # Utiliser la fonction standardisation_interne
#' resultat <- standardisation_interne(
#'   donnees = donnees,
#'   unite = "region",
#'   age_cat = "groupe_age",
#'   numerateur = "numerateur",
#'   denominateur = "denominateur",
#'   methode = "indirecte",
#'   multiplicateur = 1000
#' )
#' 
#' # Afficher les résultats
#' print(resultat$Resultat)
#' }
#' 

standardisation_interne<- function(donnees,
                                    unite=NULL,
                                    age_cat=NULL,
                                    sexe=NULL, 
                                    autres_vars=NULL,
                                    numerateur=NULL, 
                                    denominateur=NULL,
                                    reference_unite=NULL,
                                    methode="directe",
                                    multiplicateur=1){
  
  
  
  options(dplyr.summarise.inform = FALSE,
          scipen=999)
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#  
  ########### ASSIGNEMENTS DE VARIABLES ###########
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  if(is.null(donnees)){stop("L'argument `donnees` ne peut pas être NULL")}
  
  #unité
  if("agregation" %in% class(donnees) & is.null(unite)){
    unite<-donnees$unite
    donnees$df<-donnees$df %>% rename(unite=unite)
  }else if(is.null(unite)){stop("L'argument `unite` ne peut pas être NULL")
  }else if(!unite %in% colnames(donnees)){stop(paste0("\nLa colonne ",unite," n'est pas retrouvée dans le tableau de données"))
  }else{donnees<-donnees %>% rename(unite=unite)}
  
  #groupes d'âges données
  if("agregation" %in% class(donnees) & is.null(age_cat)){
    age_cat<-"AGE_CAT"
  }else if(is.null(age_cat)){stop("L'argument `age_cat` ne peut pas être NULL")
  }else if(!age_cat %in% colnames(donnees)){stop(paste0("\nLa colonne ",age_cat," n'est pas retrouvée dans le tableau de données"))
  }else if (is.numeric(donnees[[age_cat]])) {
    stop("\nLa variable `age_cat` doit représenter des groupes d'âge, pas un vecteur numérique.")
  }else if (length(unique(donnees[[age_cat]])) > 25) {
    stop("\nLa variable `age_cat` semble être une variable continu d'âge (plus de 25 valeurs) mais en format non-numérique. Veuillez la transformer en numérique, sinon elle sera interpretée comme un variable déjà catégorisée")
  }else{donnees<-donnees %>% rename(AGE_CAT=age_cat)}
  
  #sexe
  if("agregation" %in% class(donnees) & is.null(sexe)){
    sexe<-donnees$sexe
    if(!is.null(sexe)){
      donnees$df<-donnees$df %>% rename(sexe=sexe)
    }
  }else if(!is.null(sexe)){
    if(!sexe %in% colnames(donnees)){stop(paste0("\nLa colonne ",sexe," n'est pas retrouvée dans le tableau de données"))
    }else{donnees<-donnees %>% rename(sexe=sexe)}
  }
  
  #numerateur
  if("agregation" %in% class(donnees) & is.null(numerateur)){
    numerateur<-"num"
    donnees$df<-donnees$df %>% rename(numerateur=numerateur)
  }else if(is.null(numerateur)){stop("L'argument `numerateur` ne peut pas être NULL")
  }else if(!numerateur %in% colnames(donnees)){stop(paste0("\nLa colonne ",numerateur," n'est pas retrouvée dans le tableau de données"))
  }else{donnees<-donnees %>% rename(numerateur=numerateur)}
  
  #denominateur
  if("agregation" %in% class(donnees) & is.null(denominateur)){
    denominateur<-"denom"
    donnees$df<-donnees$df %>% rename(denominateur=denominateur)
  }else if(is.null(denominateur)){stop("L'argument `denominateur` ne peut pas être NULL")
  }else if(!denominateur %in% colnames(donnees)){stop(paste0("\nLa colonne ",denominateur," n'est pas retrouvée dans le tableau de données"))
  }else{donnees<-donnees %>% rename(denominateur=denominateur)}
  
  #autres vars
  if("agregation" %in% class(donnees) & is.null(autres_vars)){
    autres_vars<-donnees$autres_vars
  }else if(!is.null(autres_vars)){
    if(any(!autres_vars %in% colnames(donnees))){
      stop("\nUne ou plusieurs variables (",paste(autres_vars,collapse=", "),") ne sont pas retrouvées dans le tableau de données:\n",
           print(paste(autres_vars[!autres_vars %in% colnames(donnees)],collapse=", ")))
    }}
  
  # Si reference_unite est spécifié, vérifier que la valeur existe dans les données
  
  if(!is.null(reference_unite)){
    if("agregation" %in% class(donnees)){
      if(!reference_unite %in% donnees$df$unite){stop("\nLa valeur précisée pour reference_unite n'existe pas dans les données.")
      }
    }else if(!reference_unite %in% donnees$unite){stop("\nLa valeur précisée pour reference_unite n'existe pas dans les données.")
    }
  }
  
  if("agregation" %in% class(donnees)){
    donnees<-donnees$df
  }
  
  
  #variables d'analyse et ajustement
  vars<-c("unite", "AGE_CAT", if(!is.null(sexe)) "sexe", autres_vars)
  
  
  
  
  
  #refus de NA
  if(donnees %>%
     ungroup %>%
     select(all_of(vars),numerateur, denominateur) %>%
     is.na %>% any){stop("\nLes données ne doivent pas avoir de valeurs NA")}
  
  
  #verifier si le nombre de rangées suggère une variable de stratification omise
  if(nrow(donnees %>%droplevels %>%  ungroup %>% expand(!!!syms(vars))) < nrow(donnees)){
    stop("\nLe nombre de lignes de 'donnees' est supérieur à ce qui est attendu.Les données fournies ne doivent pas contenir de niveaux autre que  celles résultant de l'agrégation par les strates spécifiées: ",
         paste(capture.output(print(c({{unite}},{{age_cat}},{{sexe}},{{autres_vars}}))),collapse="\n"))
  }
  
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ################# TAUX BRUTS ####################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  
  #Pour chaque région, faire le compte des personnes dans chaque tranche de groupe d'âge/sexe
  #et calculer le nombre d'événements.
  ind_group<-donnees %>%
    ungroup %>%
    select(all_of(vars),numerateur, denominateur)
  
  
  verif_n<-ind_group %>% droplevels %>% ungroup %>% expand(!!!syms(vars)) %>% anti_join(ind_group) %>%   suppressMessages() %>%as.data.frame()
  
  if(nrow(verif_n)!=0) stop("\nStrate(s) d'agrégation manquante(s). Veuillez inclure une valeur de 0 comme numérateur pour les strates qui n'ont pas d'événements \n\n",
                            paste(capture.output(print(verif_n)),collapse="\n"),"\n")
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ############### TAUX REFERENCE  #################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  
  # #Agrégation de la population de référence
  # Si la méthode est "indirecte", on calcule le numérateur et le dénominateur de référence
  ind_ref <- if (methode == "indirecte") {
    ind_group %>%
      # Filtrer les données en fonction de la valeur de 'reference_unite', si elle est spécifiée
      filter(if (!is.null(reference_unite)) unite == reference_unite else TRUE) %>%
      # Grouper les données en fonction des variables (à l'exception de l'unité)
      group_by(across(all_of(vars[-1]))) %>%
      # Calculer le numérateur et le dénominateur de référence
      summarize(num_ref =  sum(numerateur),
                denom_ref = sum(denominateur))
  } else {
    # Pour la méthode directe, on a seulement besoin du dénominateur de référence
    ind_group %>%
      # Filtrer les données en fonction de la valeur de 'reference_unite', si elle est spécifiée
      filter(if (!is.null(reference_unite)) unite == reference_unite else TRUE) %>%
      # Grouper les données en fonction des variables (à l'exception de l'unité)
      group_by(across(all_of(vars[-1]))) %>%
      # Calculer le dénominateur de référence
      summarize(denom_ref =sum(denominateur))
  }
  
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
         paste(capture.output(print(as.data.frame(n_ind[n_ind$denom==0,]))),collapse="\n"),"\n")
  }
  
  
  
  # # #-----------------------------------------------#
  # # #-----------------------------------------------#
  # # ##############  STANDARDISATION #################
  # # #-----------------------------------------------#
  # # #-----------------------------------------------#
  
  if(methode=="directe"){
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
    if(any(result$n<10)) warning("\nLe taux ajusté n'est pas calculé pour les unités ayant < 10 observations. Il pourrait être calculé avec la standardisation indirecte.")
    
  }else{
    #Effectuer la standardisation directe.
    if(methode=="indirecte"){
      
      resultats_sti<- calculate_ISRatio(data = n_ind,x =  numerateur,n= denominateur,x_ref =  num_ref,n_ref =  denom_ref, refpoptype = "field",type = "standard")
      # Renommer les colonnes
      result<-resultats_sti %>%
        rename( obs=observed, exp=expected,ratio=value,IC_bas=lowercl, IC_haut=uppercl)
      
      #ajouter les ratios brutes
      ratio_brut_df<-n_ind %>% 
        group_by(unite) %>% 
        summarize(Taux=sum(numerateur)/sum(denominateur)) %>% 
        data.frame(n_ind %>% 
                     ungroup %>% 
                     summarize(Taux_sum=sum(numerateur)/sum(denominateur))) %>% 
        mutate(ratio_brut=Taux/Taux_sum) %>% 
        select(unite,ratio_brut)
      
      result<-result %>% left_join(ratio_brut_df) %>% 
        relocate(ratio_brut,.before=ratio)
      
      
      colnames(result)[1]<-{{unite}}
    }}
  
  
  # #Réassigner les noms de colonnes originaux
  colnames(n_ind)[1]<-{{unite}}
  colnames(n_ind)[2]<-{{age_cat}}
  if(!is.null(sexe))colnames(n_ind)[3]<-{{sexe}}
  
  
  #Sortie de résultats d'ajustement et tableau des données agrégés
  output_list<-list("Resultat"=result,
                    "Details"=n_ind ,
                    "methode"=methode,
                    "multiplicateur"=multiplicateur,
                    "unite"=unite)
  
  
  class(output_list)<-c("list","standardisation_list")
  output_list
}
