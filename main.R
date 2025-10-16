# Copyright 2024 Louis Héraut (louis.heraut@inrae.fr)*1
#
# *1   INRAE, France
#
# This file is part of Explore2 R toolbox.
#
# Explore2 R toolbox is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Explore2 R toolbox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Explore2 R toolbox.
# If not, see <https://www.gnu.org/licenses/>.


# Chemin du dossier à changer
setwd("C:/Users/esauquet/Desktop/Explore2_peche_aux_outils-main/")


## 0. INFO ___________________________________________________________
# 0.1. Library _______________________________________________________
if(!require(ncdf4)) install.packages("ncdf4")
if(!require(lubridate)) install.packages("lubridate")
if(!require(dplyr)) install.packages("dplyr")
if(!require(tidyr)) install.packages("tidyr")
if(!require(ggh4x)) install.packages("ggh4x")
if(!require(latex2exp)) install.packages("latex2exp")
if(!require(sf)) install.packages("sf")
if(!require(remotes)) install.packages("remotes")
if(!require(dataSHEEP)) remotes::install_github("super-lou/dataSHEEP")
if(!require(httr)) install.packages("httr")

## 0.2. Source _______________________________________________________
Scripts = list.files("R", full.names=TRUE)
for (script in Scripts) {
    source(script)    
}

## 0.3. Chemins ______________________________________________________
figures_dir = "figures"
if (!dir.exists(figures_dir)) {
    dir.create(figures_dir)
}
shapefiles_dir = "shapefiles"

## 0.4. Narratifs ____________________________________________________
# La liste des narratifs ainsi que quelques données utiles les
# concernant
Storylines = list(
    vert=list(
        name="vert",
        EXP="(historical)|(rcp85)",
        GCM="HadGEM2-ES", RCM="ALADIN63", BC="ADAMONT",
        climate_chain=c(
            "historical|MOHC-HadGEM2-ES|CNRM-ALADIN63|MF-ADAMONT-SAFRAN-1980-2011",
            "rcp85|MOHC-HadGEM2-ES|CNRM-ALADIN63|MF-ADAMONT-SAFRAN-1980-2011",
            "historical-rcp85|HadGEM2-ES|ALADIN63|MF-ADAMONT"),
        color="#569A71", color_light="#BAD8C6",
        info="Réchauffement marqué et augmentation des précipitations"
    ),
    jaune=list(
        name="jaune",
        EXP="(historical)|(rcp85)",
        GCM="CNRM-CM5", RCM="ALADIN63", BC="ADAMONT",
        climate_chain=c(
            "historical|CNRM-CERFACS-CNRM-CM5|CNRM-ALADIN63|MF-ADAMONT-SAFRAN-1980-2011",
            "rcp85|CNRM-CERFACS-CNRM-CM5|CNRM-ALADIN63|MF-ADAMONT-SAFRAN-1980-2011",
            "historical-rcp85|CNRM-CM5|ALADIN63|MF-ADAMONT"),
        color="#EECC66", color_light="#F8EBC2",
        info="Changements futurs relativement peu marqués"
    ),
    orange=list(
        name="orange",
        EXP="(historical)|(rcp85)",
        GCM="EC-EARTH", RCM="HadREM3-GA7", BC="ADAMONT",
        climate_chain=c(
            "historical|ICHEC-EC-EARTH|MOHC-HadREM3-GA7-05|MF-ADAMONT-SAFRAN-1980-2011",
            "rcp85|ICHEC-EC-EARTH|MOHC-HadREM3-GA7-05|MF-ADAMONT-SAFRAN-1980-2011",
            "historical-rcp85|EC-EARTH|HadREM3-GA7-05|MF-ADAMONT"),
        color="#E09B2F", color_light="#F3D7AC",
        info="Fort réchauffement et fort assèchement en été (et en annuel)"
    ),
    violet=list(
        name="violet",
        EXP="(historical)|(rcp85)",
        GCM="HadGEM2-ES", RCM="CCLM4-8-17", BC="ADAMONT",
        climate_chain=c(
            "historical|MOHC-HadGEM2-ES|CLMcom-CCLM4-8-17|MF-ADAMONT-SAFRAN-1980-2011",
            "rcp85|MOHC-HadGEM2-ES|CLMcom-CCLM4-8-17|MF-ADAMONT-SAFRAN-1980-2011",
            "historical-rcp85|HadGEM2-ES|CCLM4-8-17|MF-ADAMONT"),
        color="#791F5D", color_light="#E9A9D5",
        info="Fort réchauffement et forts contrastes saisonniers en précipitations"
    )
)

### 0.5. Périodes typiques ___________________________________________
historical = c("1976-01-01", "2005-08-31")
Horizons = list(H1=c("2021-01-01", "2050-12-31"),
                H2=c("2041-01-01", "2070-12-31"),
                H3=c("2070-01-01", "2099-12-31"))


## 1. PROJECTIONS ____________________________________________________
### 1.1. Obtenir les URLs ____________________________________________
# Une liste préformatée des URLs disponibles sur DRIAS-Eau est
# disponible dans le fichier URL_DRIAS_projections.csv
URL = dplyr::as_tibble(read.table(
                 file=file.path("robot",
                                "URL_DRIAS_projections.csv"),
                 header=TRUE,
                 sep=",", quote='"'))

# Le tibble URL contient donc l'ensemble des combinaisons utiles pour
# faire une sous sélection des URLs disponibles
EXP = unique(URL$EXP)
GCM = unique(URL$GCM)
RCM = unique(URL$RCM)
BC = unique(URL$BC)
HM = unique(URL$HM)
Variables = unique(URL$variable)

# Choix d'un nom de dossier pour une sélection de NetCDF de projections
projection_dir = paste0("DRIAS_projections_",
                        "narratif_J2000_GRSD")

### 1.2. Filtrer les URLs ____________________________________________
# Soit en utilisant le tibble URL avec dplyr pour une combinaison
# spécifique ...
URL_filtered = dplyr::filter(URL,
                             EXP == "rcp85" &
                             grepl("ADAMONT", BC) &
                             HM %in% c("J2000", "GRSD") &
                             variable == "discharge")

# ou pour filtrer les narratifs Explore2
URL_filtered = dplyr::tibble()
for (storyline in Storylines) {
    URL_filtered_tmp = dplyr::filter(URL,
                                     grepl(storyline$EXP, EXP) &
                                     grepl(storyline$GCM, GCM) &
                                     grepl(storyline$RCM, RCM) &
                                     grepl(storyline$BC, BC))
    URL_filtered = dplyr::bind_rows(URL_filtered, URL_filtered_tmp)
}
URL_filtered = dplyr::filter(URL_filtered,
                             HM %in% c("J2000", "GRSD"))
Urls = URL_filtered$url

# Soit en lisant directement un fichier txt qui contient une liste des
# URLs récupérés par le biais de la plateforme DRIAS-Eau
# Urls = readLines("manual_URL_DRIAS_projections.txt")

### 1.3. Obtenir les NetCDFs _________________________________________
get_DRIAS_netcdf(Urls, projection_dir)

### 1.4. Lire un NetCDF ______________________________________________
# Obtenir l'ensemble des chemins des NetCDFs téléchargés
Paths = list.files(projection_dir,
                   recursive=TRUE,
                   full.names=TRUE)

# Le package ncdf4 permet de lire un NetCDF
NC = nc_open(Paths[1])

# Dans un premier temps, il est possible d'obtenir la liste des
# attributs globaux ...
ncatt_get(NC, "")
# ou un seul spécifiquement
ncatt_get(NC, "", "hy_institute_id")$value
# De la même manière, il est possible d'obtenir les attributs
# d'une dimension ou d'une variable
ncatt_get(NC, "time", "units")$value

# Dans un second temps, il est possible d'obtenir une variable
# contenue dans la liste des variables disponibles
names(NC$var)
# Donc par exemple pour obtenir le code des stations :
Codes_NC = ncvar_get(NC, "code")

# De cette manière, pour la Dore à Dorat ...
code = "K298191001"
# il faut chercher son indice dans ce NetCDF
id = match(code, Codes_NC)
# Cet id permet donc d'aller chercher les informations d'intérêt dans
# ce NetCDF et uniquement dans celui-ci
ncvar_get(NC, "topologicalSurface_model")[id]

# Cependant, il est plus périlleux de vouloir répéter l'opération
# précédente pour obtenir l'entierté de la matrice des débits.
# Il est donc conseillé de n'en extraire que la partie souhaitée en
# utilisant les fonctionnalités internes aux NetCDFs
# On part de l'indice id pour la première dimension "station" et on
# part du début de la dimension seconde dimension "time"
start = c(id, 1)
# On compte un seul pas sur la dimension "station" et on prend
# l'entiereté de la dimension "time"
count = c(1, -1)
# Ainsi, on peut obtenir les débits de la Dore à Dorat pour ce NetCDF
debit = ncvar_get(NC, "debit",
                  start=start,
                  count=count)

# et son vecteur temps associé
Date = ncvar_get(NC, "time") + as.Date("1950-01-01")

# Cette fonction reprend ce procédé avec une liste de stations pour
# obtenir un tibble prêt à être traité
code = "K298191001"
data = read_DRIAS_netcdf(Paths, Codes=code)

# La variables Codes peut correspondre à une liste de code comme :
# Codes = c("K297031001", "K298191001", "K299401001"), ou à une
# expression régulière.
# Donc "*" utilisera tous les codes du NetCDF et par exemple "^K20",
# cherchera tous les codes commençant par cette expression.

### 1.5. Afficher les projections ____________________________________
# Pour la Dora à Dorat
# Calcul de la date minimale parmi les chaînes de modélisation
min_date = data %>%
    dplyr::filter(EXP == "historical") %>%
    dplyr::group_by(chain) %>%
    dplyr::summarise(min=min(date, na.rm=TRUE))
min_date = max(min_date$min, na.rm=TRUE)

# Pareil pour la date maximale
max_date = data %>%
    dplyr::filter(EXP != "historical") %>%
    dplyr::group_by(chain) %>%
    dplyr::summarise(max=max(date, na.rm=TRUE))
max_date = min(max_date$max, na.rm=TRUE)

# Filtrage des données sur la période de disponibilité
data = dplyr::filter(data,
                     min_date <= date &
                     date <= max_date)

# Pour chaque narratif, calcule de la médiane sur l'nemseble des modèles
# hydrologiques
data_med = data %>%
    dplyr::group_by(climate_chain, date) %>%
    dplyr::summarise(debit=median(debit, na.rm=TRUE),
                     .groups="drop")

# Pour chaque narratif
for (storyline in Storylines) {
    data_med_storyline = data_med %>%
        dplyr::filter(climate_chain %in% storyline$climate_chain)

    # Définition du plot et du theme
    plot = ggplot() +
        theme_minimal() +
        theme(panel.grid.major.x=element_blank(),
              panel.grid.minor.x=element_blank(),
              axis.line.x=element_line(color="grey65",
                                       linewidth=0.5,
                                       lineend="round"),
              axis.ticks.x=element_line(color="grey80"),
              axis.ticks.length=unit(0.2, "cm"),
              plot.title=element_text(color=storyline$color)) +
        
        # Titre
        ggtitle(TeX(paste0(code, " - \\textbf{",
                           storyline$info, "}"))) +
        
        # Affichage des chaînes de modélisation
        geom_line(data=data,
                  aes(x=date,
                      y=debit,
                      group=chain),
                  color="grey65",
                  linewidth=0.8,
                  alpha=0.15,
                  lineend="round") +
        # et de la médiane du narratif concerné
        geom_line(data=data_med_storyline,
                  aes(x=date,
                      y=debit),
                  color=storyline$color,
                  linewidth=0.25,
                  alpha=1,
                  lineend="round")

    # Mise en forme des axes
    plot = plot +
        xlab(NULL) +
        scale_x_date(
            breaks=get_breaks,
            minor_breaks=get_minor_breaks,
            guide="axis_minor",
            date_labels="%Y",
            expand=c(0, 0)) +
        ylab(TeX("débit \\small{m$^{3}$.s$^{-1}$}")) +
        scale_y_sqrt(limits=c(0, NA),
                     expand=c(0, 0))
    
    # Sauvegarde
    ggsave(plot=plot,
           filename=file.path(figures_dir,
                              paste0("DRIAS_projection_",
                                     code, "_",
                                     storyline$name, ".pdf")),
           width=50, height=10, units="cm")
}


## 2. INDICATEURS ____________________________________________________
### 2.1. Obtenir les URLs ____________________________________________
# Une liste préformatée des URLs disponibles sur DRIAS-Eau est
# disponible dans le fichier URL_DRIAS_indicateurs.csv
URL = dplyr::as_tibble(read.table(
                 file=file.path("robot",
                                "URL_DRIAS_indicateurs.csv"),
                 header=TRUE,
                 sep=",", quote='"'))

# Le tibble URL contient donc l'ensemble des combinaisons utiles pour
# faire une sous sélection des URLs disponibles
EXP = unique(URL$EXP)
BC = unique(URL$BC)
HM = unique(URL$HM)
Indicateurs_DRIAS = unique(URL$indicateur)
Indicateurs = gsub("Debit-", "",
                   gsub("[_].*", "", Indicateurs_DRIAS))

# Il est donc par exemple préférable de faire un dossier de NetCDF
# par indicateur pour simplifier les interactions avec les fichiers
# Donc pour un indicateur :
# Nom dans le fichier (liste disponible dans Indicateurs_DRIAS)
indicateur_DRIAS =
  "QMNA"
#"Debit-VCN10_Saisonnier"
# "Debit-QA_Saisonnier"
# Nom dans le NetCDF (liste disponible dans Indicateurs) 
indicateur =
   "QMNA"
    # "VCN10"
    # "QA"
# Nom de l'indicateur à afficher, utile par exemple pour les
# variables saisonnière comme "QA hiver"
indicateur_to_display =
  "QMNA"  
  #"VCN10 saisonnier"
    # "QA hiver"
# Pour les variable saisonnière comme le QA à toutes les saisons,
# il est utile d'avoir un pattern pour sélectionner après
# téléchargement des NetCDF pour toutes les saisons uniquement ceux
# de la saison d'intérêt par exemple "DJF", par défaut "*".
indicateur_pattern =
    "*"
    # "DJF"

# Nom de la moyenne de cet indicateur
mean_indicateur = paste0("mean", indicateur)
# Nom de l'indicateur de changement
delta_indicateur = paste0("delta", indicateur)
# Est ce que cet indicateur est à normalisable ?
to_normalise = TRUE

# Nom du dossier ou stocker les NetCDF
indicateur_dir =  paste0("DRIAS_indicateurs_",
                         indicateur_DRIAS)

### 2.2. Filtrer les URLs ____________________________________________
# # Soit en utilisant le tibble URL avec dplyr
URL_filtered = dplyr::filter(URL,
                             EXP == "rcp85" &
                             BC == "MF-ADAMONT" &
                             HM %in% c("J2000", "GRSD") &
                             indicateur == indicateur_DRIAS)
Urls = URL_filtered$url

# Soit en lisant directement un fichier txt qui contient une liste des
# URLs récupérés par le biais de la plateforme DRIAS-Eau
# Urls = readLines("manual_URL_DRIAS_indicateurs.txt")

### 2.3. Obtenir les NetCDFs _________________________________________
get_DRIAS_netcdf(Urls, indicateur_dir)

### 2.4. Lire un NetCDF ______________________________________________
# Obtenir l'ensemble des chemins des NetCDFs téléchargés
Paths = list.files(indicateur_dir,
                   pattern=indicateur_pattern, 
                   recursive=TRUE,
                   full.names=TRUE)

# Le NetCDF peut être ouvert de la même manière
NC = nc_open(Paths[1])
# Et l'ensemble des commandes vu précédemment restes valides
# Par conséquent, pour obtenir un tableau de donnée prêt à traiter pour la Dore à Dora
code = "K298191001"
data = read_DRIAS_netcdf(Paths, code)


### 2.5. Afficher les indicateurs ____________________________________
#### 2.5.1. en série annuelle ________________________________________
# Définition du plot et du thème
plot = ggplot() +
    theme_minimal() +
    theme(panel.grid.major.x=element_blank(),
          panel.grid.minor.x=element_blank(),
          plot.margin=margin(5, 20, 5, 5),
          axis.line.x=element_line(color="grey65",
                                   linewidth=0.5,
                                   lineend="round"),
          axis.ticks.x=element_line(color="grey80"),
          axis.ticks.length=unit(0.2, "cm"),
          plot.title=element_text(color="grey30")) +

    # Titre
    ggtitle(TeX(paste0(code, " - \\textbf{",
                       indicateur_to_display,
                       "} \\small{m$^{3}$.s$^{-1}$}"))) +

    # Affichage des chaînes de modélisation
    geom_line(data=data,
              aes(x=date,
                  y=get(indicateur),
                  group=chain),
              color="grey65",
              linewidth=0.4,
              alpha=0.15,
              lineend="round")

# Pour chaque narratif, affichage de la médiane sur les modèles
# hydrologiques
for (storyline in Storylines) {
    data_storyline = data %>%
        dplyr::filter(climate_chain %in% storyline$climate_chain)
    
    data_storyline_med = data_storyline %>%
        dplyr::group_by(climate_chain,
                        date) %>%
        dplyr::summarise(!!indicateur:=median(get(indicateur),
                                            na.rm=TRUE),
                         .groups="drop")

    plot = plot +
        geom_line(data=data_storyline_med,
                  aes(x=date,
                      y=get(indicateur)),
                  color=storyline$color,
                  linewidth=0.6,
                  alpha=1,
                  lineend="round")
}

# Mise en forme des axes
plot = plot +
    xlab(NULL) +
    scale_x_date(
        breaks=get_breaks,
        minor_breaks=get_minor_breaks,
        guide="axis_minor",
        date_labels="%Y",
        expand=c(0, 0)) +
    ylab(NULL) +
    scale_y_continuous(limits=c(0, NA),
                       expand=c(0, 0))

# Sauvegarde
ggsave(plot=plot,
       filename=file.path(figures_dir,
                          paste0("DRIAS_indicateurs_",
                                 code, "_",
                                 gsub(" ", "_", indicateur_to_display),
                                 ".pdf")),
       width=30, height=10, units="cm")

#### 2.5.2. en changement annuel _____________________________________
# Filtrage de la partie historique et moyenne de l'indicateur sur
# cette période pour chaque chaîne
data_historical = data %>%
    dplyr::group_by(chain) %>%
    dplyr::filter(historical[1] <= date &
                  date <= historical[2]) %>%
    dplyr::summarise(!!mean_indicateur:=mean(get(indicateur), na.rm=TRUE))

# Jointure avec les anciennes données
data = dplyr::left_join(data, data_historical, by="chain")

# Calcul du changement par rapport à la période de référence
# historique
data[[delta_indicateur]] =
    (data[[indicateur]] - data[[mean_indicateur]]) /
    data[[mean_indicateur]] * 100

# Définition du plot et du theme
plot = ggplot() +
    theme_minimal() +
    theme(panel.grid.major.x=element_blank(),
          panel.grid.minor.x=element_blank(),
          plot.margin=margin(5, 20, 5, 5),
          axis.line.x=element_line(color="grey65",
                                   linewidth=0.5,
                                   lineend="round"),
          axis.ticks.x=element_line(color="grey80"),
          axis.ticks.length=unit(0.2, "cm"),
          plot.title=element_text(color="grey30")) +

    # Titre
    ggtitle(TeX(paste0(code, " - changement de \\textbf{",
                       indicateur_to_display,
                       "}"))) +

    # Ligne du zéro
    annotate("line",
             x=c(min(data$date), max(data$date)),
             y=0,
             color="grey20",
             linewidth=0.6,
             linetype="dashed",
             lineend="round") +

    # Affichage des séries de changements
    geom_line(data=data,
              aes(x=date,
                  y=get(delta_indicateur),
                  group=chain),
              color="grey65",
              linewidth=0.4,
              alpha=0.15,
              lineend="round")

# Pour chaque narratif, affichage de la médiane des changements
# sur les modèles hydrologiques
for (storyline in Storylines) {
    data_storyline = data %>%
        dplyr::filter(climate_chain %in% storyline$climate_chain)

    data_storyline_med = data_storyline %>%
        dplyr::group_by(climate_chain, date) %>%
        dplyr::summarise(!!delta_indicateur:=
                             median(get(delta_indicateur), na.rm=TRUE),
                         .groups="drop")
    
    plot = plot +
        geom_line(data=data_storyline_med,
                  aes(x=date,
                      y=get(delta_indicateur)),
                  color=storyline$color,
                  linewidth=0.6,
                  alpha=1,
                  lineend="round")
}

# Mise en forme des axes
plot = plot +
    xlab(NULL) +
    scale_x_date(
        breaks=get_breaks,
        minor_breaks=get_minor_breaks,
        guide="axis_minor",
        date_labels="%Y",
        expand=c(0, 0)) +
    ylab(NULL) +
    scale_y_continuous(limits=c(-100, NA),
                       labels=delta_labels,
                       expand=c(0, 0))

# Sauvegarde
ggsave(plot=plot,
       filename=file.path(figures_dir,
                          paste0("DRIAS_indicateurs_",
                                 code, "_",
                                 "delta_",
                                 gsub(" ", "_", indicateur_to_display),
                                 ".pdf")),
       width=30, height=10, units="cm")

