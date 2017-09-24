library(h2o)
library(tidyverse)

# Tworzymy połączenie z H2O
localH2O <- h2o.init(ip = "localhost", # domyślnie
                     port = 54321, # domyślnie
                     nthreads = -1, # użyj wszystkich dostepnych rdzeni
                     min_mem_size = "20g")

# Wczytujemy dane
wine <- h2o.importFile(path = "data/wine.csv",
              destination_frame = "wine",
              col.names = c('Type', 'Alcohol', 'Malic', 'Ash', 
                             'Alcalinity', 'Magnesium', 'Phenols', 
                             'Flavanoids', 'Nonflavanoids',
                             'Proanthocyanins', 'Color', 'Hue', 
                             'Dilution', 'Proline'))

# K-means
wine_kmeans <- h2o.kmeans(x = 2:14, 
                          training_frame = wine,
                          model_id = "wine_kmeans",
                          k = 10, # Ile klastrów / Do ilu klastrów sprwdzać
                          estimate_k = TRUE,
                          standardize = TRUE)

wine_pred <- as.data.frame(h2o.predict(wine_kmeans, wine))

# PCA
wine_pca <- h2o.prcomp(x = 2:14, 
                       training_frame = wine,
                       model_id = "wine_pca",
                       transform = "STANDARDIZE", # Czy i jak transformować zmienne
                       k = 2) # Ilość komponentów (max tyle ile zmiennych 'x')
wine_components <- as.data.frame(h2o.predict(wine_pca, wine))

# Wizualizacja 
wine_data <- wine_components %>%
  cbind(wine_pred, Type = as.vector(wine$Type))

ggplot(wine_data, aes(PC1, PC2, color = as.factor(predict))) +
  geom_point() + theme_bw()
ggplot(wine_data, aes(PC1, PC2, color = as.factor(Type))) +
  geom_point() + theme_bw()

table(wine_data$predict, wine_data$Type)

# 11. Przeprowadź analogiczną analizę dla zbioru 'iris', czy widzisz coś niezwykłego ?
