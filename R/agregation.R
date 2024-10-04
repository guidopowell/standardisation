#' @title Agregation
#'
#' @description  `agregation` est une fonction qui permet de transformer des données individuelles ou partiellement agrégées en un format adapté pour les fonctions de standardisation\cr
#'
#' @param donnees Un dataframe contenant les données à agréger. Les valeurs NA ne sont pas permises.
#' @param age Un champ dans le dataframe qui indique l'âge du patient en format continu à regrouper par `age_cat_mins`.
#' @param age_cat_mins Un vecteur contenant les âges minimaux de chaque groupe d'âge pour le regroupement de `age` et/ou de la variable d'âge du tableau externe de dénominateur.
#' @param age_filtre_max  Une valeur numérique indiquant le filtre d'âge maximum exclusif, Inf par défaut.
#' @param sexe  Un champ dans le dataframe qui indique le sexe de chaque individu. Les valeurs de cette variable doivent être "M" et "F". Facultatif.
#' @param autres_vars Un vecteur optionnel d'autres variable(s) pour la stratification. Facultatif.

#' @param type_num Une chaîne de caractères indiquant le type de numérateur. Il peut être 'filtré' si les cas sont identifiés par une exression logique (`num_filtre_expression`), 'total_interne' si la somme de rangées représente les cas, ou 'colonne agrégée' si un champ de `donnees`indique les numérateurs agrégées.
#' @param type_denom Une chaîne de caractères indiquant le type de dénominateur. Il peut être 'total interne' si la somme de rangées représente les dénominateurs, 'externe' si des dénominateurs externes sont utilisés, ou 'colonne agrégée' si un champ de `donnees`indique les dénominateurs agrégées.

#' @param num_filtre_expression Une chaîne de caractères représentant une expression conditionnelle utilisée pour filtrer les données. Cette expression est utilisée lorsque `type_num` est 'filtré'.

#' @param numerateur_agr_col Une colonne facultative dans le dataframe `donnees` qui contient des numérateurs agrégés. Ceci n'est utilisé que lorsque `type_num` est 'colonne agrégée'.
#' @param denominateur_agr_col Une colonne facultative dans le dataframe `donnees` qui contient des dénominateurs agrégés. Ceci n'est utilisé que lorsque `type_denom` est 'colonne agrégée'.
#'
#' @param denom_externe_type_unite Une chaîne de caractères facultative indiquant le type d'unité pour le dénominateur externe. Il peut être 'Régional' ou 'Annuel'.
#' @param denom_externe_geo Si `denom_externe_type_unite` = 'Régional', une chaîne de caractères facultative indiquant le niveau géographique pour le dénominateur externe. Il peut être 'RSS', 'RLS', ou 'RTS'.
#' @param denom_externe_annee Si `denom_externe_type_unite` = 'Régional', un valeur indiquant l'année pour le dénominateur externe. 
#' @param denom_externe_regroupement_unite Une liste facultative contenant des correspondances de nouveaux noms de groupe à des noms d'unité originaux pour le dénominateur externe. Ceci est utilisé pour effectuer une correspondance entre les regroupement d'unités de `donnees` et du dataframe pop_ref.
#' 
#' @return Un dataframe incluant une colonne pour les unités d'analyse (par exemple les régions ou les années), les variables agrégées (age, sexe, autres), le numérateur et le dénominateur. Le regroupement de la variable d'âge sort toujours avec le nom AGE_CAT
#' 
#' @keywords internal
#' @encoding UTF-8
#' @import tidyverse PHEindicatormethods rlang
#' @export
#' @examples
#' \dontrun{
#'
#'data_n<-agregation(donnees = donnees_sim %>% filter(annee=="2022"),
#'           unite = "rss",
#'           age = "age",
#'           age_cat_mins = c(0,50, 60,70),
#'           sexe = "sexe",
#'           type_num = "filtré",
#'           num_filtre_expression = "deces == 'Oui'",
#'           type_denom = 'total interne')
#'           
#'glimpse(data_n) 
#'}
#'
agregation<- function(donnees,
                      unite,
                      
                      age,
                      age_cat_mins=NULL, 
                      age_filtre_max=Inf,
                      sexe=NULL, 
                      autres_vars=NULL,
                      
                      type_num,
                      type_denom,
                      
                      num_filtre_expression=NULL,
                      
                      numerateur_agr_col=NULL, 
                      denominateur_agr_col=NULL,
                      
                      denom_externe_type_unite= NULL,
                      denom_externe_annee=NULL,
                      denom_externe_geo=NULL,
                      denom_externe_regroupement_unite=NULL){
  
  
  
  options(dplyr.summarise.inform = FALSE)
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#  
  ################ PREP DONNEES ###################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  
  if(is.null(donnees)){stop("L'argument `donnees` ne peut pas être NULL")}
  
  #assigner les colonnes
  if(is.null(unite)){stop("L'argument `unite` ne peut pas être NULL")
  }else if(!unite %in% colnames(donnees)){stop(paste0("\nLa colonne ",unite," n'est pas retrouvée dans le tableau de données"))
  }else if(any(is.na(donnees[[unite]]))){stop(paste0("\nLa colonne ",unite," ne doit pas contenir de valeurs NA."))
  }else{donnees$unite<-donnees[[unite]]}
  
  if(is.null(age)){stop("L'argument `age` ne peut pas être NULL")
  }else if(!age %in% colnames(donnees)){stop(paste0("\nLa colonne ",age," n'est pas retrouvée dans le tableau de données"))
  }else if(any(is.na(donnees[[age]]))){stop(paste0("\nLa colonne ",age," ne doit pas contenir de valeurs NA."))
  }else{donnees$age<-donnees[[age]]}
  
  if(!is.null(age_cat_mins)) {
    if(!is.null(age_filtre_max)){
      if( max(age_cat_mins)>=age_filtre_max){stop("\nLa valeur de 'age_filtre_max' ne doit pas être plus petite ou égale à la valeur maximale de 'age_cat_mins'.")}
    }
  }
  
  if(!is.null(sexe)){
    if(!sexe %in% colnames(donnees)){stop(paste0("\nLa colonne ",sexe," n'est pas retrouvée dans le tableau de données"))
    }else if(any(is.na(donnees[[sexe]]))){stop(paste0("\nLa colonne ",sexe," ne doit pas contenir de valeurs NA."))
    }else{donnees$sexe<-donnees[[sexe]]}
  }
  
  if(is.null(type_num) || !type_num %in% c("colonne agrégée", "filtré","total interne")){stop("\nLes valeurs permises pour `type_num`  sont c('colonne agrégée', 'filtré', 'total interne)")}
  
  if(is.null(type_denom) || !type_denom %in% c("colonne agrégée", "externe","total interne")){stop("\nLes valeurs permises pour `type_denom`  sont c('colonne agrégée', 'externe', 'total interne')")}
  
  if(type_num=="colonne agrégée"){ 
    if(is.null(numerateur_agr_col)){stop("\nUne valeur doit être spécifiée pour `numerateur_agr_col` lorsque `type_num` = 'colonne agrégée'.")}
    if(type_denom=="total interne"){stop("\nLe `type_denom` ne peut pas être 'total_interne' lorsque `type_num` = 'colonne agrégée'")}
  }
  
  if(!is.null(numerateur_agr_col)){
    if(type_num!="colonne agrégée"){stop("\nVous ne pouvez pas spécifier une valeur pour 'numerateur_agr_col' si le type `type_num` n'est pas 'colonne agrégée' ." )}
    if(!numerateur_agr_col %in% colnames(donnees)){stop(paste0("\nLa colonne ",numerateur_agr_col," n'est pas retrouvée dans le tableau de données"))
    }else if(any(is.na(donnees[[numerateur_agr_col]]))){stop(paste0("\nLa colonne ",numerateur_agr_col," ne doit pas contenir de valeurs NA."))
    }else{donnees$numerateur_agr_col<-donnees[[numerateur_agr_col]]}
  } 
  
  
  if(type_num=="total interne" & type_denom!="externe"){
    stop("\nLorsque `type_num` = 'total interne' le `type_denom` doit être 'externe' ")
  }  
  
  if(type_num=="filtré"){
    if(type_denom == "colonne agrégée"){stop("nLorsque `type_num` = 'filtré' l'argument `type_denom` ne peut pas être 'colonne agrégée'")}
    if(is.null(num_filtre_expression)){stop("\nLorsque `type_num` = 'filtré' l'argument `num_filtre_expression` ne doit pas être NULL.")}
    
    tryCatch({
      donnees_filtre <- donnees %>% filter(eval(parse(text = num_filtre_expression)))
      
      if (is.data.frame(donnees_filtre) && nrow(donnees_filtre) == 0) {
        stop("L'expression 'num_filtre_expression' a donné lieu à un tableau vide . Veuillez vérifier vos critères de filtrage.")
      }
    }, error = function(e) {
      stop("L'expresion num_filtre_expression' a produit une erreur. Assurez d'avoir bien précisé une colonne dans les données, qu'elle est évaluée par un opérateur logique valide, et que la valeur est entourée d'apostrophes (' ') si elle est un caractère  . \n\nPar exemple,\n \"deces == 'Oui'\" ; \n \"n_Médicament  > 0\" ;\n \"HOSPIT %in% c('admis','transfer')\" ; \n \"naissance == TRUE & poids_lbs < 5\"   ")
    })
    
    # #aucune valeur NA
    # evaluated_expression <- with(donnees, eval(parse(text = num_filtre_expression)))
    # 
    # if(any(is.na(evaluated_expression))) {
    #   stop("Les variables précisées dans `num_filtre_expression` ne doivent pas contenir de valeurs NA.")
    # }
  }
  
  if(!is.null(num_filtre_expression) & type_num != "filtré"){stop("\nL'argument `num_filtre_expression` doit seulemet être spécifié lorsque `type_num` = 'filtré'")}
  
  if(type_denom == "colonne agrégée"){
    if(is.null(denominateur_agr_col)){stop("\nUne valeur doit être spécifiée pour `denominateur_agr_col` lorsque `type_denom` = 'colonne agrégée'.")}
    if(type_num!="colonne agrégée"){stop("\nLorsque `type_denom` = 'colonne agrégée' l'argument `type_num`doit aussi être 'colonne agrégée' ")}
  }
  
  if(!is.null(denominateur_agr_col)){
    if(type_denom != "colonne agrégée"){stop("\nVous ne pouvez pas spécifier une valeur pour 'denominateur_agr_col' si le type `type_denom` n'est pas 'colonne agrégée' .")}
    if(!denominateur_agr_col %in% colnames(donnees)){stop(paste0("\nLa colonne ",denominateur_agr_col," n'est pas retrouvée dans le tableau de données"))
    }else if(any(is.na(donnees[[denominateur_agr_col]]))){stop(paste0("\nLa colonne ",denominateur_agr_col," ne doit pas contenir de valeurs NA."))
    }else{donnees$denominateur_agr_col<-donnees[[denominateur_agr_col]]}
  }
  
  if(type_denom != "externe" & any(!is.null(c(denom_externe_annee,
                                              denom_externe_geo,
                                              denom_externe_type_unite,
                                              denom_externe_regroupement_unite)))){
    stop("\nLes arguments spécifique au dénominateur externe (`denom_externe_annee`,`denom_externe_geo`,`denom_externe_type_unite`,`denom_externe_regroupement_unite`) doivent être NULL si `type_denom` n'est pas 'externe'")
  }
  
  if(type_denom=="total interne" & type_num!="filtré"){
    stop("\nLorsque `type_denom` = 'total interne' le `type_num` doit être 'filtré' ")
  }  
  
  
  if(!is.null(autres_vars)){
    if(any(!autres_vars %in% colnames(donnees))){
      stop("\nUne ou plusieurs variables (",paste(autres_vars,collapse=", "),") ne sont pas retrouvées dans le tableau de données:\n",
           print(paste(autres_vars[!autres_vars %in% colnames(donnees)],collapse=", ")))
    }}
  
  
  #variables d'analyse et ajustement
  vars<-c("unite", "AGE_CAT", if(!is.null(sexe)) "sexe", autres_vars)
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ################ VERIFICATIONS ##################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  
  # Vérifier les conditions lorsque type_denom == "externe" est TRUE
  if (type_denom == "externe") {
    
    
    if(is.null(denom_externe_type_unite) || !denom_externe_type_unite %in% c("Régional", "Annuel")){stop("\nL'argument 'denom_externe_type_unite' doit avoir comme valeur 'Régional' ou 'Annuel' ")}
    
    
    # Si denom_externe_type_unite est "Régional", vérifier les conditions pour type_denom == "externe"_annee et les codes d'unité
    if (denom_externe_type_unite == "Régional") {
      
      if(is.null(denom_externe_geo)){stop("\nL'argument `denom_externe_geo`ne peut pas être NULL is `type_denom` est 'externe' et `denom_externe_type_unite` est 'Régional'")}
      
      # Vérifier que denom_externe_annee n'est pas NULL
      if (is.null(denom_externe_annee)) stop("\nVeuillez choisir une année pour la population de dénominateurs des régions ('denom_externe_annee' ne peut pas être NULL) ")
      
      # Vérifier que la variable unite est de format caractère
      if (!is.character(donnees$unite)) {stop("\nLa variable unite doit être de format caractère afin d'apparier avec les codes de régions du fichier de population de dénominateur (ex: codes RSS '01','02',etc.)")}
      
      # Vérifier les codes d'unité en fonction du regroupement géographique
      if (is.null(denom_externe_regroupement_unite)) {
        
        # Vérifier les codes RSS
        if (denom_externe_geo == "RSS" & (any(nchar(donnees$unite) != 2) |
                                          !all(donnees$unite %in% pop_ref$code[pop_ref$geo == "RSS"]))) {
          stop("\nLes codes RSS doivent être un caractère de 2 chiffres dont un '0' pour les codes < '10', exemples '06','16', etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
        
        # Vérifier les codes RLS
        if (denom_externe_geo == "RLS" & (any(nchar(donnees$unite) != 4) |
                                          !all(donnees$unite %in% pop_ref$code[pop_ref$geo == "RLS"]))) {
          stop("\nLes codes RLS doivent être un caractère de 4 chiffres dont un '0' pour les codes < '1000', exemples '0111', '0815', '1112' etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
        
        # Vérifier les codes RTS
        if (denom_externe_geo == "RTS" & (any(nchar(donnees$unite) != 3) |
                                          !all(donnees$unite %in% pop_ref$code[pop_ref$geo == "RTS"]))) {
          stop("\nLes codes RTS doivent être un caractère de 3 chiffres dont un '0' pour les codes < '100', exemples '021', '065', '161' etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
        
      }
    } else if (denom_externe_type_unite == "Annuel") {
      # Avertir que denom_externe_annee est ignoré si denom_externe_type_unite est "Annuel"
      if (!is.null(denom_externe_annee)) {warning("\nLa valeur de 'denom_externe_annee' est ignorée lorsque 'denom_externe_type_unite' = 'Annuel'")}
      if (!is.null(denom_externe_geo)) {warning("\nLa valeur de 'denom_externe_geo' est ignorée lorsque 'denom_externe_type_unite' = 'Annuel'. Les populations annuelles pour l'ensemble du Québec servent comme dénominateurs avec cette configuration.")}
      if(is.null(denom_externe_regroupement_unite)){
        if(any(nchar(donnees$unite) != 4)|
           !all(donnees$unite %in% pop_ref$annee)){
          stop("\nLes valeurs d'années doivent être de format quatre chiffres, exemples '2023'. Consultez annees dans le tableau pop_ref pour connaître les valeurs admissibles.")
          
        }
      }
    }
    # Vérifier que les valeurs de la variable sexe correspondent aux données externes
    if (!is.null(sexe)) {
      if (!identical(sort(unique(donnees$sexe)),
                     sort(unique(pop_ref$sexe))))stop("\nLes valeurs de la variables sexe doivent correspondre à celles du tableau de données externe : c('M','F').")
    }
    # Vérifier que l'argument autres_vars est NULL lorsqu'une population externe est utilisée
    if (!is.null(autres_vars)) stop("\nL'agrégation avec une population externe comme dénominateur ( `type_denom` == 'externe') peut seulement ajuster pour l'âge et le sexe. L'argument autres_vars doit être NULL ")
    
  }
  
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ################ GROUPES D'ÂGES #################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  #créer les groupes d'âges si pas déjà catégorisé
  
  # Vérifier si la variable "age" est numérique
  if (is.numeric(donnees$age)) {
    # Si "age_cat_mins" n'est pas fourni, renvoyer une erreur
    if (is.null(age_cat_mins)) {
      stop("\nL'argument `age_cat_mins` ne doit pas être NULL lorsque `age` est une variable en format numérique (continu, non-regroupée)")
    } else {
      # Créer des catégories d'âge pour les données fournies
      donnees <- donnees %>% mutate(AGE_CAT = cut(age, c(age_cat_mins, age_filtre_max),
                                                  right = FALSE) %>% as.character) %>%
        drop_na(AGE_CAT)
      
      # Si une population externe est utilisée, ajuster les groupes d'âge de la population externe
      if ( type_denom == "externe") {
        if (length(unique(donnees$AGE_CAT)) != length(age_cat_mins)) {
          stop("\nLe nombre de groupes d'âges de la population d'analyse diffère de celui de la population externe.
                \n\nSi la variable `age` est déjà catégorisée, vérifiez que `age_cat_mins` corresponde bien aux valeurs de la variable `age`.
                \nSinon, vérifier qu'il y a des cas dans les données pour chaque groupe d'âge de `age_cat_mins` .")
        }
        
        # Créer des catégories d'âge pour la population externe
        pop_ref <- pop_ref %>%
          mutate(AGE_CAT = cut(age, c(age_cat_mins, age_filtre_max),
                               right = FALSE) %>% as.character) %>%
          drop_na(AGE_CAT)
      }
    }
  } else {
    # Si la variable "age" n'est pas numérique, vérifier si elle est déjà catégorisée
    if (length(unique(donnees$age)) > 25) {
      stop("\nLa variable `age` semble être une variable continu d'âge (plus de 25 valeurs) mais en format non-numérique. Veuillez la transformer en numérique, sinon elle sera interpretée comme un variable déjà catégorisée")
    }
    
    # Utiliser la variable "age" comme catégorie d'âge
    donnees <- donnees %>%
      mutate(AGE_CAT = age)
    
    # Si une population externe est utilisée et "age_cat_mins" est fourni, ajuster les groupes d'âge
    if ( type_denom == "externe") {
      
      if (is.null(age_cat_mins)) stop("\nL'argument `age_cat_mins` ne doit pas être NULL lorsque `type_denom` = 'externe' ou `denom_externe` = T")
      
      if (length(unique(donnees$AGE_CAT)) != length(age_cat_mins)) {
        stop("\nLe nombre de groupes d'âges de la population d'analyse diffère de celui de la population externe.
              \n\nSi la variable `age` est déjà catégorisée, vérifiez que `age_cat_mins` corresponde bien aux valeurs de la variable `age`.
              \nSinon, vérifier qu'il y a des cas dans les données pour chaque groupe d'âge de `age_cat_mins` .")}
      
      # Créer des catégories d'âge pour la population externe
      pop_ref <- pop_ref %>%
        mutate(AGE_CAT = cut(age, c(age_cat_mins, age_filtre_max),
                             right = FALSE) %>% as.character) %>%
        drop_na(AGE_CAT)
      
      # Mapper les catégories d'âge entre les données et la population externe
      map_age <- data.frame(age_donnees = unique(donnees$AGE_CAT) %>% sort,
                            age_ext = unique(pop_ref$AGE_CAT) %>% sort)
      
      # Mettre à jour les catégories d'âge de la population externe en fonction des données
      pop_ref <- pop_ref %>% inner_join(map_age, by = c("AGE_CAT" = "age_ext")) %>%
        suppressMessages() %>% 
        mutate(AGE_CAT = age_donnees) %>%
        select(-age_donnees)
      
      # Avertir l'utilisateur que les groupes d'âge sont supposés équivalents et dans le même ordre
      warning("\nLes groupes d'âge de la population d'analyse sont assumés comme étant équivalents et dans la même ordre que ceux de la population externe du dénominateur.\nSinon, veuillez modifier les valeurs de vos groupes d'âge\n\n",
              paste(capture.output(print(data.frame(`Âge données` = unique(donnees$AGE_CAT) %>% sort,
                                                    `Âge externe` = unique(map_age$age_ext) %>% sort))), collapse = "\n"), "\n")
      
    } else if (!is.null(age_cat_mins)) {
      # Si "age_cat_mins" est fourni, mais les données ne sont pas numériques, avertir l'utilisateur
      warning("\nLe paramètre age_cat_mins est ignoré (age est déjà non-numérique)")
    }}
  
  
  
  
  # Enlever les lignes avec une valeur manquante pour la variable portant sur les régions.
  donnees <- drop_na(donnees, any_of(vars))
  
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ################ DENOMINATEURS ##################
  #-----------------------------------------------#
  #-----------------------------------------------#
  
  # Si les dénominateurs externes sont utilisés
  if (type_denom == "externe") {
    
    # Filtrer et renommer les colonnes de la population de référence pour correspondre aux unités choisies
    denom_pop <- pop_ref %>%
      filter(if (denom_externe_type_unite == "Régional") geo == denom_externe_geo else TRUE,
             if (denom_externe_type_unite == "Régional") annee %in% denom_externe_annee else TRUE) %>%
      rename(unite = ifelse(denom_externe_type_unite == "Régional", "code", "annee"))
    
    # Si un regroupement d'unités est spécifié
    if (!is.null(denom_externe_regroupement_unite)) {
      
      # Créer un dataframe pour mapper les unités regroupées
      regroupement_df <- data.frame(unite_gr = rep(names(denom_externe_regroupement_unite),
                                                   sapply(denom_externe_regroupement_unite, length)),
                                    unite = unlist(denom_externe_regroupement_unite), row.names = NULL)
      
      # Vérifier si les noms de regroupement d'unités correspondent aux données
      if (any(!regroupement_df$unite_gr %in% donnees$unite)) {
        stop("\nUn ou plusieurs noms de regroupement d'unités ne sont pas retrouvés dans la tableau de données:\n\n", print(paste(unique(regroupement_df$unite_gr[!regroupement_df$unite_gr %in% donnees$unite]),collapse = ", ")))
      }
      
      # Vérifier si certaines unités à regrouper ne se trouvent pas dans les données externe
      if (any(!regroupement_df$unite %in% denom_pop$unite)) {
        stop("\nUne ou plusieurs unités à regrouper ne se trouvent pas dans les fichier de population externe:\n\n", print(paste(unique(regroupement_df$unite[!regroupement_df$unite %in% denom_pop$unite]),collapse = ", ")))
      }
      
      # Fusionner les données de regroupement avec les données de la population de dénominateur
      denom_pop <- denom_pop %>% left_join(regroupement_df) %>%
        suppressMessages() %>%
        mutate(unite = case_when(!is.na(unite_gr) ~ unite_gr,
                                 TRUE ~ unite))
      
      #Identifier si les unités de donnees autres que les regroupées sont du bons format
      donnees_compl<-donnees %>% filter(!unite %in% c(regroupement_df$unite_gr))
      
      if(denom_externe_type_unite == "Régional"){
        # Vérifier les codes RSS
        if (denom_externe_geo == "RSS" & (any(nchar(donnees_compl$unite) != 2) |
                                          !all(donnees_compl$unite %in% pop_ref$code[pop_ref$geo == "RSS"]))) {
          stop("\nLes codes RSS autres que les regroupements doivent être un caractère de 2 chiffres, exemples '06','16', etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
        
        # Vérifier les codes RLS
        if (denom_externe_geo == "RLS" & (any(nchar(donnees_compl$unite) != 4) |
                                          !all(donnees_compl$unite %in% pop_ref$code[pop_ref$geo == "RLS"]))) {
          stop("\nLes codes RLS autres que les regroupements doivent être un caractère de 4 chiffres, exemples '0111', '0815', '1112' etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
        
        # Vérifier les codes RTS
        if (denom_externe_geo == "RTS" & (any(nchar(donnees_compl$unite) != 3) |
                                          !all(donnees_compl$unite %in% pop_ref$code[pop_ref$geo == "RTS"]))) {
          stop("\nLes codes RTS autres que les regroupements doivent être un caractère de 3 chiffres, exemples '021', '065', '161' etc. Consultez le tableau pop_ref pour connaître les valeurs admissibles.")
        }
      }else{
        if(any(nchar(donnees_compl$unite) != 4)|
           !all(donnees_compl$unite %in% pop_ref$annee)){
          stop("\nLes valeurs d'années autres que les années regroupées doivent être de format quatre chiffres, exemples '2023'. Consultez annees dans le tableau pop_ref pour connaître les valeurs admissibles.")
          
        }
      }
      
    }
    
    # Grouper par variables, calculer la somme des populations
    denom_group <- denom_pop %>%
      filter(unite %in% unique(donnees$unite)) %>% 
      group_by(across(all_of(c(vars)))) %>%
      summarize(denom = sum(pop))
    
    
  }else{
    denom_group <- donnees %>%
      group_by(across(all_of(c(vars)))) %>%
      summarize(denom = ifelse(type_denom=="colonne agrégée", 
                               sum(denominateur_agr_col),
                               ifelse(type_denom=="total interne",n(),NA)))
  }
  
  
  #
  verif_n<-denom_group %>% droplevels %>%  ungroup %>% expand(!!!syms(vars)) %>% anti_join(denom_group) %>%suppressMessages() %>% as.data.frame()
  
  if(nrow(verif_n)!=0) stop("\nStrate(s) d'agrégation manquante(s). Veuillez créer des catégories d'âges plus larges, considérer enlever l'ajustement par sexe ou atres variables, ou exclure des unités (régions ou années) trop petites. \n\n",
                            paste(capture.output(print(verif_n)),collapse="\n"),"\n")
  
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ################# NUMÉRATEUR ####################
  #-----------------------------------------------#
  #-----------------------------------------------#
  num_group<-
    donnees %>%
    filter(if(type_num=="filtré") eval(parse(text = num_filtre_expression)) else TRUE) %>%
    group_by(across(all_of(vars))) %>%
    summarize(num = ifelse(type_num=="colonne agrégée",
                           sum(numerateur_agr_col),
                           n()))
  
  #-----------------------------------------------#
  #-----------------------------------------------#
  ##################### JOIN ######################
  #-----------------------------------------------#
  #-----------------------------------------------#
  agg<-
    denom_group %>%
    left_join(num_group) %>%
    suppressMessages() %>%
    mutate(num=replace_na(num,0))
  
  #Réassigner les noms de colonnes originaux
  colnames(agg)[1]<-{{unite}}
  if(!is.null(sexe))colnames(agg)[3]<-{{sexe}}
  
  
  structure(list("df"=agg,
                 "unite"=unite,
                 "age_cat_mins"=age_cat_mins,
                 "age_filtre_max"=age_filtre_max,
                 "sexe"=sexe,
                 "autres_vars"=autres_vars),
            class=c("agregation","list"))
  
  
}





