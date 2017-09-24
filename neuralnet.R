library(h2o)
library(tidyverse)
library(gridExtra)

# Tworzymy połączenie z H2O
localH2O <- h2o.init(ip = "localhost", # domyślnie
                     port = 54321, # domyślnie
                     nthreads = -1, # użyj wszystkich dostepnych rdzeni
                     min_mem_size = "20g")

# Wczytujemy dane
fmnist_train <- h2o.importFile(path = "data/fashion-mnist_train.csv", 
                               destination_frame = "fmnist_train",
                               col.types=c("factor", rep("int", 784)))

fmnist_test <- h2o.importFile(path = "data/fashion-mnist_test.csv",
                              destination_frame = "fmnist_test",
                              col.types=c("factor", rep("int", 784)))

# Wizualizacja losowych cyfr
xy_axis <- data.frame(x = expand.grid(1:28,28:1)[,1],
                      y = expand.grid(1:28,28:1)[,2])
plot_theme <- list(
  raster = geom_raster(hjust = 0, vjust = 0),
  gradient_fill = scale_fill_gradient(low = "white", high = "black", guide = FALSE),
  theme = theme_void()
)

sample_plots <- sample(1:nrow(fmnist_train), 100) %>% map(~ {
  plot_data <- cbind(xy_axis, fill = as.data.frame(t(fmnist_train[.x, -1]))[,1]) 
  ggplot(plot_data, aes(x, y, fill = fill)) + plot_theme
})

do.call("grid.arrange", c(sample_plots, ncol = 10, nrow = 10))

# Sieć neuronowa
fmnist_nn_1 <- h2o.deeplearning(x = 2:785,
                                y = "label", 
                                training_frame = fmnist_train,
                                distribution = "multinomial",
                                model_id = "fmnist_nn_1",
                                l2 = 0.4,
                                ignore_const_cols = FALSE, # Wyjątkowo!
                                hidden = 10, # Ilość warstw ukrytych i neuronów per warstwa
                                export_weights_and_biases = TRUE, # Zachowanie wag i obciążeń
                                seed = 1234) 

# Wizualizacja wag z pierwszej warstwy ukrytej
weights_nn_1 <- as.data.frame(h2o.weights(fmnist_nn_1, 1))
biases_nn_1 <- as.vector(h2o.biases(fmnist_nn_1, 1))

neurons_plots <- 1:10 %>% map(~ {
  plot_data <- cbind(xy_axis, fill = t(weights_nn_1[.x,]) + biases_nn_1[.x])
  colnames(plot_data)[3] <- "fill"
  ggplot(plot_data, aes(x, y, fill = fill)) + plot_theme
})

do.call("grid.arrange", c(neurons_plots, ncol = 3, nrow = 4))

h2o.predict(fmnist_nn_1, fmnist_test)
h2o.confusionMatrix(fmnist_nn_1, fmnist_test)

# 9. Zbuduj sieć ze regularyzacją L1 i zwizualizuj, czy wynik jest lepszy ?
# 10. Zbuduj sieć ze 100 neuronami i zwizualizuj, czy wynik jest lepszy ?

# Dodajmy więcej parametrów
fmnist_nn_2 <- h2o.deeplearning(x = 2:785,
                                y = "label", 
                                training_frame = fmnist_train,
                                distribution = "multinomial",
                                model_id = "fmnist_nn_2",
                                activation = "Tanh", # Funkcja aktywacji
                                loss = "CrossEntropy", # Minimalizowana funkcja straty
                                adaptive_rate = FALSE,
                                rate = 0.01,
                                rate_annealing = 0.001,
                                hidden = c(50, 50, 100)) # Ilość warstw ukrytych i neuronów per warstwa

h2o.confusionMatrix(fmnist_nn_2, fmnist_test)

# Jeszcze więcej parametrów
fmnist_nn_final <- h2o.loadModel("data/fmnist_nn_final")
# fmnist_nn_final <- h2o.deeplearning(x = 2:785,
#                                     y = "label",
#                                     training_frame = fmnist_train,
#                                     distribution = "multinomial",
#                                     model_id = "fmnist_nn_final",
#                                     activation = "RectifierWithDropout",
#                                     hidden=c(1000, 1000, 2000),
#                                     epochs = 180,
#                                     adaptive_rate = FALSE,
#                                     rate=0.01,
#                                     rate_annealing = 1.0e-6,
#                                     rate_decay = 1.0,
#                                     momentum_start = 0.4,
#                                     momentum_ramp = 384000,
#                                     momentum_stable = 0.98, 
#                                     input_dropout_ratio = 0.22,
#                                     l1 = 1.0e-5,
#                                     max_w2 = 15.0, 
#                                     initial_weight_distribution = "Normal",
#                                     initial_weight_scale = 0.01,
#                                     nesterov_accelerated_gradient = TRUE,
#                                     loss = "CrossEntropy",
#                                     fast_mode = TRUE,
#                                     diagnostics = TRUE,
#                                     ignore_const_cols = TRUE,
#                                     force_load_balance = TRUE,
#                                     seed = 3.656455e+18)
# h2o.saveModel(fmnist_nn_final, path = "fmnist_nn_final")

h2o.confusionMatrix(fmnist_nn_final, fmnist_test)

# Grid search
hyper_params <- list(
  hidden = list(c(32,32), c(32,16,8), c(65)),
  l1 =  c(1e-4, 1e-3)
)

fmnist_nn_grid <- h2o.grid(algorithm = "deeplearning",
                           grid_id = "fmnist_nn_grid",
                           hyper_params = hyper_params,
                           x = 2:785,
                           y = "label",
                           distribution = "multinomial",
                           training_frame = fmnist_train,
                           stopping_tolerance = 0.05)

h2o.getGrid("fmnist_nn_grid",
            sort_by = "logloss",
            decreasing = FALSE)
