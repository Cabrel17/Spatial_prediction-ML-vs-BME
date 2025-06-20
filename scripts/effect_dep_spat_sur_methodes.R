library(readxl)
library(dplyr)
library(FSA)        
library(rstatix)   
library(stringr)

# 2. Chargement des données
data <- read_excel("D:/Courses/DRAFT - Copy/resultats_combines.xlsx")

# Liste des modèles
modeles <- unique(data$Modele)

# Boucle sur chaque modèle
for (m in modeles) {
  cat("\n==========================\n")
  cat("Résultats pour le modèle :", m, "\n")
  cat("==========================\n")
  
  # Sous-ensemble des données pour le modèle
  d <- data %>% filter(Modele == m)
  
  # Test de Kruskal-Wallis
  kruskal <- kruskal.test(MAE ~ Dependance, data = d)
  print(kruskal)
  
  # Test de Dunn post-hoc si significatif
  if (kruskal$p.value < 0.05) {
    cat("Test post-hoc de Dunn (p.adjust = bonferroni) :\n")
    dunn <- dunnTest(MAE ~ Dependance, data = d, method = "bonferroni")
    print(dunn)
  }
}


######

# Lecture des données
data <- read_excel("resultats_combines.xlsx")

# S'assurer que Asymétrie est un facteur
data$Asymetrie <- as.factor(data$Asymetrie)

# Liste des modèles
models <- unique(data$Modele)

# Boucle sur chaque modèle
for (model in models) {
  cat("\n==========================\n")
  cat("Résultats pour le modèle :", model, "\n")
  cat("==========================\n\n")
  
  # Sous-ensemble des données
  subset_model <- data %>% filter(Modele == model)
  
  # Test de Kruskal-Wallis
  kruskal <- kruskal.test(MAE ~ Asymetrie, data = subset_model)
  print(kruskal)
  
  # Si significatif, alors post-hoc de Dunn
  if (kruskal$p.value < 0.05) {
    cat("\nTest post-hoc de Dunn (p.adjust = bonferroni) :\n")
    dunn_result <- dunnTest(MAE ~ Asymetrie, data = subset_model, method = "bonferroni")
    print(dunn_result)
  } else {
    cat("\nAucune différence significative détectée : post-hoc non effectué.\n")
  }
}


######
# S'assurer que Size est un facteur ordonné
data$Size <- factor(data$Size, levels = sort(unique(data$Size)))

# Liste des modèles
models <- unique(data$Modele)

# Boucle sur chaque modèle
for (model in models) {
  cat("\n==========================\n")
  cat("Résultats pour le modèle :", model, "\n")
  cat("==========================\n\n")
  
  # Sous-ensemble des données
  subset_model <- data %>% filter(Modele == model)
  
  # Test de Kruskal-Wallis
  kruskal <- kruskal.test(MAE ~ Size, data = subset_model)
  print(kruskal)
  
  # Si significatif, alors post-hoc de Dunn
  if (kruskal$p.value < 0.05) {
    cat("\nTest post-hoc de Dunn (p.adjust = bonferroni) :\n")
    dunn_result <- dunnTest(MAE ~ Size, data = subset_model, method = "bonferroni")
    print(dunn_result)
  } else {
    cat("\nAucune différence significative détectée : post-hoc non effectué.\n")
  }
}

