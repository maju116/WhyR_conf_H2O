# 1.
x$a <- sin(as.h2o(44:47))
# 2.
x$id <- as.factor(x$id)
# 3.
a <- h2o.importFile(path = "data/a.csv",
                    destination_frame = "a")
b <- h2o.importFile(path = "data/b.csv",
                    destination_frame = "b")
ab <- h2o.assign(h2o.merge(a, b, by = "id"), key = "ab")
ab$suma <- apply(ab, 1, sum)
ab
# 4.
card_train <- h2o.getFrame("creditcard_train")
card_test <- h2o.getFrame("creditcard_test")
# 5.
pred_lasso_balanced <- h2o.predict(card_lasso_balanced, card_test)
# 6.
h2o.auc(card_lasso_balanced)
h2o.aic(card_lasso_balanced)
# 7.
h2o.coef(card_lasso_balanced)
# 8.
card_lasso_balanced@model$lambda_best
# 9.
fmnist_nn_l1 <- h2o.deeplearning(x = 2:785,
                                  y = "label", 
                                  training_frame = fmnist_train,
                                  distribution = "multinomial",
                                  model_id = "fmnist_nn_l1",
                                  l1 = 0.4,
                                  ignore_const_cols = FALSE, # Wyjątkowo!
                                  hidden = 100, # Ilość warstw ukrytych i neuronów per warstwa
                                  export_weights_and_biases = TRUE, # Zachowanie wag i obciążeń
                                  seed = 1234)
weights_nn_l1 <- as.data.frame(h2o.weights(fmnist_nn_l1, 1))
biases_nn_l1 <- as.vector(h2o.biases(fmnist_nn_l1, 1))
neurons_plots <- 1:10 %>% map(~ {
  plot_data <- cbind(xy_axis, fill = t(weights_nn_l1[.x,]) + biases_nn_l1[.x])
  colnames(plot_data)[3] <- "fill"
  ggplot(plot_data, aes(x, y, fill = fill)) + plot_theme
})
do.call("grid.arrange", c(neurons_plots, ncol = 3, nrow = 4))
h2o.confusionMatrix(fmnist_nn_l1, fmnist_test)
# 10.
fmnist_nn_100 <- h2o.deeplearning(x = 2:785,
                                y = "label", 
                                training_frame = fmnist_train,
                                distribution = "multinomial",
                                model_id = "fmnist_nn_100",
                                l2 = 0.4,
                                ignore_const_cols = FALSE, # Wyjątkowo!
                                hidden = 100, # Ilość warstw ukrytych i neuronów per warstwa
                                export_weights_and_biases = TRUE, # Zachowanie wag i obciążeń
                                seed = 1234)
weights_nn_100 <- as.data.frame(h2o.weights(fmnist_nn_100, 1))
biases_nn_100 <- as.vector(h2o.biases(fmnist_nn_100, 1))
neurons_plots <- 1:100 %>% map(~ {
  plot_data <- cbind(xy_axis, fill = t(weights_nn_100[.x,]) + biases_nn_100[.x])
  colnames(plot_data)[3] <- "fill"
  ggplot(plot_data, aes(x, y, fill = fill)) + plot_theme
})
do.call("grid.arrange", c(neurons_plots, ncol = 10, nrow = 10))
h2o.confusionMatrix(fmnist_nn_100, fmnist_test)
# 11.
iris_h2o <- as.h2o(iris, destination_frame = "iris")
iris_kmeans <- h2o.kmeans(x = 1:4, 
                          training_frame = iris_h2o,
                          model_id = "iris_kmeans",
                          k = 10, # Ile klastrów / Do ilu klastrów sprwdzać
                          estimate_k = TRUE,
                          standardize = TRUE)
iris_pred <- as.data.frame(h2o.predict(iris_kmeans, iris_h2o))
iris_pca <- h2o.prcomp(x = 1:4, 
                       training_frame = iris_h2o,
                       model_id = "iris_pca",
                       transform = "STANDARDIZE", # Czy i jak transformować zmienne
                       k = 2) # Ilość komponentów (max tyle ile zmiennych 'x')
iris_components <- as.data.frame(h2o.predict(iris_pca, iris_h2o))
iris_data <- iris_components %>%
  cbind(iris_pred, Type = as.vector(iris_h2o$Species))
ggplot(iris_data, aes(PC1, PC2, color = as.factor(predict))) +
  geom_point() + theme_bw()
ggplot(iris_data, aes(PC1, PC2, color = as.factor(Type))) +
  geom_point() + theme_bw()
