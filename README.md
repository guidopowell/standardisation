standardisation
================

-   [Introduction](#introduction)
    -   [Installation](#installation)
    -   [Description courte](#description-courte)
    -   [Exemples d’utilisation](#exemples-dutilisation)
-   [Description détaillée](#description-détaillée)
    -   [`agregation`](#agregation)
        -   [Regroupement d’âge](#regroupement-dâge)
        -   [Structure des données](#structure-des-données)
    -   [`standardisation_interne`](#standardisation_interne)
    -   [`standardisation_externe`](#standardisation_externe)

# Introduction

Le package **standardisation** comprend un ensemble de fonctions conçues
pour la standardisation et la transformation des données. La
standardisation permet des comparaisons plus fiables entre différentes
populations en ajustant les taux de maladie, de mortalité ou d’autres
indicateurs en tenant compte des différences d’âge, de sexe, ou d’autre
variables. Ce package permet la standardisation en ajustant par une
population de référence soit interne, soit externe. De plus, la fonction
agregation permet de convertir les données individuelles ou
partiellement agrégées en un format propice à la standardisation.

<br>

## Installation

Pour installer à partir de github il faut avoir installé le package
devtools.

``` r
if (!require("devtools")) {
  install.packages("devtools")
}
devtools::install_github("guidopowell/standardisation")
```

## Description courte

Le package comprend trois fonctions d’analyse et deux fonctions de
visualisation :

`agregation()` : Cette fonction est conçue pour transformer des données
individuelles ou partiellement agrégées en un format adapté pour les
fonctions de standardisation. Elle peut gérer une large gamme de types
et de formes de données, garantissant une flexibilité pour répondre à
divers besoins d’agrégation de données.

Il convient de noter que les données entièrement agrégées qui répondent
déjà aux exigences des fonctions de standardisation peuvent contourner
cette étape et passer directement à la standardisation.

`plot.agregation()` : Cette fonction visualise un heatmap des données
agrégées pour validation (il suffit d’appeler la fonction `plot` avec un
objet de classe agregation).

`standardisation_interne()` : Cette fonction applique une
standardisation interne à des données agrégées. Dans le processus de
standardisation, elle utilise soit la somme des données d’entrée comme
population de référence ou une unité spécifiée par `reference_unite`. La
fonction ajuste pour des facteurs tels que le groupe d’âge, le sexe, et
d’autres variables fournies

La standardisation interne peut-être directe ou indirecte.

`standardisation_externe()` : Cette fonction applique une
standardisation externe à des données agrégées, prenant comme référence
un fichier de données `pop_ref` réprésentant la population du Québec
stratifiée par âge et sexe, à de différentes années et niveaux
géographiques. Cette approche est utile lorsque les données à ajuster ne
sont pas suffisamment représentatif de la population (par exemple une
petite cohorte de patients ayant reçu un nouveau médicamment).

La standardisation externe doit être directe car les numérateurs de la
population référence ne sont pas disponible.

`plot.standardisation_list()` : Cette fonction produit un graphiques à
barres ou de points pour visualiser les résultats de la standardisation
(il suffit d’appeler la fonction `plot` avec un objet de classe
standardisation_list).

<br>

## Exemples d’utilisation

Voici un exemple simple d’utilisation avec des données simulées de
patients hospitalisés parmi lesquels certains sont décédés (valeur “Oui”
pour la variable `deces`). On veut comparer les taux de décès entre les
régions (RSS) en ajustant pour l’âge. Les détails d’arguments sont
précisés plus bas.

La première étape est d’agréger les données brutes.

``` r
agr<-agregation(donnees = donnees_sim %>% filter(annee == "2022"), 
                   unite = "rss",
                   age = "age",
                   age_cat_mins = c(0,50,60,70),
                   type_num = "filtré",
                   num_filtre_expression = "deces == 'Oui' ",
                   type_denom = "total interne")
```

<br>

On peut valider les résultats de l’agrégation rapidement en les
visualisant.

``` r
plot(agr)
```

<img src="vignettes/plot_agregation.PNG" width="70%" style="display: block; margin: auto;" />

<br>

Une fois agrégée, les données peuvent être standardisées, dans cet
exemple on fait une standardisation interne et indirecte. Les fonctions
de standardisation retiennent les arguments de la fonction d’agrégation
pour faciliter la standardisation.

``` r
st_i<-standardisation_interne(donnees = agr,
                            methode = "indirecte")
## Joining with `by = join_by(unite)`
```

On peut vérifier les résultats de la standardisation (l’autre objet
“Details” contient les strates d’agrégation). Les intervalles de
confiance sont issues du package `PHEIndicatormethods`.

``` r
st_i
## # A tibble: 15 × 7
## # Groups:   rss [15]
##    rss                                obs    exp ratio_brut ratio IC_bas IC_haut
##    <chr>                            <int>  <dbl>      <dbl> <dbl>  <dbl>   <dbl>
##  1 01_Bas-Saint-Laurent                17  19.1       0.995 0.891  0.518    1.43
##  2 02_Saguenay-Lac-Saint-Jean          18  25.8       0.683 0.696  0.413    1.10
##  3 03_Capitale-Nationale               79  61.8       1.22  1.28   1.01     1.59
##  4 04_Mauricie et Centre-du-Québec     50  54.4       0.943 0.919  0.682    1.21
##  5 05_Estrie                           44  39.1       1.14  1.12   0.817    1.51
##  6 06_Montréal                        155 147.        1.07  1.06   0.896    1.24
##  7 07_Outaouais                        23  19.7       0.988 1.17   0.740    1.75
##  8 08_Abitibi-Témiscamingue            14  13.8       1.12  1.01   0.553    1.70
##  9 09_Côte-Nord                         6  12.7       0.417 0.472  0.173    1.03
## 10 11_Gaspésie-Îles-de-la-Madeleine     8   8.19      1.12  0.976  0.422    1.92
## 11 12_Chaudière-Appalaches             38  40.0       0.988 0.950  0.672    1.30
## 12 13_Laval                            35  29.8       1.13  1.17   0.818    1.63
## 13 14_Lanaudière                       42  36.6       1.10  1.15   0.827    1.55
## 14 15_Laurentides                      45  53.7       0.808 0.837  0.611    1.12
## 15 16_Montérégie                      119 131.        0.930 0.907  0.751    1.08
```

<br>

Il est aussi possible de visualiser les résultats de standardisation.

``` r
plot(st_i)
```

<img src="vignettes/plot_indirect.PNG" width="70%" style="display: block; margin: auto;" />

<br> <br> Et voici ici un exemple d’une standardisation externe et
directe. Notez que les groupes d’âges doivent être spéficiés de nouveau
pour permettre la correspondance avec le dataframe de référence externe.
La valeur 99 pour ref_externe_code fait référence au niveau géographique
de l’ensemble du Québec.

``` r
st_e<-standardisation_externe(donnees = agr,
                            ref_externe_annee = 2022,
                            ref_externe_code = "99",
                            multiplicateur = 100)
## Warning in standardisation_externe(donnees = agr, ref_externe_annee = 2022, : 
## Les groupes d'âge de la population d'analyse sont assumés comme étant équivalents et dans la même ordre que ceux de la population externe de référence.
## Sinon, veuillez modifier les valeurs de vos groupes d'âge
## 
##   Âge.données Âge.externe
## 1      [0,50)      [0,50)
## 2     [50,60)     [50,60)
## 3     [60,70)     [60,70)
## 4    [70,Inf)    [70,Inf)
## Warning in standardisation_externe(donnees = agr, ref_externe_annee = 2022, : 
## Le taux ajusté n'est pas calculé pour les unités ayant < 10 observations

st_e
## # A tibble: 15 × 7
## # Groups:   rss [15]
##    rss                        n   pop valeur_brute valeur_ajustee IC_bas IC_haut
##    <chr>                  <int> <int>        <dbl>          <dbl>  <dbl>   <dbl>
##  1 01_Bas-Saint-Laurent      17   127        13.4            3.68   1.77    6.42
##  2 02_Saguenay-Lac-Saint…    18   196         9.18           5.27   1.43   10.7 
##  3 03_Capitale-Nationale     79   481        16.4            8.85   6.00   12.2 
##  4 04_Mauricie et Centre…    50   394        12.7            5.56   3.43    8.19
##  5 05_Estrie                 44   288        15.3            4.05   2.78    5.64
##  6 06_Montréal              155  1075        14.4            5.30   4.13    6.62
##  7 07_Outaouais              23   173        13.3            6.85   3.75   11.1 
##  8 08_Abitibi-Témiscamin…    14    93        15.1            3.15   1.72    5.29
##  9 09_Côte-Nord               6   107         5.61          NA     NA      NA   
## 10 11_Gaspésie-Îles-de-l…     8    53        15.1           NA     NA      NA   
## 11 12_Chaudière-Appalach…    38   286        13.3            2.93   2.07    4.02
## 12 13_Laval                  35   230        15.2           13.0    7.39   20.2 
## 13 14_Lanaudière             42   284        14.8            4.94   3.15    7.19
## 14 15_Laurentides            45   414        10.9            7.81   4.48   12.0 
## 15 16_Montérégie            119   951        12.5            6.09   4.12    8.36
```

<br>

Et la visualisation.

``` r
plot(st_e)
```

<img src="vignettes/plot_externe.PNG" width="70%" style="display: block; margin: auto;" />

<br>

# Description détaillée

Regardons plus en détail les trois fonctions.

## `agregation`

### Regroupement d’âge

La fonction `agregation()` est surtout utile lorsqu’il faut regrouper
des valeurs d’âge continu et compter la somme par groupe. Pour se faire,
il faut spécifier l’argument `age_cat_mins` (et si nécessaire
`age_filtre_max`). Cet argument prend comme valeur un vecteur des âges
minimum de chaque groupe, par exemple, c(18,40,60,80). Cet exemple
produirait les groupes d’âge suivant: \[18, 39), \[40, 59), \[60, 79),
et \[80, Inf). La première valeur du vecteur crée un filtre sur les
données en excluant les patients de moins de 18 ans (une valeur de 0
n’applique pas de filtre). Par défaut, l’âge maximale est Inf, donc
aucun filtre n’est appliqué pour la dernier groupe d’âge. Si nécessaire,
une valeur peut être spéficifié pour `age_filtre_max` qui permettrait
des exclure les patients en haut de cet âge (la valeur est un maximum
“exclusif”).

<br>

### Structure des données

Bien que l’utilisation typique de cette fonction est d’agréger des
données individuelles ayants des valeurs d’âges continus, la fonction
offre aussi de la flexibilité dans la manière dont les numérateurs et
les dénominateurs sont identifiés et calculés. Cependant, il est
important de noter que toutes les combinaisons des types de numérateurs
(`type_num`) et de dénominateurs (`type_denom`) ne sont pas autorisées.

#### **Numérateurs**

Il y a trois façons d’identifier les numérateurs dans un ensemble de
données :

1.  `type_num = "filtré"` : Une expression logique est spécifié pour
    identifier quelles lignes dans un ensemble de données individuelles
    doivent être comptées. Cette option nécessite l’argument
    `num_filtre_expression` (par exemple,
    `num_filtre_expression  = "hospitalisation == TRUE"` ).

<img src="vignettes/image_num_filtre.PNG" width="20%" style="display: block; margin: auto;" />

1.  `type_num = "total interne"` : L’ensemble de données individuelles
    fourni est compté comme numérateur. Par exemple dans un cas où une
    extraction de données ne représente que les patients à analyser.

<img src="vignettes/image_num_total.PNG" width="20%" style="display: block; margin: auto;" />

1.  `type_num = "colonne agrégée"` : Les données sont partiellement
    agrégées et une colonne spécifie les décomptes des numérateurs.
    Cette option nécessite l’argument `numerateur_agr_col.`

<img src="vignettes/image_num_col.PNG" width="20%" style="display: block; margin: auto;" />

<br>

#### **Dénominateurs**

De même, il y a trois façons d’obtenir les dénominateurs :

1.  `type_denom = "total_interne"` : L’ensemble de données individuelles
    fourni est compté comme dénominateur.

<img src="vignettes/image_denom_total.PNG" width="20%" style="display: block; margin: auto;" />

1.  `type_denom = "externe"` : Un ensemble de données de population
    externe agrégé , le fichier `pop_ref`, est utilisé comme
    dénominateurs. Cette option nécessite l’argument
    `denom_externe_type_unite`. Si ce dernier est “Régional” (au lieu de
    “Annuel”), il faut préciser une valeur pour `denom_externe_annee` et
    `denom_externe_geo`. Un dernier argument facultatif est
    `denom_externe_regroupement_unite` (voir plus bas).

<img src="vignettes/image_denom_ext.PNG" width="20%" style="display: block; margin: auto;" />

1.  `type_denom = "colonne_agrégée"` : Les données sont partiellement
    agrégées et une colonne spécifie les décomptes des dénominateurs.
    Cette option nécessite l’argument `denominateur_agr_col.`

<img src="vignettes/image_denom_col.PNG" width="20%" style="display: block; margin: auto;" />

<br>

#### **Combinaisons autorisées**

Toutes les combinaisons de `type_num` et `type_denom` ne sont pas
autorisées. Les combinaisons autorisées sont les suivantes :

-   `type_num = "filtré"` peut être associé avec
    `type_denom = "total_interne"` ou `type_denom = "externe"`.

-   `type_num = "total_interne"` ne peut être utilisé qu’avec
    `type_denom = "externe"`.

-   `type_num = "colonne agrégée"` peut être associé avec
    `type_denom = "colonne_agrégée"` ou `type_denom = "externe"`.

<img src="vignettes/image.PNG" width="90%" style="display: block; margin: auto;" />

<br>

#### **Exemple de regroupement d’unité**

Dans un scénario où l’agrégation se fait avec un dénominateur externe et
que les unités du numérateur représentent de regroupement d’unités (par
exemple “Régions du nord” pour les RSS 10, 18 et 19 ou “2020 à 2022”
pour les années 2020, 2021 et 2022), l’argument
`denom_externe_regroupement_unite` permet de effectuer une
correspondance entre ces regroupements d’unités et les unités du fichier
`pop_ref`. Les valeurs acceptées pour cet argument doit être en format
de liste où les noms des éléments correspondent aux valeurs regroupés de
`donnees` et les valeurs de chaque élément représente les unités de
`pop_ref` à regrouper.

Prenons un exemple où les RSS de Montréal et Laval et de
Capitale-Nationale et Chaudières-Appalaches sont regroupés dans les
mêmes zones.

``` r
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

agr_avec_regroup
## # A tibble: 26 × 4
## # Groups:   zone [13]
##    zone  AGE_CAT   denom   num
##    <chr> <chr>     <int> <int>
##  1 01    [0,75)   176149     0
##  2 01    [75,Inf)  22948     6
##  3 02    [0,75)   251493     5
##  4 02    [75,Inf)  28456     4
##  5 04    [0,75)   475844     3
##  6 04    [75,Inf)  57016     4
##  7 05    [0,75)   456707     3
##  8 05    [75,Inf)  49853    16
##  9 07    [0,75)   376522     3
## 10 07    [75,Inf)  27743     0
## # ℹ 16 more rows
```

<br>

<br>

Avec les données agrégés, on peut maintenant passer à la
standardisation. Si vous aviez des données déjà agrégées, il faut
s’assurer que toutes les strates sont inclues, même celles qui ont 0
comme numérateur.

<br>

## `standardisation_interne`

La standardisation interne permet de prendre comme référence la
population de l’ensemble de données, évitant alors le besoin d’apparier
des données de référence externe. Il est aussi possible dans la
standardisation interne de sélectionner une unité de l’analyse (par
exemple, une région ou une année) comme référence. Dans cet exemple on
reprend celui décris plus haut mais en spécifiant le RSS de Montréal
(“06_Montréal” ) comme référence.

``` r
st_i<-standardisation_interne(donnees = agr,
                              reference_unite = "06_Montréal",
                              methode = "indirecte",
                              multiplicateur = 100)
## Joining with `by = join_by(unite)`
```

Dans l’élement “Resultats” on contate que le ratio pour Montréal est de
1, car le nombre observés de cas est le même que le “expected” étant
donné que c’est la référence.

``` r
st_i
## # A tibble: 15 × 7
## # Groups:   rss [15]
##    rss                                obs    exp ratio_brut ratio IC_bas IC_haut
##    <chr>                            <int>  <dbl>      <dbl> <dbl>  <dbl>   <dbl>
##  1 01_Bas-Saint-Laurent                17  20.6       0.995 0.825  0.480   1.32 
##  2 02_Saguenay-Lac-Saint-Jean          18  27.6       0.683 0.652  0.386   1.03 
##  3 03_Capitale-Nationale               79  64.7       1.22  1.22   0.966   1.52 
##  4 04_Mauricie et Centre-du-Québec     50  57.7       0.943 0.867  0.643   1.14 
##  5 05_Estrie                           44  41.4       1.14  1.06   0.773   1.43 
##  6 06_Montréal                        155 155         1.07  1      0.849   1.17 
##  7 07_Outaouais                        23  20.5       0.988 1.12   0.711   1.68 
##  8 08_Abitibi-Témiscamingue            14  15.0       1.12  0.936  0.511   1.57 
##  9 09_Côte-Nord                         6  13.1       0.417 0.458  0.168   0.998
## 10 11_Gaspésie-Îles-de-la-Madeleine     8   8.80      1.12  0.909  0.392   1.79 
## 11 12_Chaudière-Appalaches             38  42.1       0.988 0.903  0.639   1.24 
## 12 13_Laval                            35  31.1       1.13  1.12   0.783   1.56 
## 13 14_Lanaudière                       42  38.3       1.10  1.10   0.790   1.48 
## 14 15_Laurentides                      45  55.9       0.808 0.805  0.587   1.08 
## 15 16_Montérégie                      119 139.        0.930 0.854  0.707   1.02
```

<br>

<br>

## `standardisation_externe`

La standardisation externe permet d’ajuster les unités d’analyse
(régions ou années) en prenant comme référence le fichier de population
du Québec, `ref_pop` . À noter que seulement l’ajustement par âge et
sexe est possible dans la standardisation externe car les taux de
référence ne sont pas disponibles pour d’autres variables.

-   `ref_externe_annee` . Le fichier `pop_ref` contient des données de
    population datant de 1996 jusqu’à 2041 (projections). Il faut
    sélectionner une année comme référence.

-   `ref_externe_code`. Le fichier `pop_ref` contient des données pour
    l’ensemble du Québec, ou par différents niveaux géographiques (RSS,
    RLS, RTS). Le code “99” sert à sélectionner l’ensemble du Québec
    comme référence. Les codes de RSS sont une chaînes de 2 caractères,
    les RTS sont de 3 caractères, et les RLS sont de 4 caractères.

Le prochain exemple démontre un scénario où on veut comparer des années,
en ajustant avec une année de référence externe. Pour ce faire nous
allons refaire l’agrégation des données. Pour l’agrégation nous allons
prendre un dénominateur externe. Cela permettra d’illustrer la nuance
entre l’utilisation du fichier de population externe pour les
dénominateurs et la référence. Par exemple lorsque l’unité est une année
et on veut un dénominateur externe (`type_denom` = “externe”), il faut
préciser `denom_externe_type_unite` = “Annuel”. Dans ce cas il n’est pas
nécessaire de préciser une année pour `denom_externe_annee` un niveaux
de géographie `denom_externe_geo` (dans cette situation ce sont les
populations annnuelles de l’ensemble du Québec qui servent comme
dénominateurs).

``` r
agr_ext<-agregation(donnees = donnees_sim , 
                unite = "annee",
                age = "age",
                age_cat_mins = c(18,65,85),
                sexe="sexe",
                type_num = "filtré",
                num_filtre_expression = "deces == 'Oui' ",
                type_denom = "externe",
                denom_externe_type_unite = "Annuel")

agr_ext
## # A tibble: 18 × 5
## # Groups:   annee, AGE_CAT [9]
##    annee AGE_CAT  sexe     denom   num
##    <chr> <chr>    <chr>    <int> <int>
##  1 2020  [18,65)  F     10387056     8
##  2 2020  [18,65)  M     10742692    15
##  3 2020  [65,85)  F      3089952    92
##  4 2020  [65,85)  M      2836976    94
##  5 2020  [85,Inf) F       541040   100
##  6 2020  [85,Inf) M       298756    66
##  7 2021  [18,65)  F     10320536    17
##  8 2021  [18,65)  M     10690080     5
##  9 2021  [65,85)  F      3194620    62
## 10 2021  [65,85)  M      2942688    73
## 11 2021  [85,Inf) F       552872    41
## 12 2021  [85,Inf) M       311364    36
## 13 2022  [18,65)  F     10329444    37
## 14 2022  [18,65)  M     10720624    26
## 15 2022  [65,85)  F      3307856   156
## 16 2022  [65,85)  M      3055536   179
## 17 2022  [85,Inf) F       561172   130
## 18 2022  [85,Inf) M       323044   165
```

Maintenant nous poursuivons avec une standardisation externe de ces
données. Cette fois il faut préciser une année pour `ref_externe_annee`
car il n’y a qu’une seule année qui sert comme référence. La valeur “99”
pour `ref_externe_code` précise que c’est l’ensemble du Québec qui sert
comme référence (d’autres valeurs sont permises si on veut une région
particulière comme référence).

Ici le multiplicateur est beaucoup plus grand pour permettre des taux
plus facile à interpreter.

``` r
st_ext<-standardisation_externe(donnees = agr_ext,
                            ref_externe_annee = 2022,
                            ref_externe_code = "99",
                            multiplicateur = 100000)
## Warning in standardisation_externe(donnees = agr_ext, ref_externe_annee = 2022, : 
## Les groupes d'âge de la population d'analyse sont assumés comme étant équivalents et dans la même ordre que ceux de la population externe de référence.
## Sinon, veuillez modifier les valeurs de vos groupes d'âge
## 
##   Âge.données Âge.externe
## 1     [18,65)     [18,65)
## 2     [65,85)     [65,85)
## 3    [85,Inf)    [85,Inf)

plot(st_ext, Annuel=T)
```

<img src="README_files/figure-gfm/unnamed-chunk-23-1.png" style="display: block; margin: auto;" />
